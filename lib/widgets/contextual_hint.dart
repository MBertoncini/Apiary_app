import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shows a dismissible hint banner the first time a screen is visited.
/// Tracks shown state in SharedPreferences.
/// Usage: place ContextualHint(key: 'dashboard_v1', message: '...')
///        at the top of a ListView or Column.
class ContextualHint extends StatefulWidget {
  final String prefKey;
  final String message;

  const ContextualHint({
    super.key,
    required this.prefKey,
    required this.message,
  });

  @override
  State<ContextualHint> createState() => _ContextualHintState();
}

class _ContextualHintState extends State<ContextualHint> {
  bool _visible = false;

  static const Color _dark = Color(0xFF2C1810);

  @override
  void initState() {
    super.initState();
    _checkShouldShow();
  }

  Future<void> _checkShouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('hint_${widget.prefKey}') ?? false;
    if (!shown && mounted) {
      setState(() => _visible = true);
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hint_${widget.prefKey}', true);
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return AnimatedSlide(
      offset: Offset.zero,
      duration: const Duration(milliseconds: 350),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _dark,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.message,
                style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white, height: 1.5),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _dismiss,
              child: Text('✕', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
