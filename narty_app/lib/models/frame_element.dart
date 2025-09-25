import 'package:flutter/material.dart';

/// Model elementu w frame'ie (jak w Figmie)
class FrameElement {
  final String id;
  final String frameId; // ID frame'a w którym się znajduje
  final double left;
  final double top;
  final double width;
  final double height;
  final Color color;
  final String? text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;
  final double? borderRadius;
  final Border? border;

  const FrameElement({
    required this.id,
    required this.frameId,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.color,
    this.text,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.borderRadius,
    this.border,
  });

  /// Tworzy element z JSON
  factory FrameElement.fromJson(Map<String, dynamic> json) {
    return FrameElement(
      id: json['id'] as String,
      frameId: json['frame'] as String,
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      color: _parseColor(json['color'] as String),
      text: json['text'] as String?,
      fontSize: json['fontSize'] != null ? (json['fontSize'] as num).toDouble() : null,
      fontWeight: json['fontWeight'] != null ? FontWeight.values[json['fontWeight'] as int] : null,
      textColor: json['textColor'] != null ? _parseColor(json['textColor'] as String) : null,
      borderRadius: json['borderRadius'] != null ? (json['borderRadius'] as num).toDouble() : null,
    );
  }

  /// Konwertuje do JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'frame': frameId,
      'left': left,
      'top': top,
      'width': width,
      'height': height,
      'color': _colorToString(color),
      'text': text,
      'fontSize': fontSize,
      'fontWeight': fontWeight?.index,
      'textColor': textColor != null ? _colorToString(textColor!) : null,
      'borderRadius': borderRadius,
    };
  }

  static Color _parseColor(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'purple': return Colors.purple;
      case 'orange': return Colors.orange;
      case 'pink': return Colors.pink;
      case 'white': return Colors.white;
      case 'black': return Colors.black;
      case 'grey': return Colors.grey;
      case 'transparent': return Colors.transparent;
      default:
        // Próbuj parsować jako hex
        if (colorString.startsWith('#')) {
          return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
        }
        return Colors.grey;
    }
  }

  static String _colorToString(Color color) {
    if (color == Colors.red) return 'red';
    if (color == Colors.blue) return 'blue';
    if (color == Colors.green) return 'green';
    if (color == Colors.yellow) return 'yellow';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.pink) return 'pink';
    if (color == Colors.white) return 'white';
    if (color == Colors.black) return 'black';
    if (color == Colors.grey) return 'grey';
    if (color == Colors.transparent) return 'transparent';
    return '#${color.value.toRadixString(16).substring(2)}';
  }
}

/// Model frame'a (kontenera)
class Frame {
  final String id;
  final double left;
  final double top;
  final double width;
  final double height;
  final Color? backgroundColor;
  final double? borderRadius;
  final Border? border;
  final List<FrameElement> elements;

  const Frame({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.backgroundColor,
    this.borderRadius,
    this.border,
    this.elements = const [],
  });

  /// Tworzy frame z JSON
  factory Frame.fromJson(Map<String, dynamic> json) {
    return Frame(
      id: json['id'] as String,
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      backgroundColor: json['backgroundColor'] != null 
          ? FrameElement._parseColor(json['backgroundColor'] as String) 
          : null,
      borderRadius: json['borderRadius'] != null ? (json['borderRadius'] as num).toDouble() : null,
      elements: (json['elements'] as List<dynamic>?)
          ?.map((e) => FrameElement.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Konwertuje do JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'left': left,
      'top': top,
      'width': width,
      'height': height,
      'backgroundColor': backgroundColor != null 
          ? FrameElement._colorToString(backgroundColor!) 
          : null,
      'borderRadius': borderRadius,
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }
}
