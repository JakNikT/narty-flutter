import 'package:flutter/material.dart';
import '../widgets/frame_renderer.dart';
import '../models/frame_element.dart';

/// Ekran demonstracyjny systemu frame'ów
class FrameDemoScreen extends StatefulWidget {
  const FrameDemoScreen({super.key});

  @override
  State<FrameDemoScreen> createState() => _FrameDemoScreenState();
}

class _FrameDemoScreenState extends State<FrameDemoScreen> {
  // Przykładowe dane frame'ów
  late List<Frame> frames;
  late List<FrameElement> elements;

  @override
  void initState() {
    super.initState();
    _loadExampleData();
  }

  void _loadExampleData() {
    // Frame'y (kontenery)
    frames = [
      // Główne okno
      const Frame(
        id: 'root',
        left: 0,
        top: 0,
        width: 1100,
        height: 650,
        backgroundColor: Colors.white,
      ),
      
      // Nagłówek
      const Frame(
        id: 'header',
        left: 0,
        top: 0,
        width: 1100,
        height: 200,
        backgroundColor: Color(0xFF386BB2),
      ),
      
      // Formularz sekcja
      const Frame(
        id: 'form_section',
        left: 201,
        top: 10,
        width: 890,
        height: 180,
        backgroundColor: Color(0xFF194576),
        borderRadius: 20,
      ),
      
      // Lewa strona - względem formularz sekcja (x:10, y:10)
      const Frame(
        id: 'left_side',
        left: 10,
        top: 10,
        width: 307,
        height: 160,
        backgroundColor: Color(0xFF2C699F),
        borderRadius: 10,
      ),
      
      // Dane klienta - względem formularz sekcja (x:230, y:10) - środek góra
      const Frame(
        id: 'client_data',
        left: 230,
        top: 10,
        width: 230,
        height: 50,
        backgroundColor: Color(0xFF2C699F),
        borderRadius: 10,
      ),
      
      // Środek - względem formularz sekcja (x:230, y:74) - środek dół
      const Frame(
        id: 'center',
        left: 230,
        top: 74,
        width: 230,
        height: 96,
        backgroundColor: Color(0xFF2C699F),
        borderRadius: 10,
      ),
      
      // Prawa strona - względem formularz sekcja (x:680, y:10)
      const Frame(
        id: 'right_side',
        left: 680,
        top: 10,
        width: 307,
        height: 160,
        backgroundColor: Color(0xFF2C699F),
        borderRadius: 10,
      ),
    ];

    // Elementy w frame'ach
    elements = [
      // Elementy w głównym oknie
      const FrameElement(
        id: 'title',
        frameId: 'root',
        left: 50,
        top: 250,
        width: 300,
        height: 50,
        color: Colors.transparent,
        text: 'Frame Demo - Figma-like Layout',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        textColor: Colors.black,
      ),
      
      // Elementy w nagłówku
      const FrameElement(
        id: 'logo',
        frameId: 'header',
        left: 50,
        top: 50,
        width: 200,
        height: 100,
        color: Colors.white,
        text: 'LOGO',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        textColor: Colors.black,
      ),
      
      const FrameElement(
        id: 'header_text',
        frameId: 'header',
        left: 300,
        top: 80,
        width: 400,
        height: 40,
        color: Colors.transparent,
        text: 'Asystent Doboru Nart',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        textColor: Colors.white,
      ),
      
      // Elementy w lewej stronie
      const FrameElement(
        id: 'date_from',
        frameId: 'left_side',
        left: 20,
        top: 20,
        width: 100,
        height: 30,
        color: Color(0xFF194576),
        text: 'Data od:',
        fontSize: 14,
        fontWeight: FontWeight.bold,
        textColor: Colors.white,
      ),
      
      const FrameElement(
        id: 'date_input',
        frameId: 'left_side',
        left: 20,
        top: 50,
        width: 150,
        height: 30,
        color: Color(0xFF194576),
        borderRadius: 5,
      ),
      
      const FrameElement(
        id: 'height_label',
        frameId: 'left_side',
        left: 20,
        top: 90,
        width: 80,
        height: 25,
        color: Color(0xFF194576),
        text: 'Wzrost:',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        textColor: Colors.white,
      ),
      
      const FrameElement(
        id: 'height_input',
        frameId: 'left_side',
        left: 100,
        top: 90,
        width: 60,
        height: 25,
        color: Color(0xFF194576),
        borderRadius: 3,
      ),
      
      // Elementy w środku
      const FrameElement(
        id: 'client_data',
        frameId: 'center',
        left: 10,
        top: 10,
        width: 210,
        height: 30,
        color: Color(0xFF2C699F),
        text: 'Dane klienta',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        textColor: Colors.white,
      ),
      
      const FrameElement(
        id: 'level_label',
        frameId: 'center',
        left: 10,
        top: 50,
        width: 100,
        height: 25,
        color: Color(0xFF194576),
        text: 'Poziom:',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        textColor: Colors.white,
      ),
      
      const FrameElement(
        id: 'level_dropdown',
        frameId: 'center',
        left: 110,
        top: 50,
        width: 100,
        height: 25,
        color: Color(0xFF194576),
        borderRadius: 3,
      ),
      
      // Elementy w prawej stronie
      const FrameElement(
        id: 'preferences',
        frameId: 'right_side',
        left: 20,
        top: 20,
        width: 100,
        height: 25,
        color: Color(0xFF194576),
        text: 'Preferencje:',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        textColor: Colors.white,
      ),
      
      const FrameElement(
        id: 'all_style',
        frameId: 'right_side',
        left: 20,
        top: 50,
        width: 60,
        height: 20,
        color: Color(0xFF194576),
        text: 'Wszystkie',
        fontSize: 10,
        fontWeight: FontWeight.bold,
        textColor: Colors.white,
      ),
      
      const FrameElement(
        id: 'slalom_style',
        frameId: 'right_side',
        left: 90,
        top: 50,
        width: 50,
        height: 20,
        color: Color(0xFF194576),
        text: 'Slalom',
        fontSize: 10,
        fontWeight: FontWeight.bold,
        textColor: Colors.white,
      ),
      
      const FrameElement(
        id: 'find_button',
        frameId: 'right_side',
        left: 20,
        top: 100,
        width: 80,
        height: 30,
        color: Color(0xFF194576),
        text: '🔍 Znajdź',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        textColor: Colors.white,
        borderRadius: 5,
      ),
      
      const FrameElement(
        id: 'clear_button',
        frameId: 'right_side',
        left: 110,
        top: 100,
        width: 80,
        height: 30,
        color: Color(0xFF194576),
        text: '🗑️ Wyczyść',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        textColor: Colors.white,
        borderRadius: 5,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Frame Demo - Figma-like Layout'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Przykład systemu frame\'ów jak w Figmie',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Renderuj frame'y
              FrameRenderer(
                frames: frames,
                elements: elements,
                width: 1100,
                height: 650,
              ),
              
              const SizedBox(height: 30),
              
              // Przycisk do odświeżenia
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loadExampleData();
                  });
                },
                child: const Text('Odśwież'),
              ),
              
              const SizedBox(height: 20),
              
              // Przykład JSON
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Przykład JSON do dodawania elementów:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Frame\'y:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      '''[
  {"id": "root", "left": 0, "top": 0, "width": 1100, "height": 650, "backgroundColor": "white"},
  {"id": "header", "left": 0, "top": 0, "width": 1100, "height": 200, "backgroundColor": "#386BB2"}
]''',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Elementy:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      '''[
  {"id": "title", "frame": "root", "left": 50, "top": 250, "width": 300, "height": 50, "color": "transparent", "text": "Tytuł", "fontSize": 24},
  {"id": "logo", "frame": "header", "left": 50, "top": 50, "width": 200, "height": 100, "color": "white", "text": "LOGO"}
]''',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
