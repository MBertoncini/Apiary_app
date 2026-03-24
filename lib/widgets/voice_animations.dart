// lib/widgets/voice_animations.dart
import 'package:flutter/material.dart';
import '../constants/theme_constants.dart';

/// Concentric rings that pulse outward while [isActive].
class VoicePulsingRings extends StatefulWidget {
  final bool isActive;
  const VoicePulsingRings({Key? key, required this.isActive}) : super(key: key);

  @override
  State<VoicePulsingRings> createState() => _VoicePulsingRingsState();
}

class _VoicePulsingRingsState extends State<VoicePulsingRings>
    with TickerProviderStateMixin {
  static const int _ringCount = 3;
  static const int _baseDurationMs = 1600;
  static const int _staggerMs = 520;

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scaleAnims;
  late final List<Animation<double>> _opacityAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _ringCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: _baseDurationMs),
      ),
    );
    _scaleAnims = _controllers
        .map((c) => Tween<double>(begin: 0.4, end: 1.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _opacityAnims = _controllers
        .map((c) => Tween<double>(begin: 0.55, end: 0.0)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    if (widget.isActive) _startAll();
  }

  void _startAll() {
    for (int i = 0; i < _ringCount; i++) {
      Future.delayed(Duration(milliseconds: i * _staggerMs), () {
        if (mounted) _controllers[i].repeat();
      });
    }
  }

  void _stopAll() {
    for (final c in _controllers) {
      c.stop();
      c.reset();
    }
  }

  @override
  void didUpdateWidget(VoicePulsingRings old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _startAll();
    if (!widget.isActive && old.isActive) _stopAll();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.isActive ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(_ringCount, (i) {
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, __) => Transform.scale(
              scale: _scaleAnims[i].value,
              child: Opacity(
                opacity: _opacityAnims[i].value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.shade400.withOpacity(0.10),
                    border: Border.all(
                      color: Colors.red.shade300.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Equalizer-style waveform bars that animate while [isActive].
class VoiceWaveform extends StatefulWidget {
  final bool isActive;
  const VoiceWaveform({Key? key, required this.isActive}) : super(key: key);

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform>
    with TickerProviderStateMixin {
  static const List<double> _maxHeights = [28, 18, 42, 22, 46, 22, 42, 18, 28];
  static const List<int> _durations =     [580, 460, 700, 520, 640, 520, 700, 460, 580];

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _maxHeights.length,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: _durations[i]),
      ),
    );
    _anims = _controllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeInOut))
        .toList();

    if (widget.isActive) _startAll();
  }

  void _startAll() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 55), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  void _stopAll() {
    for (final c in _controllers) {
      c.stop();
      c.animateTo(0.15, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  void didUpdateWidget(VoiceWaveform old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) _startAll();
    if (!widget.isActive && old.isActive) _stopAll();
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const minH = 5.0;
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_maxHeights.length, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) {
              final h = minH + (_maxHeights[i] - minH) * _anims[i].value;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: 4,
                height: h,
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryColor
                      .withOpacity(0.35 + 0.65 * _anims[i].value),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Three bouncing dots shown while waiting for a trigger word.
class VoiceTriggerIndicator extends StatefulWidget {
  const VoiceTriggerIndicator({Key? key}) : super(key: key);

  @override
  State<VoiceTriggerIndicator> createState() => _VoiceTriggerIndicatorState();
}

class _VoiceTriggerIndicatorState extends State<VoiceTriggerIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controllers[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, -10 * _controllers[i].value),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ThemeConstants.primaryColor
                      .withOpacity(0.35 + 0.65 * _controllers[i].value),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Circular microphone button with breathing animation while listening.
class VoiceMicButton extends StatefulWidget {
  final bool isListening;
  final bool isProcessing;
  final VoidCallback onPressed;

  const VoiceMicButton({
    Key? key,
    required this.isListening,
    required this.isProcessing,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  @override
  void initState() {
    super.initState();
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _breathAnim = Tween<double>(begin: 1.0, end: 1.10).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
    if (widget.isListening) _breathCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(VoiceMicButton old) {
    super.didUpdateWidget(old);
    if (widget.isListening && !old.isListening) {
      _breathCtrl.repeat(reverse: true);
    } else if (!widget.isListening && old.isListening) {
      _breathCtrl
          .animateTo(0.0, duration: const Duration(milliseconds: 250))
          .then((_) => _breathCtrl.stop());
    }
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    super.dispose();
  }

  Color get _color {
    if (widget.isProcessing) return Colors.orange.shade600;
    if (widget.isListening) return Colors.red.shade600;
    return ThemeConstants.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _breathAnim,
        builder: (_, child) =>
            Transform.scale(scale: _breathAnim.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(widget.isListening ? 0.50 : 0.28),
                spreadRadius: widget.isListening ? 5 : 2,
                blurRadius: widget.isListening ? 20 : 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: widget.isProcessing
                  ? const SizedBox(
                      key: ValueKey('spinner'),
                      width: 44,
                      height: 44,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    )
                  : Icon(
                      widget.isListening ? Icons.stop_rounded : Icons.mic,
                      key: ValueKey<bool>(widget.isListening),
                      color: Colors.white,
                      size: widget.isListening ? 54 : 48,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
