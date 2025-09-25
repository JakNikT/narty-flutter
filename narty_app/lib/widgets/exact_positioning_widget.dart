import 'package:flutter/material.dart';

/// Widget do dokładnego pozycjonowania zgodnie z Figma
class ExactPositioningWidget extends StatelessWidget {
  final Widget child;
  final double x;
  final double y;
  final double width;
  final double height;

  const ExactPositioningWidget({
    super.key,
    required this.child,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x,
      top: y,
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

/// Test widget z kolorowymi kwadratami
class TestSquaresWidget extends StatelessWidget {
  const TestSquaresWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Główny kontener (x:0, y:0, w:1100, h:650)
        ExactPositioningWidget(
          x: 0,
          y: 0,
          width: 1100,
          height: 650,
          child: Container(
            color: Colors.grey.withValues(alpha: 0.1),
            child: const Center(
              child: Text(
                'GŁÓWNY KONTENER\n(0, 0, 1100, 650)',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Nagłówek (x:0, y:0, w:1100, h:200)
        ExactPositioningWidget(
          x: 0,
          y: 0,
          width: 1100,
          height: 200,
          child: Container(
            color: Colors.blue.withValues(alpha: 0.3),
            child: const Center(
              child: Text(
                'NAGŁÓWEK\n(0, 0, 1100, 200)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Formularz sekcja (x:201, y:10, w:890, h:180)
        ExactPositioningWidget(
          x: 201,
          y: 10,
          width: 890,
          height: 180,
          child: Container(
            color: Colors.green.withValues(alpha: 0.3),
            child: const Center(
              child: Text(
                'FORMULARZ SEKCJA\n(201, 10, 890, 180)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Lewa strona (x:10, y:10, w:307, h:160) - względem formularza
        ExactPositioningWidget(
          x: 201 + 10, // 201 (formularz) + 10 (lewa strona)
          y: 10 + 10, // 10 (formularz) + 10 (lewa strona)
          width: 307,
          height: 160,
          child: Container(
            color: Colors.red.withValues(alpha: 0.5),
            child: const Center(
              child: Text(
                'LEWA STRONA\n(211, 20, 307, 160)\nwzględem głównego',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Środek (względem formularza) - dodajmy przykładowe pozycje
        ExactPositioningWidget(
          x: 201 + 350, // 201 (formularz) + 350 (środek)
          y: 10 + 120, // 10 (formularz) + 120 (środek)
          width: 230,
          height: 96,
          child: Container(
            color: Colors.orange.withValues(alpha: 0.5),
            child: const Center(
              child: Text(
                'ŚRODEK\n(551, 130, 230, 96)\nwzględem głównego',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Prawa strona (względem formularza)
        ExactPositioningWidget(
          x: 201 + 680, // 201 (formularz) + 680 (prawa strona)
          y: 10 + 10, // 10 (formularz) + 10 (prawa strona)
          width: 307,
          height: 160,
          child: Container(
            color: Colors.purple.withValues(alpha: 0.5),
            child: const Center(
              child: Text(
                'PRAWA STRONA\n(881, 20, 307, 160)\nwzględem głównego',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
