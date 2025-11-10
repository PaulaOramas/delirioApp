import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:delirio_app/navigation.dart' as nav;

class CartAnimation {
  /// Animates a circular thumbnail (or provided widget) from [startRect]
  /// toward the cart icon position exposed via `nav.cartIconKey`.
  static void animateAddToCart(BuildContext context,
      {required Rect startRect, Widget? child, String? imageUrl, Duration duration = const Duration(milliseconds: 700)}) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    // Determine target center from cart icon key
    Offset targetCenter;
    final cartContext = nav.cartIconKey.currentContext;
    if (cartContext != null) {
      final box = cartContext.findRenderObject() as RenderBox;
      final topLeft = box.localToGlobal(Offset.zero);
      targetCenter = topLeft + Offset(box.size.width / 2, box.size.height / 2);
    } else {
      // Fallback: bottom-right corner
      final size = MediaQuery.of(context).size;
      targetCenter = Offset(size.width - 36, size.height - 56);
    }

    final startCenter = startRect.center;

    final overlayEntry = OverlayEntry(builder: (ctx) {
      return _FlyingItem(
        start: startCenter,
        end: targetCenter,
        child: child,
        imageUrl: imageUrl,
        duration: duration,
      );
    });

    overlay.insert(overlayEntry);

    // Remove entry after duration + small buffer
    Future.delayed(duration + const Duration(milliseconds: 80), () {
      overlayEntry.remove();
    });
  }
}

class _FlyingItem extends StatefulWidget {
  final Offset start;
  final Offset end;
  final Widget? child;
  final String? imageUrl;
  final Duration duration;

  const _FlyingItem({required this.start, required this.end, this.child, this.imageUrl, required this.duration});

  @override
  State<_FlyingItem> createState() => _FlyingItemState();
}

class _FlyingItemState extends State<_FlyingItem> {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: widget.duration,
          curve: Curves.easeInOutCubic,
          builder: (context, t, _) {
            final dx = lerpDouble(widget.start.dx, widget.end.dx, t)!;
            final dy = lerpDouble(widget.start.dy, widget.end.dy, t)!;
            final scale = lerpDouble(1.0, 0.3, t)!;
            final opacity = lerpDouble(1.0, 0.0, t)!;

            final size = 48.0 * scale;

            return Stack(
              children: [
                Positioned(
                  left: dx - size / 2,
                  top: dy - size / 2,
                  width: size,
                  height: size,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: widget.child ?? _buildDefault(widget.imageUrl),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDefault(String? imageUrl) {
    return Material(
      color: Colors.transparent,
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(color: Colors.white, child: const Icon(Icons.local_florist, color: Colors.pink));
}
