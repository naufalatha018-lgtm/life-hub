import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size, numChannels: 4);

  // Background: Rich dark luxury gradient with radial subtle glow
  final cx = size / 2.0;
  final cy = size / 2.0;
  final maxDist = sqrt(cx * cx + cy * cy);

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = sqrt(dx * dx + dy * dy) / maxDist;
      
      // Radial glow in center (indigo/slate dark blend)
      final r = (15 + (1.0 - dist) * 25).clamp(0, 255).toInt();
      final g = (18 + (1.0 - dist) * 20).clamp(0, 255).toInt();
      final b = (28 + (1.0 - dist) * 55).clamp(0, 255).toInt();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Draw Shield/Vault outline
  // Coordinates for a modern sleek shield:
  // Top-left (260, 200), Top-right (764, 200),
  // Mid-left (200, 480), Mid-right (824, 480),
  // Tip bottom (512, 850)
  
  void drawThickLine(int x1, int y1, int x2, int y2, int thickness, int r, int g, int b, int a) {
    final dx = (x2 - x1).toDouble();
    final dy = (y2 - y1).toDouble();
    final steps = max(dx.abs(), dy.abs()).toInt() * 2;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final px = (x1 + dx * t).round();
      final py = (y1 + dy * t).round();
      for (int ox = -thickness ~/ 2; ox <= thickness ~/ 2; ox++) {
        for (int oy = -thickness ~/ 2; oy <= thickness ~/ 2; oy++) {
          final fx = px + ox;
          final fy = py + oy;
          if (fx >= 0 && fx < size && fy >= 0 && fy < size) {
            image.setPixelRgba(fx, fy, r, g, b, a);
          }
        }
      }
    }
  }

  // Draw glowing outer shield border
  final shieldPoints = [
    [512, 170], // Top apex
    [780, 250], // Top right corner
    [780, 520], // Mid right
    [512, 840], // Bottom tip
    [244, 520], // Mid left
    [244, 250], // Top left corner
    [512, 170], // Back to apex
  ];

  for (int i = 0; i < shieldPoints.length - 1; i++) {
    // Glow layer
    drawThickLine(shieldPoints[i][0], shieldPoints[i][1], shieldPoints[i+1][0], shieldPoints[i+1][1], 26, 99, 102, 241, 80);
    // Sharp core layer
    drawThickLine(shieldPoints[i][0], shieldPoints[i][1], shieldPoints[i+1][0], shieldPoints[i+1][1], 12, 129, 140, 248, 255);
  }

  // Inner geometric "L" and "H" modern emblem
  // "L" on the left:
  // Vertical stem: (380, 350) -> (380, 640)
  // Horizontal foot: (380, 640) -> (480, 640)
  drawThickLine(380, 360, 380, 640, 18, 99, 102, 241, 100); // Glow
  drawThickLine(380, 360, 380, 640, 10, 238, 242, 255, 255); // Core
  drawThickLine(380, 640, 480, 640, 18, 99, 102, 241, 100);
  drawThickLine(380, 640, 480, 640, 10, 238, 242, 255, 255);

  // Central connector / node linking L and H:
  // Connecting (480, 500) to (640, 500)
  drawThickLine(480, 500, 640, 500, 16, 6, 182, 212, 100); // Cyan glow
  drawThickLine(480, 500, 640, 500, 10, 56, 189, 248, 255);

  // "H" on the right:
  // Left stem: (550, 360) -> (550, 640)
  // Crossbar: (550, 500) -> (640, 500)
  // Right stem: (640, 360) -> (640, 640)
  drawThickLine(550, 360, 550, 640, 18, 99, 102, 241, 100);
  drawThickLine(550, 360, 550, 640, 10, 238, 242, 255, 255);

  drawThickLine(640, 360, 640, 640, 18, 99, 102, 241, 100);
  drawThickLine(640, 360, 640, 640, 10, 238, 242, 255, 255);

  // Glowing Hub Nodes (Circles at intersections)
  void drawCircleFilled(int cx, int cy, int radius, int r, int g, int b, int a) {
    for (int y = cy - radius; y <= cy + radius; y++) {
      for (int x = cx - radius; x <= cx + radius; x++) {
        if (x >= 0 && x < size && y >= 0 && y < size) {
          final distSq = (x - cx) * (x - cx) + (y - cy) * (y - cy);
          if (distSq <= radius * radius) {
            image.setPixelRgba(x, y, r, g, b, a);
          }
        }
      }
    }
  }

  // Draw node rings and glows
  final nodes = [
    [380, 360], [380, 640], [480, 640],
    [550, 360], [550, 640], [640, 360], [640, 640],
    [512, 170], [512, 840], [595, 500],
  ];

  for (final n in nodes) {
    drawCircleFilled(n[0], n[1], 18, 99, 102, 241, 80);
    drawCircleFilled(n[0], n[1], 10, 6, 182, 212, 220);
    drawCircleFilled(n[0], n[1], 5, 255, 255, 255, 255);
  }

  final outDir = Directory('assets/branding');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final pngBytes = img.encodePng(image);
  File('assets/branding/app_icon.png').writeAsBytesSync(pngBytes);
  print('Successfully generated assets/branding/app_icon.png (${pngBytes.length} bytes)');
}
