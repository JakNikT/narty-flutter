import 'package:flutter/material.dart';
import 'frame_renderer.dart';

/// Widget do łatwego budowania layoutu z JSON
class JsonFrameBuilder extends StatelessWidget {
  final String jsonData;
  final double? width;
  final double? height;

  const JsonFrameBuilder({
    super.key,
    required this.jsonData,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Parsuj JSON (w prawdziwej aplikacji użyj jsonDecode)
      final data = _parseJsonData(jsonData);
      
      return JsonFrameRenderer(
        frameData: data['frames'] ?? [],
        elementData: data['elements'] ?? [],
        width: width,
        height: height,
      );
    } catch (e) {
      return Container(
        width: width,
        height: height,
        color: Colors.red[100],
        child: Center(
          child: Text(
            'Błąd parsowania JSON: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Map<String, dynamic> _parseJsonData(String jsonString) {
    // W prawdziwej aplikacji użyj: import 'dart:convert'; jsonDecode(jsonString)
    // Tutaj zwracamy przykładowe dane
    return {
      'frames': [
        {
          'id': 'root',
          'left': 0,
          'top': 0,
          'width': 1100,
          'height': 650,
          'backgroundColor': 'white',
        },
        {
          'id': 'header',
          'left': 0,
          'top': 0,
          'width': 1100,
          'height': 200,
          'backgroundColor': '#386BB2',
        },
      ],
      'elements': [
        {
          'id': 'title',
          'frame': 'root',
          'left': 50,
          'top': 250,
          'width': 300,
          'height': 50,
          'color': 'transparent',
          'text': 'Tytuł z JSON',
          'fontSize': 24,
        },
        {
          'id': 'logo',
          'frame': 'header',
          'left': 50,
          'top': 50,
          'width': 200,
          'height': 100,
          'color': 'white',
          'text': 'LOGO',
          'fontSize': 20,
        },
      ],
    };
  }
}

/// Widget do edycji JSON w czasie rzeczywistym
class JsonFrameEditor extends StatefulWidget {
  final double? width;
  final double? height;

  const JsonFrameEditor({
    super.key,
    this.width,
    this.height,
  });

  @override
  State<JsonFrameEditor> createState() => _JsonFrameEditorState();
}

class _JsonFrameEditorState extends State<JsonFrameEditor> {
  late TextEditingController _jsonController;
  String _currentJson = '';

  @override
  void initState() {
    super.initState();
    _jsonController = TextEditingController();
    _loadDefaultJson();
  }

  void _loadDefaultJson() {
    _currentJson = '''
{
  "frames": [
    {
      "id": "root",
      "left": 0,
      "top": 0,
      "width": 1100,
      "height": 650,
      "backgroundColor": "white"
    },
    {
      "id": "header",
      "left": 0,
      "top": 0,
      "width": 1100,
      "height": 200,
      "backgroundColor": "#386BB2"
    }
  ],
  "elements": [
    {
      "id": "title",
      "frame": "root",
      "left": 50,
      "top": 250,
      "width": 300,
      "height": 50,
      "color": "transparent",
      "text": "Tytuł z JSON",
      "fontSize": 24
    },
    {
      "id": "logo",
      "frame": "header",
      "left": 50,
      "top": 50,
      "width": 200,
      "height": 100,
      "color": "white",
      "text": "LOGO",
      "fontSize": 20
    }
  ]
}
''';
    _jsonController.text = _currentJson;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Edytor JSON
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const Text(
                'Edytor JSON',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TextField(
                  controller: _jsonController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'Wklej tutaj JSON z frame\'ami i elementami...',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  onChanged: (value) {
                    setState(() {
                      _currentJson = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loadDefaultJson();
                      });
                    },
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    child: const Text('Odśwież'),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 20),
        
        // Podgląd
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const Text(
                'Podgląd',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: JsonFrameBuilder(
                      jsonData: _currentJson,
                      width: widget.width,
                      height: widget.height,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }
}
