"""
Moduł motywu kolorów aplikacji
Definiuje kolory i style dla interfejsu użytkownika
"""
from PyQt5.QtGui import QColor

class ModernTheme:
    """Nowoczesny motyw kolorów - niebieski jak logo"""
    
    # Główne kolory - różne odcienie niebieskiego
    PRIMARY = QColor(240, 248, 255)          # Bardzo jasny niebieski (główne tło)
    SECONDARY = QColor(220, 235, 255)        # Jasny niebieski (sekundarne tło)
    TERTIARY = QColor(200, 220, 255)         # Średni jasny niebieski (ramki)
    
    # Akcenty - inspirowane niebieskim logo
    ACCENT = QColor(30, 100, 175)            # Głęboki niebieski (główny akcent)
    ACCENT_HOVER = QColor(20, 80, 140)       # Ciemniejszy niebieski (hover)
    ACCENT_LIGHT = QColor(59, 130, 246)      # Jaśniejszy niebieski (aktywne elementy)
    
    # Kolory funkcjonalne - kontrastowe na niebieskim tle
    SUCCESS = QColor(5, 150, 105)            # Zielony las (sukces)
    WARNING = QColor(217, 119, 6)            # Pomarańczowy zachód (ostrzeżenie)
    ERROR = QColor(220, 38, 38)              # Ciemny czerwony (błąd)
    INFO = QColor(2, 132, 199)               # Niebieski lód (informacja)
    
    # Tekst - ciemny dla kontrastu na niebieskim tle
    TEXT_PRIMARY = QColor(31, 41, 55)        # Prawie czarny (główny tekst)
    TEXT_SECONDARY = QColor(55, 65, 81)      # Ciemny szary (drugorzędny tekst)

def get_application_stylesheet():
    """Zwraca główny arkusz stylów aplikacji"""
    return f"""
        QMainWindow {{
            background-color: {ModernTheme.PRIMARY.name()};
        }}
        QGroupBox {{
            font-weight: bold;
            border: 2px solid {ModernTheme.TERTIARY.name()};
            border-radius: 10px;
            margin-top: 10px;
            padding-top: 10px;
            background-color: {ModernTheme.SECONDARY.name()};
        }}
        QGroupBox::title {{
            subcontrol-origin: margin;
            left: 10px;
            padding: 0 5px 0 5px;
            color: {ModernTheme.TEXT_PRIMARY.name()};
        }}
        QLineEdit, QComboBox {{
            border: 2px solid {ModernTheme.TERTIARY.name()};
            border-radius: 8px;
            padding: 8px;
            background-color: white;
            font-size: 11px;
        }}
        QLineEdit:focus, QComboBox:focus {{
            border-color: {ModernTheme.ACCENT.name()};
        }}
        QRadioButton {{
            font-size: 11px;
            color: {ModernTheme.TEXT_PRIMARY.name()};
        }}
        QTextEdit {{
            border: 2px solid {ModernTheme.TERTIARY.name()};
            border-radius: 8px;
            background-color: white;
            font-family: 'Segoe UI';
        }}
    """

def get_button_style(color, hover_color=None):
    """Zwraca styl dla przycisku z określonym kolorem"""
    if hover_color is None:
        hover_color = color.darker(120)
    
    return f"""
        QPushButton {{
            background-color: {color.name()};
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            font-weight: bold;
        }}
        QPushButton:hover {{
            background-color: {hover_color.name()};
        }}
    """

def get_results_text_style():
    """Zwraca styl dla pola wyników"""
    return f"""
        QTextEdit {{
            background-color: {ModernTheme.PRIMARY.name()};
            border: 2px solid {ModernTheme.TERTIARY.name()};
            border-radius: 8px;
            padding: 10px;
            font-family: 'Segoe UI';
            font-size: 13px;
            line-height: 1.3;
            font-weight: 500;
        }}
    """
