// lib/widgets/animated_tier_icon.dart
//
// Animated bee-lifecycle icon for the AI tiers.
//   free          → Uovo (egg)    — gentle rocking, like it's about to hatch
//   apicoltore    → Larva         — soft wiggle / squash-stretch
//   professionale → Ape (bee)     — hovering bob + flapping wings
//
// The bee's wings live in a separate SVG layer (APE_wings.svg) overlaid on the
// body (APE_body.svg); both share the same viewBox, so at equal size they
// register pixel-perfectly and the wing layer can be squashed independently to
// fake a wing-beat. Egg and larva animate as a single piece.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/user.dart';

class AnimatedTierIcon extends StatefulWidget {
  final AiTier tier;
  final double size;

  /// When false the icon renders static (no controllers running). Handy for
  /// dense lists or when reduce-motion is desired.
  final bool animate;

  const AnimatedTierIcon({
    super.key,
    required this.tier,
    this.size = 48,
    this.animate = true,
  });

  @override
  State<AnimatedTierIcon> createState() => _AnimatedTierIconState();
}

class _AnimatedTierIconState extends State<AnimatedTierIcon>
    with TickerProviderStateMixin {
  // Slow body motion: rock (egg) / wiggle (larva) / hover (bee).
  late final AnimationController _bodyCtrl;
  late final Animation<double> _body;

  // Fast wing-beat — used by the bee only.
  late final AnimationController _wingCtrl;
  late final Animation<double> _wing;

  @override
  void initState() {
    super.initState();
    _bodyCtrl = AnimationController(vsync: this, duration: _bodyDuration);
    _body = CurvedAnimation(parent: _bodyCtrl, curve: Curves.easeInOut);

    _wingCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _wing = CurvedAnimation(parent: _wingCtrl, curve: Curves.easeInOut);

    _syncControllers();
  }

  Duration get _bodyDuration {
    switch (widget.tier) {
      case AiTier.free:
        return const Duration(milliseconds: 1700);
      case AiTier.apicoltore:
        return const Duration(milliseconds: 900);
      case AiTier.professionale:
        return const Duration(milliseconds: 1400);
    }
  }

  void _syncControllers() {
    if (widget.animate) {
      if (!_bodyCtrl.isAnimating) _bodyCtrl.repeat(reverse: true);
      if (widget.tier == AiTier.professionale) {
        if (!_wingCtrl.isAnimating) _wingCtrl.repeat(reverse: true);
      } else {
        _wingCtrl.stop();
      }
    } else {
      _bodyCtrl.stop();
      _wingCtrl.stop();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedTierIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tier != widget.tier) {
      _bodyCtrl.duration = _bodyDuration;
      _bodyCtrl.reset();
    }
    _syncControllers();
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    _wingCtrl.dispose();
    super.dispose();
  }

  SvgPicture _svg(String asset) => SvgPicture.asset(
        asset,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
      );

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _svg(widget.tier.iconAsset);
    }
    switch (widget.tier) {
      case AiTier.free:
        return _buildEgg();
      case AiTier.apicoltore:
        return _buildLarva();
      case AiTier.professionale:
        return _buildBee();
    }
  }

  // ── Uovo: rocks back and forth around its base ─────────────────────────
  Widget _buildEgg() {
    return AnimatedBuilder(
      animation: _body,
      builder: (_, child) => Transform.rotate(
        angle: (_body.value - 0.5) * 0.16, // ≈ ±4.6°
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: _svg('assets/images/icons/Tiers/UOVO.svg'),
    );
  }

  // ── Larva: wriggles (small rotation + horizontal shift + breathing) ────
  Widget _buildLarva() {
    return AnimatedBuilder(
      animation: _body,
      builder: (_, child) {
        final t = _body.value - 0.5; // -0.5..0.5
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(t * widget.size * 0.06)
            ..rotateZ(t * 0.18) // ≈ ±5°
            ..scale(1.0, 1.0 + t * 0.06),
          child: child,
        );
      },
      child: _svg('assets/images/icons/Tiers/LARVA.svg'),
    );
  }

  // ── Ape: hovers up/down while the wings beat fast ──────────────────────
  Widget _buildBee() {
    return AnimatedBuilder(
      animation: Listenable.merge([_body, _wing]),
      builder: (_, __) {
        final bob = (_body.value - 0.5) * widget.size * 0.10;
        final wingSquash = 1.0 - _wing.value * 0.45; // 1.0 → 0.55
        return Transform.translate(
          offset: Offset(0, bob),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              children: [
                _svg('assets/images/icons/Tiers/APE_body.svg'),
                Transform(
                  // Pivot near the wing roots (upper third of the bee).
                  alignment: const Alignment(0.0, -0.30),
                  transform: Matrix4.identity()..scale(1.0, wingSquash, 1.0),
                  child: _svg('assets/images/icons/Tiers/APE_wings.svg'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
