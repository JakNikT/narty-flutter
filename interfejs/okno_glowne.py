"""
Główne okno aplikacji Asystent Doboru Nart
Zawiera interfejs użytkownika i logikę obsługi zdarzeń
"""
import os
import sys
from datetime import datetime, timedelta
from PyQt5.QtWidgets import (QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, 
                             QLabel, QPushButton, QLineEdit, QRadioButton, 
                             QTextEdit, QGroupBox, QMessageBox, QCalendarWidget, QDialog, QFrame)
from PyQt5.QtCore import Qt, QRegExp
from PyQt5.QtGui import QFont, QPixmap, QRegExpValidator

# Import modułów
from logika.dobieranie_nart import dobierz_narty
from dane.wczytywanie_danych import sprawdz_czy_narta_zarezerwowana
from styl.motyw_kolorow import ModernTheme, get_application_stylesheet, get_button_style, get_results_text_style
from narzedzia.konfiguracja_logowania import get_logger

logger = get_logger(__name__)

class DatePickerDialog(QDialog):
    """Dialog wyboru daty"""
    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("Wybierz datę")
        self.setModal(True)
        self.setFixedSize(300, 250)
        
        layout = QVBoxLayout(self)
        
        # Kalendarz
        self.calendar = QCalendarWidget()
        self.calendar.setGridVisible(True)
        layout.addWidget(self.calendar)
        
        # Przyciski
        btn_layout = QHBoxLayout()
        
        ok_btn = QPushButton("OK")
        ok_btn.clicked.connect(self.accept)
        ok_btn.setStyleSheet(get_button_style(ModernTheme.SUCCESS))
        
        cancel_btn = QPushButton("Anuluj")
        cancel_btn.clicked.connect(self.reject)
        cancel_btn.setStyleSheet(get_button_style(ModernTheme.ERROR))
        
        btn_layout.addWidget(ok_btn)
        btn_layout.addWidget(cancel_btn)
        layout.addLayout(btn_layout)
    
    def get_selected_date(self):
        return self.calendar.selectedDate()

class SkiApp(QMainWindow):
    """Główne okno aplikacji"""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("🎿 Asystent Doboru Nart v6.0 - Modularna")
        self.setGeometry(100, 100, 1000, 700)
        self.setup_ui()
        self.setup_styles()
        logger.info("Aplikacja uruchomiona")
        
    def setup_ui(self):
        """Konfiguruje interfejs użytkownika"""
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # Główny layout
        main_layout = QVBoxLayout(central_widget)
        main_layout.setSpacing(12)
        main_layout.setContentsMargins(15, 15, 15, 15)
        
        # Nagłówek z logo i formularzem
        header_frame = self.create_header()
        main_layout.addWidget(header_frame)
        
        # Pole wyników
        results_group = self.create_results_group()
        main_layout.addWidget(results_group)
        
    def create_header(self):
        """Tworzy nagłówek z logo i formularzem"""
        # Główny kontener poziomy
        top_frame = QFrame()
        top_frame.setStyleSheet(f"background-color: {ModernTheme.PRIMARY.name()}; border: 2px solid {ModernTheme.TERTIARY.name()};")
        
        header_layout = QHBoxLayout(top_frame)
        header_layout.setContentsMargins(15, 15, 15, 15)
        
        # Lewa strona - logo i tytuł
        left_side = QFrame()
        left_side.setStyleSheet(f"background-color: {ModernTheme.PRIMARY.name()};")
        left_side.setFixedWidth(350)
        
        # Kontener pionowy - logo na górze, tekst pod spodem
        unified_container = QVBoxLayout()
        unified_container.setContentsMargins(0, 0, 0, 0)
        unified_container.setAlignment(Qt.AlignCenter)
        
        # Logo
        try:
            current_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            logo_path = os.path.join(current_dir, "zasoby", "narty.png")
            logger.info(f"Próbuję załadować logo z: {logo_path}")
            
            logo_pixmap = QPixmap(logo_path)
            if not logo_pixmap.isNull():
                scaled_logo = logo_pixmap.scaled(260, 260, Qt.KeepAspectRatio, Qt.SmoothTransformation)
                logo_label = QLabel()
                logo_label.setPixmap(scaled_logo)
                logo_label.setAlignment(Qt.AlignCenter)
                logo_label.setStyleSheet(f"background-color: {ModernTheme.PRIMARY.name()};")
                logo_label.setFixedSize(260, 260)
                unified_container.addWidget(logo_label)
            else:
                # Fallback
                fallback_logo = QLabel("🎿")
                fallback_logo.setFont(QFont("Segoe UI", 120))
                fallback_logo.setStyleSheet(f"color: {ModernTheme.ACCENT.name()}; background-color: {ModernTheme.PRIMARY.name()};")
                fallback_logo.setFixedSize(260, 260)
                fallback_logo.setAlignment(Qt.AlignCenter)
                unified_container.addWidget(fallback_logo)
        except Exception as e:
            logger.warning(f"Nie można załadować logo: {e}")
            fallback_logo = QLabel("🎿")
            fallback_logo.setFont(QFont("Segoe UI", 120))
            fallback_logo.setStyleSheet(f"color: {ModernTheme.ACCENT.name()}; background-color: {ModernTheme.PRIMARY.name()};")
            fallback_logo.setFixedSize(260, 260)
            fallback_logo.setAlignment(Qt.AlignCenter)
            unified_container.addWidget(fallback_logo)
        
        # Tekst pod logo
        title_text = QLabel("System doboru nart")
        title_text.setFont(QFont("Segoe UI", 16, QFont.Bold))
        title_text.setStyleSheet(f"color: {ModernTheme.ACCENT.name()}; background-color: {ModernTheme.PRIMARY.name()};")
        title_text.setAlignment(Qt.AlignCenter)
        unified_container.addWidget(title_text)
        
        left_side.setLayout(unified_container)
        header_layout.addWidget(left_side)
        
        # Prawa strona - formularz danych klienta
        right_side = QFrame()
        right_side.setStyleSheet(f"background-color: {ModernTheme.SECONDARY.name()}; border: 2px solid {ModernTheme.TERTIARY.name()}; border-radius: 10px;")
        
        right_layout = QVBoxLayout(right_side)
        right_layout.setContentsMargins(12, 12, 12, 12)
        
        # Nagłówek "Dane Klienta"
        header_label = QLabel("📝 Dane Klienta")
        header_label.setFont(QFont("Segoe UI", 14, QFont.Bold))
        header_label.setStyleSheet(f"color: {ModernTheme.TEXT_PRIMARY.name()}; background-color: {ModernTheme.SECONDARY.name()};")
        right_layout.addWidget(header_label)
        
        # Formularz
        form_layout = QVBoxLayout()
        form_layout.setSpacing(8)
        
        # RZĄD 1: Daty rezerwacji
        row1_layout = QVBoxLayout()
        
        # Data od
        od_layout = QHBoxLayout()
        od_layout.addWidget(QLabel("📅 Data od:"))
        
        self.od_dzien = QLineEdit()
        self.od_dzien.setPlaceholderText("DD")
        self.od_dzien.setMaxLength(2)
        self.od_dzien.setFixedWidth(45)
        od_layout.addWidget(self.od_dzien)
        
        self.od_miesiac = QLineEdit()
        self.od_miesiac.setPlaceholderText("MM")
        self.od_miesiac.setMaxLength(2)
        self.od_miesiac.setFixedWidth(45)
        od_layout.addWidget(self.od_miesiac)
        
        self.od_rok = QLineEdit()
        self.od_rok.setPlaceholderText("RR")
        self.od_rok.setMaxLength(4)
        self.od_rok.setFixedWidth(60)
        od_layout.addWidget(self.od_rok)
        
        # Przycisk kalendarza
        self.cal_od_btn = QPushButton("📅")
        self.cal_od_btn.setFixedSize(25, 25)
        self.cal_od_btn.setToolTip("Otwórz kalendarz")
        self.cal_od_btn.clicked.connect(lambda: self.open_calendar("od"))
        self.cal_od_btn.setStyleSheet(get_button_style(ModernTheme.INFO))
        od_layout.addWidget(self.cal_od_btn)
        od_layout.addStretch()
        
        # Data do
        do_layout = QHBoxLayout()
        do_layout.addWidget(QLabel("📅 Data do:"))
        
        self.do_dzien = QLineEdit()
        self.do_dzien.setPlaceholderText("DD")
        self.do_dzien.setMaxLength(2)
        self.do_dzien.setFixedWidth(45)
        do_layout.addWidget(self.do_dzien)
        
        self.do_miesiac = QLineEdit()
        self.do_miesiac.setPlaceholderText("MM")
        self.do_miesiac.setMaxLength(2)
        self.do_miesiac.setFixedWidth(45)
        do_layout.addWidget(self.do_miesiac)
        
        self.do_rok = QLineEdit()
        self.do_rok.setPlaceholderText("RR")
        self.do_rok.setMaxLength(4)
        self.do_rok.setFixedWidth(60)
        do_layout.addWidget(self.do_rok)
        
        # Przycisk kalendarza
        self.cal_do_btn = QPushButton("📅")
        self.cal_do_btn.setFixedSize(25, 25)
        self.cal_do_btn.setToolTip("Otwórz kalendarz")
        self.cal_do_btn.clicked.connect(lambda: self.open_calendar("do"))
        self.cal_do_btn.setStyleSheet(get_button_style(ModernTheme.INFO))
        do_layout.addWidget(self.cal_do_btn)
        do_layout.addStretch()
        
        row1_layout.addLayout(od_layout)
        row1_layout.addLayout(do_layout)
        form_layout.addLayout(row1_layout)
        
        # RZĄD 2: Wzrost i Waga
        row2_layout = QHBoxLayout()
        row2_layout.addWidget(QLabel("📏 Wzrost (cm):"))
        self.wzrost_entry = QLineEdit()
        self.wzrost_entry.setFixedWidth(80)
        row2_layout.addWidget(self.wzrost_entry)
        row2_layout.addWidget(QLabel("⚖️ Waga (kg):"))
        self.waga_entry = QLineEdit()
        self.waga_entry.setFixedWidth(80)
        row2_layout.addWidget(self.waga_entry)
        row2_layout.addStretch()
        form_layout.addLayout(row2_layout)
        
        # RZĄD 3: Poziom i Płeć
        row3_layout = QHBoxLayout()
        row3_layout.addWidget(QLabel("🎯 Poziom:"))
        self.poziom_entry = QLineEdit()
        self.poziom_entry.setPlaceholderText("1-6")
        self.poziom_entry.setFixedWidth(80)
        self.poziom_entry.setToolTip("Wpisz poziom 1-6")
        row3_layout.addWidget(self.poziom_entry)
        
        row3_layout.addWidget(QLabel("👤 Płeć:"))
        self.plec_entry = QLineEdit()
        self.plec_entry.setPlaceholderText("M/K/U")
        self.plec_entry.setFixedWidth(80)
        self.plec_entry.setToolTip("M=Mężczyzna, K=Kobieta, U=Wszyscy")
        row3_layout.addWidget(self.plec_entry)
        
        row3_layout.addStretch()
        form_layout.addLayout(row3_layout)
        
        # RZĄD 4: Przeznaczenie
        row4_layout = QVBoxLayout()
        row4_layout.addWidget(QLabel("🎿 Przeznaczenie:"))
        
        styl_group_widget = QGroupBox()
        styl_group_widget.setStyleSheet("QGroupBox { border: none; }")
        styl_container_layout = QVBoxLayout(styl_group_widget)
        
        # Pierwsza linia stylów
        styl_line1 = QHBoxLayout()
        self.styl_group = QRadioButton("Wszystkie")
        self.styl_group2 = QRadioButton("Slalom (SL)")
        self.styl_group3 = QRadioButton("Gigant (G)")
        self.styl_group4 = QRadioButton("Performance (SLG)")
        self.styl_group.setChecked(True)
        styl_line1.addWidget(self.styl_group)
        styl_line1.addWidget(self.styl_group2)
        styl_line1.addWidget(self.styl_group3)
        styl_line1.addWidget(self.styl_group4)
        styl_line1.addStretch()
        
        # Druga linia stylów
        styl_line2 = QHBoxLayout()
        self.styl_group5 = QRadioButton("Cały dzień (C)")
        self.styl_group6 = QRadioButton("Poza trasę (OFF)")
        styl_line2.addWidget(self.styl_group5)
        styl_line2.addWidget(self.styl_group6)
        styl_line2.addStretch()
        
        styl_container_layout.addLayout(styl_line1)
        styl_container_layout.addLayout(styl_line2)
        row4_layout.addWidget(styl_group_widget)
        form_layout.addLayout(row4_layout)
        
        # Przyciski
        button_layout = QHBoxLayout()
        button_layout.setSpacing(8)
        
        self.znajdz_button = QPushButton("🔍 Znajdź")
        self.znajdz_button.setStyleSheet(get_button_style(ModernTheme.SUCCESS))
        self.znajdz_button.clicked.connect(self.znajdz_i_wyswietl)
        
        self.wyczysc_button = QPushButton("🗑️ Wyczyść")
        self.wyczysc_button.setStyleSheet(get_button_style(ModernTheme.WARNING))
        self.wyczysc_button.clicked.connect(self.wyczysc_formularz)
        
        self.odswiez_rezerwacje_button = QPushButton("🔄 Odśwież rezerwacje")
        self.odswiez_rezerwacje_button.setStyleSheet(get_button_style(ModernTheme.INFO))
        self.odswiez_rezerwacje_button.clicked.connect(self.odswiez_rezerwacje)
        
        button_layout.addWidget(self.znajdz_button)
        button_layout.addWidget(self.wyczysc_button)
        button_layout.addWidget(self.odswiez_rezerwacje_button)
        button_layout.addStretch()
        
        form_layout.addLayout(button_layout)
        right_layout.addLayout(form_layout)
        
        header_layout.addWidget(right_side)
        
        # Ustaw obsługę automatycznego przechodzenia między polami
        self.setup_date_handlers()
        
        # Ustaw walidatory
        self.setup_validators()
        
        return top_frame
        
    def create_results_group(self):
        """Tworzy grupę wyników"""
        group = QGroupBox("🔍 Wyniki Doboru Nart")
        group.setFont(QFont("Segoe UI", 14, QFont.Bold))
        group.setStyleSheet(f"""
            QGroupBox {{
                font-weight: bold;
                border: 2px solid {ModernTheme.TERTIARY.name()};
                border-radius: 8px;
                margin-top: 10px;
                padding-top: 10px;
            }}
            QGroupBox::title {{
                subcontrol-origin: margin;
                left: 10px;
                padding: 0 5px 0 5px;
                top: 15px;
            }}
        """)
        
        layout = QVBoxLayout(group)
        layout.setContentsMargins(15, 20, 15, 15)
        
        # Pole tekstowe na wyniki
        self.wyniki_text = QTextEdit()
        self.wyniki_text.setReadOnly(True)
        self.wyniki_text.setMinimumHeight(500)
        self.wyniki_text.setStyleSheet(get_results_text_style())
        
        layout.addWidget(self.wyniki_text)
        
        return group
        
    def setup_styles(self):
        """Konfiguruje style aplikacji"""
        self.setStyleSheet(get_application_stylesheet())
    
    def setup_validators(self):
        """Ustawia walidatory dla pól"""
        # Walidator dla dnia (01-31)
        day_regex = QRegExp(r"^(0[1-9]|[12][0-9]|3[01])$")
        day_validator = QRegExpValidator(day_regex)
        self.od_dzien.setValidator(day_validator)
        self.do_dzien.setValidator(day_validator)
        
        # Walidator dla miesiąca (01-12)
        month_regex = QRegExp(r"^(0[1-9]|1[0-2])$")
        month_validator = QRegExpValidator(month_regex)
        self.od_miesiac.setValidator(month_validator)
        self.do_miesiac.setValidator(month_validator)
        
        # Walidator dla roku (0-9999)
        year_regex = QRegExp(r"^([0-9]|[1-9][0-9]|[1-9][0-9][0-9]|[1-9][0-9][0-9][0-9])$")
        year_validator = QRegExpValidator(year_regex)
        self.od_rok.setValidator(year_validator)
        self.do_rok.setValidator(year_validator)
        
        # Walidator dla poziomu (1-6)
        poziom_regex = QRegExp(r"^[1-6]$")
        poziom_validator = QRegExpValidator(poziom_regex)
        self.poziom_entry.setValidator(poziom_validator)
        
        # Walidator dla płci (M, K, U)
        plec_regex = QRegExp(r"^[MKUmku]$")
        plec_validator = QRegExpValidator(plec_regex)
        self.plec_entry.setValidator(plec_validator)
    
    def setup_date_handlers(self):
        """Ustawia obsługę automatycznego przechodzenia między polami"""
        # Data od
        self.od_dzien.textChanged.connect(lambda: self.auto_next_field(self.od_dzien, self.od_miesiac))
        self.od_miesiac.textChanged.connect(lambda: self.auto_next_field(self.od_miesiac, self.od_rok))
        self.od_rok.textChanged.connect(lambda: self.auto_complete_year_safe(self.od_rok))
        self.od_rok.textChanged.connect(lambda: self.auto_next_field(self.od_rok, self.do_dzien))
        
        # Data do
        self.do_dzien.textChanged.connect(lambda: self.auto_next_field(self.do_dzien, self.do_miesiac))
        self.do_miesiac.textChanged.connect(lambda: self.auto_next_field(self.do_miesiac, self.do_rok))
        self.do_rok.textChanged.connect(lambda: self.auto_complete_year_safe(self.do_rok))
        self.do_rok.textChanged.connect(lambda: self.auto_next_field(self.do_rok, self.wzrost_entry))
        
        # Wzrost, waga, poziom, płeć
        self.wzrost_entry.textChanged.connect(lambda: self.auto_next_field(self.wzrost_entry, self.waga_entry))
        self.waga_entry.textChanged.connect(lambda: self.auto_next_field(self.waga_entry, self.poziom_entry))
        self.poziom_entry.textChanged.connect(lambda: self.auto_next_field(self.poziom_entry, self.plec_entry))
    
    def auto_complete_year_safe(self, year_field):
        """Bezpieczne uzupełnianie roku"""
        text = year_field.text()
        
        if len(text) == 2 and text.isdigit():
            year = int(text)
            if year >= 0 and year <= 99:
                if year < 50:
                    full_year = 2000 + year
                else:
                    full_year = 1900 + year
                
                year_field.setText(str(full_year))
                
                if year_field == self.od_rok:
                    self.do_dzien.setFocus()
                    self.do_dzien.selectAll()
                elif year_field == self.do_rok:
                    self.wzrost_entry.setFocus()
                    self.wzrost_entry.selectAll()
    
    def auto_next_field(self, current_field, next_field):
        """Automatyczne przechodzenie do następnego pola"""
        text = current_field.text()
        
        if current_field in [self.od_rok, self.do_rok]:
            if len(text) == 4 and text.isdigit():
                next_field.setFocus()
                next_field.selectAll()
        elif current_field == self.wzrost_entry:
            if len(text) == 3 and text.isdigit():
                next_field.setFocus()
                next_field.selectAll()
        elif current_field == self.waga_entry:
            if len(text) >= 2 and text.isdigit():
                try:
                    waga = int(text)
                    if 20 <= waga <= 200:
                        next_field.setFocus()
                        next_field.selectAll()
                except ValueError:
                    pass
        elif current_field == self.poziom_entry:
            if len(text) == 1 and text.isdigit():
                try:
                    poziom = int(text)
                    if 1 <= poziom <= 6:
                        next_field.setFocus()
                        next_field.selectAll()
                except ValueError:
                    pass
        elif current_field == self.plec_entry:
            if len(text) == 1 and text.upper() in ['M', 'K', 'U']:
                current_field.setText(text.upper())
                if hasattr(self, 'styl_group'):
                    self.styl_group.setFocus()
        else:
            if len(text) == 2 and text.isdigit():
                next_field.setFocus()
                next_field.selectAll()
    
    def open_calendar(self, target):
        """Otwiera kalendarz dla wybranego pola"""
        dialog = DatePickerDialog(self)
        if dialog.exec_() == QDialog.Accepted:
            selected_date = dialog.get_selected_date()
            
            day = selected_date.toString("dd")
            month = selected_date.toString("MM")
            year = selected_date.toString("yyyy")
            year_suffix = year[2:]
            
            if target == "od":
                self.od_dzien.setText(day)
                self.od_miesiac.setText(month)
                self.od_rok.setText(year_suffix)
            else:
                self.do_dzien.setText(day)
                self.do_miesiac.setText(month)
                self.do_rok.setText(year_suffix)
    
    def znajdz_i_wyswietl(self):
        """Główna funkcja wyszukiwania nart"""
        logger.info("Rozpoczęto wyszukiwanie nart")
        
        # Walidacja danych
        wzrost_text = self.wzrost_entry.text().strip()
        waga_text = self.waga_entry.text().strip()
        
        if not wzrost_text or not waga_text:
            QMessageBox.critical(self, "Błąd Danych", "Wypełnij pola Wzrost i Waga!")
            return
            
        try:
            wzrost_klienta = int(wzrost_text)
            waga_klienta = int(waga_text)
        except ValueError:
            QMessageBox.critical(self, "Błąd Danych", "Wzrost i waga muszą być liczbami!")
            return
        
        if wzrost_klienta < 100 or wzrost_klienta > 250:
            QMessageBox.critical(self, "Błąd Danych", "Wzrost musi być między 100 a 250 cm!")
            return
            
        if waga_klienta < 20 or waga_klienta > 200:
            QMessageBox.critical(self, "Błąd Danych", "Waga musi być między 20 a 200 kg!")
            return
        
        # Sprawdź poziom
        poziom_text = self.poziom_entry.text().strip()
        if not poziom_text:
            QMessageBox.critical(self, "Błąd Danych", "Wpisz poziom umiejętności (1-6)!")
            return
            
        try:
            poziom_klienta = int(poziom_text)
            if poziom_klienta < 1 or poziom_klienta > 6:
                QMessageBox.critical(self, "Błąd Danych", "Poziom musi być między 1 a 6!")
                return
        except ValueError:
            QMessageBox.critical(self, "Błąd Danych", "Poziom musi być liczbą od 1 do 6!")
            return

        # Sprawdź płeć
        plec_text = self.plec_entry.text().strip().upper()
        if not plec_text:
            QMessageBox.critical(self, "Błąd Danych", "Wpisz płeć (M/K/U)!")
            return
            
        if plec_text not in ['M', 'K', 'U']:
            QMessageBox.critical(self, "Błąd Danych", "Płeć musi być M (Mężczyzna), K (Kobieta) lub U (Wszyscy)!")
            return
            
        # Mapuj na pełne nazwy
        plec_mapping = {
            'M': 'Mężczyzna',
            'K': 'Kobieta', 
            'U': 'Wszyscy'
        }
        plec_klienta = plec_mapping[plec_text]
        
        # Pobierz daty rezerwacji
        od_dzien = self.od_dzien.text().strip()
        od_miesiac = self.od_miesiac.text().strip()
        od_rok = self.od_rok.text().strip()
        
        do_dzien = self.do_dzien.text().strip()
        do_miesiac = self.do_miesiac.text().strip()
        do_rok = self.do_rok.text().strip()
        
        if not all([od_dzien, od_miesiac, od_rok, do_dzien, do_miesiac, do_rok]):
            QMessageBox.warning(self, "Uwaga", "Wypełnij wszystkie pola dat rezerwacji!")
            return
            
        try:
            # Konwertuj na pełne daty
            if len(od_rok) == 4:
                od_full_year = od_rok
            else:
                od_full_year = f"20{od_rok}"
                
            if len(do_rok) == 4:
                do_full_year = do_rok
            else:
                do_full_year = f"20{do_rok}"
            
            import pandas as pd
            data_od = pd.to_datetime(f"{od_full_year}-{od_miesiac}-{od_dzien}").date()
            data_do = pd.to_datetime(f"{do_full_year}-{do_miesiac}-{do_dzien}").date()
            
        except Exception as e:
            QMessageBox.critical(self, "Błąd Danych", f"Nieprawidłowa data: {e}")
            return
            
        if data_od > data_do:
            QMessageBox.critical(self, "Błąd Danych", "Data rozpoczęcia musi być wcześniejsza niż data zakończenia!")
            return
        
        # Pobierz styl jazdy
        styl = "Wszystkie"
        if self.styl_group2.isChecked(): styl = "SL"
        elif self.styl_group3.isChecked(): styl = "G"
        elif self.styl_group4.isChecked(): styl = "SLG"
        elif self.styl_group5.isChecked(): styl = "C"
        elif self.styl_group6.isChecked(): styl = "OFF"
        
        logger.info(f"Wywołuję dobierz_narty z parametrami: wzrost={wzrost_klienta}, waga={waga_klienta}, poziom={poziom_klienta}, plec={plec_klienta}, styl={styl}")
        
        idealne, poziom_za_nisko, alternatywy, inna_plec = dobierz_narty(wzrost_klienta, waga_klienta, poziom_klienta, plec_klienta, styl)
        
        # Wyczyść pole tekstowe
        self.wyniki_text.clear()
        
        if idealne is None:
            logger.error("dobierz_narty zwróciło None - błąd w funkcji")
            QMessageBox.critical(self, "Błąd", "Wystąpił błąd podczas dobierania nart. Sprawdź logi.")
            return
        
        # Sprawdź czy są jakieś wyniki
        if not idealne and not poziom_za_nisko and not alternatywy and not inna_plec:
            self.wyniki_text.append("❌ BRAK DOPASOWANYCH NART")
            self.wyniki_text.append("=" * 50)
            self.wyniki_text.append("Nie znaleziono nart spełniających kryteria wyszukiwania.")
            return

        # Wyświetl wyniki
        if idealne:
            self.wyniki_text.append("✅ IDEALNE DOPASOWANIA:")
            self.wyniki_text.append("=" * 50)
            for narta_info in idealne:
                self.wyswietl_jedna_narte(narta_info, wzrost_klienta, waga_klienta, poziom_klienta, plec_klienta, data_od, data_do)
            self.wyniki_text.append("")
        
        if poziom_za_nisko:
            self.wyniki_text.append("🟡 POZIOM ZA NISKO:")
            self.wyniki_text.append("=" * 50)
            for narta_info in poziom_za_nisko:
                self.wyswietl_jedna_narte(narta_info, wzrost_klienta, waga_klienta, poziom_klienta, plec_klienta, data_od, data_do)
            self.wyniki_text.append("")
        
        if alternatywy:
            self.wyniki_text.append("⚠️ ALTERNATYWY:")
            self.wyniki_text.append("=" * 50)
            for narta_info in alternatywy:
                self.wyswietl_jedna_narte(narta_info, wzrost_klienta, waga_klienta, poziom_klienta, plec_klienta, data_od, data_do)
            self.wyniki_text.append("")
        
        if inna_plec:
            self.wyniki_text.append("👥 INNA PŁEĆ:")
            self.wyniki_text.append("=" * 50)
            for narta_info in inna_plec:
                self.wyswietl_jedna_narte(narta_info, wzrost_klienta, waga_klienta, poziom_klienta, plec_klienta, data_od, data_do)
            self.wyniki_text.append("")
        
        # Przewiń do początku wyników
        self.wyniki_text.moveCursor(self.wyniki_text.textCursor().Start)
    
    def wyswietl_jedna_narte(self, narta_info, w, s, p, plec_klienta, data_od=None, data_do=None):
        """Wyświetla informacje o jednej narcie"""
        narta = narta_info['dane']
        dopasowanie = narta_info['dopasowanie']
        
        # Współczynnik idealności
        wspolczynnik = narta_info.get('wspolczynnik_idealnosci', 0)
        if wspolczynnik >= 90:
            wspolczynnik_emoji = "🎯"
        elif wspolczynnik >= 80:
            wspolczynnik_emoji = "✅"
        elif wspolczynnik >= 70:
            wspolczynnik_emoji = "👍"
        elif wspolczynnik >= 60:
            wspolczynnik_emoji = "⚡"
        else:
            wspolczynnik_emoji = "📊"
        
        # Nazwa narty i długość z współczynnikiem
        self.wyniki_text.append(f"► {narta['MARKA']} {narta['MODEL']} ({narta['DLUGOSC']} cm) {wspolczynnik_emoji} {wspolczynnik}%")
        
        # Sprawdź rezerwacje
        ilosc_sztuk = int(narta.get('ILOSC', '1') or '1')
        dostepnosc_text = "   📦 Dostępność: "
        
        for i in range(ilosc_sztuk):
            jest_zarezerwowana, okres_rezerwacji, numer_narty = sprawdz_czy_narta_zarezerwowana(
                narta['MARKA'], narta['MODEL'], narta['DLUGOSC'], data_od, data_do
            )
            
            if jest_zarezerwowana and numer_narty:
                if f"//{i+1:02d}" in numer_narty or f"//{i+1}" in numer_narty:
                    dostepnosc_text += f"🔴{i+1} "
                else:
                    dostepnosc_text += f"🟩{i+1} "
            elif jest_zarezerwowana and not numer_narty:
                dostepnosc_text += f"🔴{i+1} "
            else:
                dostepnosc_text += f"🟩{i+1} "
        
        self.wyniki_text.append(dostepnosc_text)
        
        # Informacje o rezerwacjach
        if jest_zarezerwowana and okres_rezerwacji:
            rezerwacja_text = f"   🚫 Zarezerwowana: {okres_rezerwacji}"
            if numer_narty:
                rezerwacja_text += f" (Nr: {numer_narty})"
            self.wyniki_text.append(rezerwacja_text)
        
        # Dopasowanie
        poziom_status = dopasowanie.get('poziom')
        plec_status = dopasowanie.get('plec')
        waga_status = dopasowanie.get('waga')
        wzrost_status = dopasowanie.get('wzrost')
        przeznaczenie_status = dopasowanie.get('przeznaczenie')
        
        dopasowanie_text = "   📊 Dopasowanie: "
        
        # Poziom
        poziom_color = "🟢" if poziom_status[1] == "OK" else "🟡"
        dopasowanie_text += f"{poziom_color} P:{p}({poziom_status[2]})→{poziom_status[1]} | "
        
        # Płeć
        plec_color = "🟢" if plec_status[1] == "OK" else "🟡"
        plec_klienta_display = "D" if plec_klienta == "Wszyscy" else plec_klienta[0]
        plec_narty_display = plec_status[2]
        dopasowanie_text += f"{plec_color} Pł:{plec_klienta_display}({plec_narty_display})→{plec_status[1]} | "
        
        # Waga
        waga_color = "🟢" if waga_status[1] == "OK" else "🟡"
        dopasowanie_text += f"{waga_color} W:{s}kg({waga_status[2]}-{waga_status[3]})→{waga_status[1]} | "
        
        # Wzrost
        wzrost_color = "🟢" if wzrost_status[1] == "OK" else "🟡"
        dopasowanie_text += f"{wzrost_color} Wz:{w}cm({wzrost_status[2]}-{wzrost_status[3]})→{wzrost_status[1]} | "
        
        # Przeznaczenie
        przeznaczenie_color = "🟢" if przeznaczenie_status[1] == "OK" else "🟡"
        dopasowanie_text += f"{przeznaczenie_color} Pr:{przeznaczenie_status[2]}→{przeznaczenie_status[1]}"
        
        self.wyniki_text.append(dopasowanie_text)

        # Informacje dodatkowe
        promien = narta.get('PROMIEN', 'Brak')
        pod_butem = narta.get('POD_BUTEM', 'Brak')
        uwagi = narta.get('UWAGI', 'Brak')
        
        if promien and promien != 'Brak':
            promien_clean = str(promien).replace(',', '.')
        else:
            promien_clean = 'Brak'
        
        info_text = f"   ℹ️ Promień: {promien_clean} | Pod butem: {pod_butem}mm"
        self.wyniki_text.append(info_text)
        
        if uwagi and uwagi != 'Brak':
            uwagi_text = f"   📝 Uwagi: {uwagi}"
            self.wyniki_text.append(uwagi_text)
        
        self.wyniki_text.append("   " + "─" * 80)
    
    def wyczysc_formularz(self):
        """Czyści formularz"""
        self.wzrost_entry.clear()
        self.waga_entry.clear()
        self.poziom_entry.clear()
        self.plec_entry.clear()
        self.styl_group.setChecked(True)
        
        # Wyczyść daty i ustaw domyślne wartości
        now = datetime.now()
        future = now + timedelta(days=7)
        
        self.od_dzien.setText(now.strftime("%d"))
        self.od_miesiac.setText(now.strftime("%m"))
        self.od_rok.setText(now.strftime("%y"))
        
        self.do_dzien.setText(future.strftime("%d"))
        self.do_miesiac.setText(future.strftime("%m"))
        self.do_rok.setText(future.strftime("%y"))
        
        self.wyniki_text.clear()
        logger.info("Formularz wyczyszczony")
    
    def odswiez_rezerwacje(self):
        """Odświeża rezerwacje z pliku FireSnow"""
        logger.info("Odświeżanie rezerwacji z FireSnow...")
        
        try:
            self.wyniki_text.clear()
            
            current_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            rez_file = os.path.join(current_dir, 'pliki_danych', 'rez.csv')
            
            if not os.path.exists(rez_file):
                self.wyniki_text.append("❌ BŁĄD: Plik rez.csv nie istnieje!")
                self.wyniki_text.append(f"Szukam w: {current_dir}")
                return
            
            self.wyniki_text.append("🔄 REZERWACJE Z FIRESNOW")
            self.wyniki_text.append("=" * 50)
            
            import pandas as pd
            try:
                df = pd.read_csv(rez_file, encoding='utf-8-sig', header=1)
                logger.info(f"Wczytano {len(df)} wierszy z rez.csv (header=1)")
            except Exception as e:
                logger.warning(f"Błąd z header=1, próbuję header=0: {e}")
                df = pd.read_csv(rez_file, encoding='utf-8-sig', header=0)
                logger.info(f"Wczytano {len(df)} wierszy z rez.csv (header=0)")
            
            if 'Od' in df.columns and 'Do' in df.columns and 'Sprzęt' in df.columns:
                df_rezerwacje = df.dropna(subset=['Od', 'Do']).copy()
                logger.info(f"Znaleziono {len(df_rezerwacje)} wierszy z datami")
                df_narty = df_rezerwacje[df_rezerwacje['Sprzęt'].str.contains('NARTY', na=False)].copy()
            else:
                logger.warning(f"Nieznany format kolumn: {list(df.columns)}")
                self.wyniki_text.append(f"❌ BŁĄD: Nieznany format kolumn w pliku rez.csv")
                return
            
            logger.info(f"Znaleziono {len(df_narty)} rezerwacji nart")
            
            if len(df_narty) == 0:
                self.wyniki_text.append("ℹ️ Brak rezerwacji nart w pliku")
                return
            
            self.wyniki_text.append(f"📊 Znaleziono {len(df_narty)} rezerwacji nart")
            self.wyniki_text.append("")
            
            for i, (_, rez) in enumerate(df_narty.iterrows(), 1):
                sprzet = rez.get('Sprzęt', '')
                if 'NARTY' in sprzet:
                    parts = sprzet.split()
                    if len(parts) >= 4:
                        marka = parts[1] if len(parts) > 1 else "Nieznana"
                        dlugosc = "Nieznana"
                        for part in parts:
                            if 'cm' in part:
                                dlugosc = part.replace('cm', '').strip()
                                break
                        numer = "Brak"
                        for part in parts:
                            if part.startswith('//') and len(part) > 2:
                                numer = part
                                break
                    else:
                        marka = "Nieznana"
                        dlugosc = "Nieznana"
                        numer = "Brak"
                else:
                    marka = "Nieznana"
                    dlugosc = "Nieznana"
                    numer = "Brak"
                
                try:
                    data_od = pd.to_datetime(rez['Od']).strftime('%Y-%m-%d')
                    data_do = pd.to_datetime(rez['Do']).strftime('%Y-%m-%d')
                except:
                    data_od = "Brak daty"
                    data_do = "Brak daty"
                
                klient = rez.get('Klient', 'Nieznany')
                
                self.wyniki_text.append(f"{i}. 🎿 {marka} ({dlugosc} cm)")
                self.wyniki_text.append(f"   📅 Okres: {data_od} - {data_do}")
                self.wyniki_text.append(f"   👤 Klient: {klient}")
                self.wyniki_text.append(f"   🔢 Numer: {numer}")
                self.wyniki_text.append("")
            
            logger.info(f"Wyświetlono {len(df_narty)} rezerwacji")
            
        except Exception as e:
            logger.error(f"Błąd podczas odświeżania rezerwacji: {e}")
            self.wyniki_text.clear()
            self.wyniki_text.append("❌ BŁĄD ODSWIEŻANIA REZERWACJI")
            self.wyniki_text.append("=" * 50)
            self.wyniki_text.append(f"Wystąpił błąd: {e}")
            self.wyniki_text.append("")
            self.wyniki_text.append("Sprawdź czy plik rez.csv istnieje i ma poprawny format.")
