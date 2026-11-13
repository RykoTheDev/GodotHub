import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

class GhShaderWarmUp extends ShaderWarmUp {
  const GhShaderWarmUp();

  @override
  ui.Size get size => const ui.Size(256, 256);

  @override
  Future<void> warmUpOnCanvas(ui.Canvas canvas) async {
    const rect = ui.Rect.fromLTWH(8, 8, 120, 80);
    final rrect = ui.RRect.fromRectAndRadius(rect, const ui.Radius.circular(12));
    final fill = ui.Paint()..color = const ui.Color(0xFF3B82F6);
    final stroke = ui.Paint()
      ..color = const ui.Color(0xFF94A3B8)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final gradient = ui.Paint()
      ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, const [ui.Color(0xFF1E293B), ui.Color(0x003B82F6)]);
    final radial = ui.Paint()..shader = ui.Gradient.radial(rect.center, 60, const [ui.Color(0x553B82F6), ui.Color(0x00000000)]);

    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, stroke);
    canvas.drawRRect(rrect, gradient);
    canvas.drawRect(rect, radial);
    canvas.drawCircle(rect.center, 20, stroke);
    canvas.drawOval(rect.deflate(10), fill);
    canvas.drawLine(rect.topLeft, rect.bottomRight, stroke);

    for (final sigma in [2.0, 6.0, 12.0, 24.0]) {
      canvas.drawRRect(
        rrect.shift(const ui.Offset(0, 4)),
        ui.Paint()
          ..color = const ui.Color(0x40000000)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, sigma),
      );
    }

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(rect.inflate(20), gradient);
    canvas.restore();

    for (final alpha in [0x33, 0x99]) {
      canvas.saveLayer(rect, ui.Paint()..color = ui.Color.fromARGB(alpha, 0, 0, 0));
      canvas.drawRRect(rrect, fill);
      canvas.restore();
    }

    for (final sigma in [4.0, 8.0, 20.0]) {
      canvas.saveLayer(rect, ui.Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma));
      canvas.drawRRect(rrect, fill);
      canvas.restore();
    }

    canvas.saveLayer(rect, ui.Paint());
    canvas.drawRRect(rrect, fill);
    canvas.drawRect(rect, gradient..blendMode = ui.BlendMode.dstIn);
    canvas.restore();

    canvas.saveLayer(rect, ui.Paint()..colorFilter = const ui.ColorFilter.mode(ui.Color(0xFF22C55E), ui.BlendMode.srcIn));
    canvas.drawRRect(rrect, fill);
    canvas.restore();
    canvas.saveLayer(
      rect,
      ui.Paint()
        ..colorFilter = const ui.ColorFilter.matrix([
          0.33,
          0.33,
          0.33,
          0,
          0,
          0.33,
          0.33,
          0.33,
          0,
          0,
          0.33,
          0.33,
          0.33,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
    );
    canvas.drawRRect(rrect, fill);
    canvas.restore();

    for (final mode in [ui.BlendMode.modulate, ui.BlendMode.plus, ui.BlendMode.screen, ui.BlendMode.multiply]) {
      canvas.drawRRect(
        rrect,
        ui.Paint()
          ..color = const ui.Color(0x80F59E0B)
          ..blendMode = mode,
      );
    }

    canvas.save();
    canvas.translate(64, 64);
    canvas.rotate(0.3);
    canvas.scale(0.9);
    canvas.drawRRect(rrect, fill);
    canvas.restore();

    for (final size in [11.0, 14.0, 24.0]) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(fontSize: size))
        ..pushStyle(ui.TextStyle(color: const ui.Color(0xFFFFFFFF)))
        ..addText('GodotHub 0123456789');
      final paragraph = builder.build()..layout(const ui.ParagraphConstraints(width: 240));
      canvas.drawParagraph(paragraph, ui.Offset(8, 100 + size * 4));
    }
  }
}
