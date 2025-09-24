import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Widget logo zgodny z projektem Figma
class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.headerBackground,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Stack(
        children: [
          // Mountain and skis icon
          Positioned(
            top: 40,
            left: 50,
            child: Column(
              children: [
                // Mountain peak
                Container(
                  width: 40,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                // Skis
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 2,
                      height: 25,
                      color: Colors.white,
                      transform: Matrix4.identity()..rotateZ(0.3),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 2,
                      height: 25,
                      color: Colors.white,
                      transform: Matrix4.identity()..rotateZ(-0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main text "NARTY"
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: const Text(
              'NARTY',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),

          // Sub text "POZNAŃ"
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: const Text(
              'POZNAŃ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),

          // Surrounding text elements
          // Top
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: const Text(
              'SKLEP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),

          // Right
          Positioned(
            top: 30,
            right: 10,
            child: const Text(
              'SERWIS',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),

          // Bottom
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: const Text(
              'WYPOŻYCZALNIA',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),

          // Left
          Positioned(
            top: 30,
            left: 10,
            child: const Text(
              'WWW.NARTYPOZNAN.PL',
              style: TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
