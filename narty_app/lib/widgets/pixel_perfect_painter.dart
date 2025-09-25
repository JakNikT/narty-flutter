import 'package:flutter/material.dart';

/// CustomPainter do dokładnego rysowania pikseli zgodnie z Figma
class PixelPerfectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Główne okno (x:0, y:0, w:1100, h:650, background: #FFFFFF)
    paint.color = const Color(0xFFFFFFFF); // #FFFFFF
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1100, 650), paint);

    // Nagłówek (x:0, y:0, w:1100, h:200, background: #386BB2)
    paint.color = const Color(0xFF386BB2); // #386BB2
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1100, 200), paint);

    // Dodajmy tekst z pozycjami
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Tekst dla głównego okna
    textPainter.text = const TextSpan(
      text: 'GŁÓWNE OKNO\n(0, 0, 1100, 650)\n#FFFFFF',
      style: TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(50, 300));

    // Tekst dla nagłówka
    textPainter.text = const TextSpan(
      text: 'NAGŁÓWEK\n(0, 0, 1100, 200)\n#386BB2',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(50, 50));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Widget używający CustomPainter
class PixelPerfectTestWidget extends StatelessWidget {
  const PixelPerfectTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: PixelPerfectPainter(),
      size: const Size(1100, 650),
    );
  }
}
