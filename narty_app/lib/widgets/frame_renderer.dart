import 'package:flutter/material.dart';
import '../models/frame_element.dart';

/// Widget do renderowania pojedynczego frame'a
class FrameWidget extends StatelessWidget {
  final Frame frame;
  final List<FrameElement> allElements;

  const FrameWidget({
    super.key,
    required this.frame,
    required this.allElements,
  });

  @override
  Widget build(BuildContext context) {
    // Znajdź elementy należące do tego frame'a
    final frameElements = allElements.where((e) => e.frameId == frame.id).toList();

    return Positioned(
      left: frame.left,
      top: frame.top,
      child: SizedBox(
        width: frame.width,
        height: frame.height,
        child: Stack(
          children: [
            // Tło frame'a (jeśli ma)
            if (frame.backgroundColor != null)
              Container(
                width: frame.width,
                height: frame.height,
                decoration: BoxDecoration(
                  color: frame.backgroundColor,
                  borderRadius: frame.borderRadius != null 
                      ? BorderRadius.circular(frame.borderRadius!) 
                      : null,
                  border: frame.border,
                ),
              ),
            
            // Elementy w frame'ie
            ...frameElements.map((element) => _buildElement(element)),
          ],
        ),
      ),
    );
  }

  Widget _buildElement(FrameElement element) {
    return Positioned(
      left: element.left,
      top: element.top,
      child: Container(
        width: element.width,
        height: element.height,
        decoration: BoxDecoration(
          color: element.color,
          borderRadius: element.borderRadius != null 
              ? BorderRadius.circular(element.borderRadius!) 
              : null,
          border: element.border,
        ),
        child: element.text != null
            ? Center(
                child: Text(
                  element.text!,
                  style: TextStyle(
                    color: element.textColor ?? Colors.black,
                    fontSize: element.fontSize ?? 14,
                    fontWeight: element.fontWeight ?? FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : null,
      ),
    );
  }
}

/// Główny widget do renderowania wszystkich frame'ów
class FrameRenderer extends StatelessWidget {
  final List<Frame> frames;
  final List<FrameElement> elements;
  final double? width;
  final double? height;

  const FrameRenderer({
    super.key,
    required this.frames,
    required this.elements,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Renderuj wszystkie frame'y
          ...frames.map((frame) => FrameWidget(
            frame: frame,
            allElements: elements,
          )),
        ],
      ),
    );
  }
}

/// Widget do łatwego dodawania elementów z JSON
class JsonFrameRenderer extends StatelessWidget {
  final List<Map<String, dynamic>> frameData;
  final List<Map<String, dynamic>> elementData;
  final double? width;
  final double? height;

  const JsonFrameRenderer({
    super.key,
    required this.frameData,
    required this.elementData,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Parsuj dane
    final frames = frameData.map((data) => Frame.fromJson(data)).toList();
    final elements = elementData.map((data) => FrameElement.fromJson(data)).toList();

    return FrameRenderer(
      frames: frames,
      elements: elements,
      width: width,
      height: height,
    );
  }
}
