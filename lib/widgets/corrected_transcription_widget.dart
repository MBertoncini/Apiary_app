// lib/widgets/corrected_transcription_widget.dart
//
// Renders a live STT transcription with vocabulary corrections highlighted:
//   – original wrong word  → red background + animated diagonal strikethrough
//   – corrected word       → green badge, fades/slides in after the strike

import 'package:flutter/material.dart';
import '../services/bee_vocabulary_corrector.dart';
import '../constants/theme_constants.dart';

// ── Main widget ───────────────────────────────────────────────────────────────

/// Drop-in replacement for [Text] inside the transcription box.
/// Applies [BeeVocabularyCorrector] and renders corrections with animation.
class CorrectedTranscriptionWidget extends StatelessWidget {
  final String rawText;
  final TextStyle? baseStyle;

  const CorrectedTranscriptionWidget({
    Key? key,
    required this.rawText,
    this.baseStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = baseStyle ??
        TextStyle(
          fontSize: 15,
          height: 1.4,
          color: ThemeConstants.textPrimaryColor,
        );

    if (rawText.isEmpty) {
      return Text(
        'Parla ora…',
        style: style.copyWith(color: Colors.grey.shade400),
      );
    }

    final segments = BeeVocabularyCorrector().correctSegments(rawText);

    // Build TextSpan children.
    // NormalSegments → TextSpan
    // CorrectedSegments → WidgetSpan containing an animated _CorrectionChip.
    // The key on _CorrectionChip ensures Flutter preserves animation state
    // across rebuilds (as new words are appended to the transcription buffer).
    int chipIndex = 0;
    final spans = <InlineSpan>[];

    for (final seg in segments) {
      if (seg is CorrectedSegment) {
        final idx = chipIndex++;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: _CorrectionChip(
            key: ValueKey('chip_${seg.original.toLowerCase()}_$idx'),
            segment: seg,
            baseStyle: style,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: (seg as NormalSegment).text,
          style: style,
        ));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      softWrap: true,
    );
  }
}

// ── Animated correction chip ──────────────────────────────────────────────────

class _CorrectionChip extends StatefulWidget {
  final CorrectedSegment segment;
  final TextStyle baseStyle;

  const _CorrectionChip({
    Key? key,
    required this.segment,
    required this.baseStyle,
  }) : super(key: key);

  @override
  State<_CorrectionChip> createState() => _CorrectionChipState();
}

class _CorrectionChipState extends State<_CorrectionChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _lineProgress; // draws the diagonal strike
  late final Animation<double> _wordOpacity;  // corrected word fades in
  late final Animation<Offset> _wordSlide;    // corrected word slides in

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Phase 1 (0 – 55 %): diagonal line draws across the wrong word.
    _lineProgress = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeInOut),
    );

    // Phase 2 (45 – 100 %): corrected word fades + slides in from the right.
    _wordOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    );
    _wordSlide = Tween<Offset>(
      begin: const Offset(0.35, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
    ));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = widget.baseStyle.fontSize ?? 15;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Wrong word with animated diagonal strikethrough ──────────────
            Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.segment.original,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: Colors.red.shade400,
                      height: 1.3,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CustomPaint(
                      painter: _DiagonalStrikePainter(
                        progress: _lineProgress.value,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Arrow + corrected word (animated) ────────────────────────────
            FadeTransition(
              opacity: _wordOpacity,
              child: SlideTransition(
                position: _wordSlide,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.arrow_right_alt_rounded,
                        size: fontSize + 2,
                        color: Colors.green.shade600,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.green.shade300,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        widget.segment.corrected,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Custom painter ────────────────────────────────────────────────────────────

/// Draws an animated diagonal line from bottom-left to top-right
/// (the universal "wrong / cancelled" slash symbol: /).
class _DiagonalStrikePainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;

  const _DiagonalStrikePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Animate from bottom-left → top-right.
    final start = Offset(2, size.height - 2);
    final end = Offset(size.width - 2, 2);
    final current = Offset.lerp(start, end, progress)!;

    canvas.drawLine(start, current, paint);
  }

  @override
  bool shouldRepaint(_DiagonalStrikePainter old) =>
      old.progress != progress || old.color != color;
}
