import 'package:flutter/material.dart';

/// Animasi masuk ringan untuk kartu dan baris daftar.
/// Indeks membuat durasi sedikit bervariasi sehingga daftar terasa bertahap.
class SmoothEntrance extends StatelessWidget {
  const SmoothEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 280),
    this.distance = 12,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final double distance;

  @override
  Widget build(BuildContext context) {
    final extraMs = (index.clamp(0, 5) * 35);
    final itemDuration = duration + Duration(milliseconds: extraMs);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: itemDuration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * distance),
            child: animatedChild,
          ),
        );
      },
    );
  }
}

/// Efek tekan untuk permukaan kartu yang ingin terasa lebih responsif.
class SmoothTap extends StatefulWidget {
  const SmoothTap({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final Widget child;
  final VoidCallback onTap;
  final BorderRadius borderRadius;

  @override
  State<SmoothTap> createState() => _SmoothTapState();
}

class _SmoothTapState extends State<SmoothTap> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
