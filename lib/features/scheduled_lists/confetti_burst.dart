import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// Fires a short confetti burst at a point on screen.
///
/// The web widget anchors its burst at the checkbox that was tapped, so this
/// takes a global position and drops a transient overlay there rather than
/// firing from a fixed point.
void fireConfettiAt(BuildContext context, Offset globalPosition) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late OverlayEntry entry;
  final controller =
      ConfettiController(duration: const Duration(milliseconds: 400));

  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: globalPosition.dx,
      top: globalPosition.dy,
      child: IgnorePointer(
        child: ConfettiWidget(
          confettiController: controller,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          numberOfParticles: 18,
          maxBlastForce: 14,
          minBlastForce: 6,
          gravity: 0.32,
          particleDrag: 0.06,
          emissionFrequency: 0.35,
          minimumSize: const Size(4, 4),
          maximumSize: const Size(9, 9),
          colors: const [
            Color(0xFF10B981),
            Color(0xFF3B82F6),
            Color(0xFFF59E0B),
            Color(0xFFEC4899),
            Color(0xFF8B5CF6),
          ],
          createParticlePath: _confettiPath,
        ),
      ),
    ),
  );

  overlay.insert(entry);
  controller.play();

  // Long enough for the particles to fall out of view before tearing down.
  Future.delayed(const Duration(milliseconds: 2200), () {
    controller.dispose();
    entry.remove();
  });
}

/// Small rounded rectangles rather than the package's default star.
Path _confettiPath(Size size) {
  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.6),
        const Radius.circular(1.5),
      ),
    );
}

/// The random jitter used to spread bursts slightly, so repeated taps in the
/// same spot do not look identical.
final Random confettiJitter = Random();
