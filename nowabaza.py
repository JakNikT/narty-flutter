# WERSJA 6.0 - PYQT5 COMBINED VERSION
# System doboru nart z integracją FireSnow

import sys
import csv
import pandas as pd
from datetime import datetime, timedelta
import os
import logging
import math
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QLabel, QPushButton, 
                             QLineEdit, QComboBox, QRadioButton, QTextEdit,
                             QTableWidget, QTableWidgetItem,
                             QFrame, QGroupBox, QMessageBox, QCalendarWidget, QDialog)
from PyQt5.QtCore import Qt, QRegExp
from PyQt5.QtGui import QFont, QPixmap, QColor, QRegExpValidator

# ===== KONFIGURACJA LOGOWANIA =====
def setup_logging():
    """Konfiguruje system logowania"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler('aplikacja_narty.log', encoding='utf-8'),
            logging.StreamHandler()
        ]
    )
    return logging.getLogger(__name__)

logger = setup_logging()

# ===== SYSTEM WSPÓŁCZYNNIKA IDEALNOŚCI I WAG =====
class CompatibilityScorer:
    """Klasa do obliczania współczynnika idealności dopasowania nart"""
    
    def __init__(self):
        # Domyślne wagi kryteriów (suma = 1.0)
        self.wagi_kryteriow = {
            'poziom': 0.35,      # 35% - Najważniejsze (bezpieczeństwo)
            'waga': 0.25,        # 25% - Bardzo ważne (kontrola nart)
            'wzrost': 0.20,      # 20% - Ważne (stabilność i zwrotność)
            'plec': 0.15,        # 15% - Mniej ważne (ergonomia)
            'przeznaczenie': 0.05 # 5% - Najmniej ważne (styl jazdy)
        }
        
        # Parametry funkcji gaussowskich dla różnych kryteriów
        self.tolerancje = {
            'poziom': 1.0,       # Standardowe odchylenie dla poziomu
            'waga': 8.0,         # Standardowe odchylenie dla wagi (kg)
            'wzrost': 8.0,       # Standardowe odchylenie dla wzrostu (cm)
        }
    
    def gaussian_score(self, value, target, tolerance):
        """
        Oblicza wynik na podstawie funkcji gaussowskiej
        Zwraca wartość 0-1, gdzie 1 = idealne dopasowanie
        """
        if tolerance == 0:
            return 1.0 if value == target else 0.0
        
        distance = abs(value - target)
        return math.exp(-0.5 * (distance / tolerance) ** 2)
    
    def score_poziom(self, poziom_klienta, poziom_narty_info):
        """Ocenia dopasowanie poziomu umiejętności"""
        # Wyciągnij rzeczywisty poziom z informacji o narcie
        if isinstance(poziom_narty_info, tuple) and len(poziom_narty_info) >= 3:
            status, opis, poziom_str = poziom_narty_info
            
            if status == 'green' and 'OK' in opis:
                return 1.0  # Idealne dopasowanie
            elif status == 'orange':
                if 'jeden poziom' in opis:
                    return 0.7  # Dobry wynik dla 1 poziom różnicy
                else:
                    return 0.4  # Słabszy wynik dla większych różnic
            else:
                return 0.1  # Bardzo słaby wynik
        
        return 0.5  # Domyślny wynik gdy nie można sparsować
    
    def score_waga(self, waga_klienta, waga_narty_info):
        """Ocenia dopasowanie wagi"""
        if isinstance(waga_narty_info, tuple) and len(waga_narty_info) >= 4:
            status, opis, waga_min, waga_max = waga_narty_info
            
            if status == 'green':
                # Oblicz jak blisko środka zakresu jest klient
                waga_srodek = (waga_min + waga_max) / 2
                return self.gaussian_score(waga_klienta, waga_srodek, self.tolerancje['waga'])
            elif status == 'orange':
                # Klient jest poza zakresem ale w tolerancji
                if waga_klienta > waga_max:
                    distance = waga_klienta - waga_max
                else:
                    distance = waga_min - waga_klienta
                
                # Im mniejsza odległość od zakresu, tym lepszy wynik
                return max(0.3, 0.8 - (distance / 10.0))
            else:
                return 0.1
        
        return 0.5
    
    def score_wzrost(self, wzrost_klienta, wzrost_narty_info):
        """Ocenia dopasowanie wzrostu"""
        if isinstance(wzrost_narty_info, tuple) and len(wzrost_narty_info) >= 4:
            status, opis, wzrost_min, wzrost_max = wzrost_narty_info
            
            if status == 'green':
                # Oblicz jak blisko środka zakresu jest klient
                wzrost_srodek = (wzrost_min + wzrost_max) / 2
                return self.gaussian_score(wzrost_klienta, wzrost_srodek, self.tolerancje['wzrost'])
            elif status == 'orange':
                # Klient jest poza zakresem ale w tolerancji
                if wzrost_klienta > wzrost_max:
                    distance = wzrost_klienta - wzrost_max
                else:
                    distance = wzrost_min - wzrost_klienta
                
                # Im mniejsza odległość od zakresu, tym lepszy wynik
                return max(0.3, 0.8 - (distance / 15.0))
            else:
                return 0.1
        
        return 0.5
    
    def score_plec(self, plec_klienta, plec_narty_info):
        """Ocenia dopasowanie płci"""
        if isinstance(plec_narty_info, tuple) and len(plec_narty_info) >= 2:
            status, opis = plec_narty_info[:2]
            
            if status == 'green' and 'OK' in opis:
                return 1.0  # Idealne dopasowanie
            elif status == 'orange':
                if 'Narta męska' in opis or 'Narta kobieca' in opis:
                    return 0.6  # Narta dla przeciwnej płci
                else:
                    return 0.8  # Inne problemy z płcią
            else:
                return 0.2
        
        return 0.5
    
    def score_przeznaczenie(self, styl_klienta, przeznaczenie_narty_info):
        """Ocenia dopasowanie przeznaczenia/stylu jazdy"""
        if not styl_klienta or styl_klienta == "Wszystkie":
            return 1.0  # Brak preferencji = pełny wynik
        
        if isinstance(przeznaczenie_narty_info, tuple) and len(przeznaczenie_narty_info) >= 2:
            status, opis = przeznaczenie_narty_info[:2]
            
            if status == 'green' and 'OK' in opis:
                return 1.0  # Idealne dopasowanie stylu
            elif status == 'orange':
                return 0.5  # Inne przeznaczenie
            else:
                return 0.2
        
        return 0.7  # Domyślny wynik gdy brak informacji
    
    def oblicz_wspolczynnik_idealnosci(self, dopasowanie, wzrost_klienta, waga_klienta, 
                                     poziom_klienta, plec_klienta, styl_klienta=None):
        """
        Główna funkcja obliczająca współczynnik idealności (0-100%)
        """
        wyniki_kryteriow = {}
        
        # Oceń każde kryterium
        if 'poziom' in dopasowanie:
            wyniki_kryteriow['poziom'] = self.score_poziom(poziom_klienta, dopasowanie['poziom'])
        
        if 'waga' in dopasowanie:
            wyniki_kryteriow['waga'] = self.score_waga(waga_klienta, dopasowanie['waga'])
        
        if 'wzrost' in dopasowanie:
            wyniki_kryteriow['wzrost'] = self.score_wzrost(wzrost_klienta, dopasowanie['wzrost'])
        
        if 'plec' in dopasowanie:
            wyniki_kryteriow['plec'] = self.score_plec(plec_klienta, dopasowanie['plec'])
        
        if 'przeznaczenie' in dopasowanie:
            wyniki_kryteriow['przeznaczenie'] = self.score_przeznaczenie(styl_klienta, dopasowanie['przeznaczenie'])
        
        # Oblicz ważoną średnią
        suma_wazona = 0.0
        suma_wag = 0.0
        
        for kryterium, wynik in wyniki_kryteriow.items():
            if kryterium in self.wagi_kryteriow:
                waga = self.wagi_kryteriow[kryterium]
                suma_wazona += wynik * waga
                suma_wag += waga
        
        # Znormalizuj wynik do 0-100%
        if suma_wag > 0:
            wspolczynnik = (suma_wazona / suma_wag) * 100
        else:
            wspolczynnik = 0
        
        return round(wspolczynnik, 1), wyniki_kryteriow
    
    def ustaw_wagi(self, nowe_wagi):
        """Pozwala na dostosowanie wag kryteriów"""
        suma = sum(nowe_wagi.values())
        if abs(suma - 1.0) > 0.01:
            raise ValueError(f"Suma wag musi wynosić 1.0, a wynosi {suma}")
        
        self.wagi_kryteriow.update(nowe_wagi)
        logger.info(f"Zaktualizowano wagi kryteriów: {self.wagi_kryteriow}")

# Globalna instancja scorera
compatibility_scorer = CompatibilityScorer()

# ===== NOWOCZESNY MOTYW KOLORÓW - NIEBIESKI JAK LOGO =====
class ModernTheme:
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

# ===== FUNKCJE OBSŁUGI REZERWACJI Z FIRESNOW =====
def wczytaj_rezerwacje_firesnow():
    """Wczytuje rezerwacje z pliku rez.csv (sprawdzony format)"""
    try:
        # Sprawdź w katalogu programu
        current_dir = os.path.dirname(os.path.abspath(__file__))
        rez_csv = os.path.join(current_dir, 'rez.csv')
        rez_xlsx = os.path.join(current_dir, 'rez.xlsx')
        
        # Użyj sprawdzonego pliku rez.csv
        if os.path.exists(rez_csv):
            # Użyj pliku CSV - header=1 bo pierwszy wiersz to "Unnamed", ale sprawdź strukturę
            try:
                df = pd.read_csv(rez_csv, encoding='utf-8-sig', header=1)
                logger.info("Wczytano dane z rez.csv")
                return przetworz_dane_narty(df)
            except Exception as e:
                logger.warning(f"Błąd parsowania z header=1, próbuję header=0: {e}")
                # Fallback: spróbuj z header=0
                df = pd.read_csv(rez_csv, encoding='utf-8-sig', header=0)
                logger.info("Wczytano dane z rez.csv (header=0)")
                return przetworz_dane_narty(df)
        elif os.path.exists(rez_xlsx):
            # Wczytaj dane z Excel
            df = pd.read_excel(rez_xlsx, header=1)
            logger.info("Wczytano dane z rez.xlsx")
            return przetworz_dane_narty(df)
        else:
            logger.warning("Brak plików z rezerwacjami")
            return pd.DataFrame()
        
    except Exception as e:
        logger.error(f"Błąd podczas wczytywania rezerwacji: {e}")
        return pd.DataFrame()

def przetworz_dane_narty(df):
    """Przetwarza surowe dane rezerwacji i wyciąga informacje o nartach"""
    try:
        # Sprawdź czy kolumny istnieją - obsłuż różne formaty
        if 'Od' in df.columns and 'Do' in df.columns and 'Sprzęt' in df.columns:
            # Nowy format z polskimi nazwami kolumn
            df_rezerwacje = df.dropna(subset=['Od', 'Do']).copy()
            df_narty = df_rezerwacje[df_rezerwacje['Sprzęt'].str.contains('NARTY', na=False)].copy()
        elif 'Data_Od' in df.columns and 'Data_Do' in df.columns and 'Sprzet' in df.columns:
            # Stary format z angielskimi nazwami kolumn
            df_rezerwacje = df.dropna(subset=['Data_Od', 'Data_Do']).copy()
            df_narty = df_rezerwacje[df_rezerwacje['Sprzet'].str.contains('NARTY', na=False)].copy()
            # Mapuj na nowe nazwy
            df_narty = df_narty.rename(columns={'Data_Od': 'Od', 'Data_Do': 'Do', 'Sprzet': 'Sprzęt'})
        else:
            logger.warning(f"Nieznany format kolumn: {list(df.columns)}")
            return pd.DataFrame()
        
        if len(df_narty) == 0:
            logger.info("Brak rezerwacji nart w pliku")
            return pd.DataFrame()
        
        # Wyciągnij informacje o nartach z kolumny Sprzęt
        def wyciagnij_info_narty(sprzet):
            """Wyciąga markę, model, długość i numer narty z opisu sprzętu"""
            if pd.isna(sprzet) or not isinstance(sprzet, str):
                return None, None, None, None
            
            # Przykład: "NARTY KNEISSL MY STAR XC 144cm /2024 //01"
            parts = sprzet.split()
            if len(parts) < 4:
                return None, None, None, None
            
            # Znajdź markę (pierwsze słowo po "NARTY")
            marka = parts[1] if len(parts) > 1 else None
            
            # Znajdź długość (słowo zawierające "cm")
            dlugosc = None
            for part in parts:
                if 'cm' in part:
                    dlugosc = part.replace('cm', '').strip()
                    break
            
            # Znajdź numer narty (ostatnie //XX)
            numer = None
            for part in parts:
                if part.startswith('//') and len(part) > 2:
                    numer = part
                    break
            
            # Model to wszystko między marką a długością
            model_parts = []
            for i, part in enumerate(parts[2:], 2):
                if 'cm' in part:
                    break
                model_parts.append(part)
            model = ' '.join(model_parts) if model_parts else None
            
            return marka, model, dlugosc, numer
        
        # Dodaj kolumny z informacjami o nartach
        narty_info = df_narty['Sprzęt'].apply(wyciagnij_info_narty)
        df_narty['Marka'] = [info[0] for info in narty_info]
        df_narty['Model'] = [info[1] for info in narty_info]
        df_narty['Dlugosc'] = [info[2] for info in narty_info]
        df_narty['Numer_Narty'] = [info[3] for info in narty_info]
        
        # Filtruj tylko wiersze z poprawnie wyciągniętymi danymi
        df_narty = df_narty.dropna(subset=['Marka', 'Model', 'Dlugosc'])
        
        logger.info(f"Przetworzono {len(df_narty)} rezerwacji nart")
        return df_narty
        
    except Exception as e:
        logger.error(f"Błąd podczas przetwarzania danych nart: {e}")
        return pd.DataFrame()

def sprawdz_czy_narta_zarezerwowana(marka, model, dlugosc, data_od=None, data_do=None):
    """Sprawdza czy narta jest zarezerwowana w danym terminie"""
    try:
        rezerwacje = wczytaj_rezerwacje_firesnow()
        if rezerwacje.empty:
            return False, None, None
        
        # Konwertuj daty do porównania
        if data_od and data_do:
            data_od = pd.to_datetime(data_od).date()
            data_do = pd.to_datetime(data_do).date()
        else:
            return False, None, None
        
        # Sprawdź czy narta jest zarezerwowana w danym terminie
        for _, rezerwacja in rezerwacje.iterrows():
            if (rezerwacja['Marka'] == marka and 
                rezerwacja['Model'] == model and 
                str(rezerwacja['Dlugosc']) == str(dlugosc)):
                
                # Konwertuj daty rezerwacji - sprawdź różne nazwy kolumn
                try:
                    # Sprawdź czy to nowy format (Od, Do) czy stary (Data_Od, Data_Do)
                    if 'Od' in rezerwacja and 'Do' in rezerwacja:
                        data_od_rez = pd.to_datetime(rezerwacja['Od']).date()
                        data_do_rez = pd.to_datetime(rezerwacja['Do']).date()
                    elif 'Data_Od' in rezerwacja and 'Data_Do' in rezerwacja:
                        data_od_rez = pd.to_datetime(rezerwacja['Data_Od']).date()
                        data_do_rez = pd.to_datetime(rezerwacja['Data_Do']).date()
                    else:
                        continue
                    
                    # Sprawdź czy terminy się nakładają
                    if not (data_do < data_od_rez or data_od > data_do_rez):
                        numer_narty = rezerwacja.get('Numer_Narty', '')
                        return True, f"{data_od_rez} - {data_do_rez}", numer_narty
                except:
                    continue
        
        return False, None, None
        
    except Exception as e:
        logger.error(f"Błąd podczas sprawdzania rezerwacji: {e}")
        return False, None, None

# ===== GŁÓWNA LOGIKA DOBIERANIA NART (zachowana z oryginału) =====
def dobierz_narty(wzrost, waga, poziom, plec, styl_jazdy=None):
    logger.info(f"Szukanie nart: wzrost={wzrost}, waga={waga}, poziom={poziom}, plec={plec}, styl={styl_jazdy}")
    
    idealne_dopasowanie = []
    poziom_niżej = []  # Nowa kategoria: 1 poziom za niski, reszta OK
    dobre_alternatywy = []
    ponizej_poziomu = []  # 2+ poziomy za niskie
    inna_plec = []  # Nowa kategoria: narty z niepasującą płcią
    
    WAGA_TOLERANCJA = 5
    WZROST_TOLERANCJA = 5
    POZIOM_TOLERANCJA_W_DOL = 2

    try:
        # Sprawdź w katalogu programu
        current_dir = os.path.dirname(os.path.abspath(__file__))
        csv_file = os.path.join(current_dir, 'NOWABAZA_final.csv')
        
        with open(csv_file, 'r', newline='', encoding='utf-8-sig') as file:
            reader = csv.DictReader(file)
            wszystkie_narty = list(reader)

            # Nie filtruj nart według przeznaczenia - przeznaczenie będzie uwzględnione w kategoryzacji
            narty_do_analizy = wszystkie_narty
            
            for row in narty_do_analizy:
                try:
                    if not all(key in row and row[key] for key in ['POZIOM', 'WAGA_MIN', 'WAGA_MAX', 'WZROST_MIN', 'WZROST_MAX', 'DLUGOSC', 'PLEC']):
                        continue

                    waga_min = int(float(row['WAGA_MIN']))
                    waga_max = int(float(row['WAGA_MAX']))
                    min_wzrost_narciarza = int(float(row['WZROST_MIN']))
                    max_wzrost_narciarza = int(float(row['WZROST_MAX']))
                    narta_plec = row.get('PLEC', 'U').strip() or 'U'

                    # Nowa logika poziomów z jedną kolumną POZIOM
                    poziom_text = row.get('POZIOM', '').strip()
                    
                    # Parsuj poziom w zależności od formatu
                    if '/' in poziom_text:
                        # Format unisex: "5M/6D"
                        try:
                            parts = poziom_text.split('/')
                            pm_part = parts[0].replace('M', '').strip()
                            pd_part = parts[1].replace('D', '').strip()
                            
                            if plec == "Kobieta":
                                # Dla kobiet: sprawdź oba poziomy - damski jako główny, męski jako alternatywa
                                poziom_min = int(float(pd_part))
                                poziom_display = f"PD{pd_part}"
                                # Dodaj informację o poziomie męskim dla nart unisex
                                if narta_plec == "U":
                                    poziom_display += f" (PM{pm_part})"
                            elif plec == "Mężczyzna":
                                # Dla mężczyzn: sprawdź oba poziomy - męski jako główny, damski jako alternatywa
                                poziom_min = int(float(pm_part))
                                poziom_display = f"PM{pm_part}"
                                # Dodaj informację o poziomie damskim dla nart unisex
                                if narta_plec == "U":
                                    poziom_display += f" (PD{pd_part})"
                            else:  # Wszyscy
                                poziom_min = min(int(float(pm_part)), int(float(pd_part)))
                                poziom_display = f"PM{pm_part}/PD{pd_part}"
                        except:
                            continue  # Błąd parsowania
                    elif ' ' in poziom_text and ('M' in poziom_text or 'D' in poziom_text):
                        # Format unisex ze spacją: "5M 6D"
                        try:
                            parts = poziom_text.split()
                            pm_part = None
                            pd_part = None
                            
                            for part in parts:
                                if 'M' in part:
                                    pm_part = part.replace('M', '').strip()
                                elif 'D' in part:
                                    pd_part = part.replace('D', '').strip()
                            
                            if plec == "Kobieta" and pd_part:
                                poziom_min = int(float(pd_part))
                                poziom_display = f"PD{pd_part}"
                            elif plec == "Mężczyzna" and pm_part:
                                poziom_min = int(float(pm_part))
                                poziom_display = f"PM{pm_part}"
                            elif plec == "Wszyscy" and pm_part and pd_part:
                                poziom_min = min(int(float(pm_part)), int(float(pd_part)))
                                poziom_display = f"PM{pm_part}/PD{pd_part}"
                            else:
                                continue
                        except:
                            continue  # Błąd parsowania
                    elif 'M' in poziom_text:
                        # Format męski: "5M" - teraz dostępny dla wszystkich
                        try:
                            poziom_min = int(float(poziom_text.replace('M', '').strip()))
                            poziom_display = f"PM{poziom_text.replace('M', '').strip()}"
                            
                            # Sprawdź czy poziom nie jest o 2+ za niski - wyklucz całkowicie
                            if poziom < poziom_min - POZIOM_TOLERANCJA_W_DOL:
                                continue  # Wyklucz narty o 2+ poziomy za niskie
                        except:
                            continue  # Błąd parsowania
                    elif 'D' in poziom_text:
                        # Format damski: "5D" - teraz dostępny dla wszystkich
                        try:
                            poziom_min = int(float(poziom_text.replace('D', '').strip()))
                            poziom_display = f"PD{poziom_text.replace('D', '').strip()}"
                            
                            # Sprawdź czy poziom nie jest o 2+ za niski - wyklucz całkowicie
                            if poziom < poziom_min - POZIOM_TOLERANCJA_W_DOL:
                                continue  # Wyklucz narty o 2+ poziomy za niskie
                        except:
                            continue  # Błąd parsowania
                    elif poziom_text.strip().isdigit():
                        # Format prosty: tylko cyfra (np. "4", "6")
                        try:
                            poziom_min = int(float(poziom_text.strip()))
                            poziom_display = f"P{poziom_text.strip()}"
                        except:
                            continue  # Błąd parsowania
                    else:
                        # Nieznany format - pomiń
                        continue

                    dopasowanie = {}
                    zielone_punkty = 0
                    poziom_niżej_kandydat = False

                    # Specjalna logika dla nart unisex - sprawdź oba poziomy
                    if narta_plec == "U" and '/' in poziom_text:
                        # Dla nart unisex sprawdź oba poziomy
                        parts = poziom_text.split('/')
                        pm_part = parts[0].replace('M', '').strip()
                        pd_part = parts[1].replace('D', '').strip()
                        poziom_m = int(float(pm_part))
                        poziom_d = int(float(pd_part))
                        
                        # Sprawdź czy poziom nie jest o 2+ za niski - wyklucz całkowicie
                        if plec == "Kobieta":
                            if poziom < poziom_d - POZIOM_TOLERANCJA_W_DOL:
                                continue  # Wyklucz narty o 2+ poziomy za niskie
                        elif plec == "Mężczyzna":
                            if poziom < poziom_m - POZIOM_TOLERANCJA_W_DOL:
                                continue  # Wyklucz narty o 2+ poziomy za niskie
                        else:  # Wszyscy
                            if poziom < min(poziom_m, poziom_d) - POZIOM_TOLERANCJA_W_DOL:
                                continue  # Wyklucz narty o 2+ poziomy za niskie
                        
                        if plec == "Kobieta":
                            # Sprawdź poziom damski jako główny, męski jako alternatywa
                            if poziom == poziom_d:
                                dopasowanie['poziom'] = ('green', 'OK', f"PD{poziom_d} (PM{poziom_m})")
                                zielone_punkty += 1
                            elif poziom == poziom_d + 1:
                                dopasowanie['poziom'] = ('orange', f'Narta słabsza o jeden poziom', f"PD{poziom_d} (PM{poziom_m})")
                                poziom_niżej_kandydat = True
                            elif poziom == poziom_m:
                                # Użyj poziom męski jako alternatywa
                                if poziom == poziom_m + 1:
                                    dopasowanie['poziom'] = ('orange', f'Narta słabsza o jeden poziom', f"PM{poziom_m} (PD{poziom_d})")
                                else:
                                    dopasowanie['poziom'] = ('orange', f'O {abs(poziom - poziom_m)} za łatwa (poziom męski)', f"PM{poziom_m} (PD{poziom_d})")
                                poziom_niżej_kandydat = True
                            elif poziom > poziom_d + 1:
                                # Sprawdź czy to dokładnie o 1 poziom za niski
                                if poziom == poziom_d + 1:
                                    dopasowanie['poziom'] = ('orange', f'Narta słabsza o jeden poziom', f"PD{poziom_d} (PM{poziom_m})")
                                    poziom_niżej_kandydat = True
                                else:
                                    # Więcej niż o 1 poziom za niski - wyklucz
                                    continue
                            else:
                                continue
                        elif plec == "Mężczyzna":
                            # Sprawdź poziom męski jako główny, damski jako alternatywa
                            if poziom == poziom_m:
                                dopasowanie['poziom'] = ('green', 'OK', f"PM{poziom_m} (PD{poziom_d})")
                                zielone_punkty += 1
                            elif poziom == poziom_m + 1:
                                dopasowanie['poziom'] = ('orange', f'Narta słabsza o jeden poziom', f"PM{poziom_m} (PD{poziom_d})")
                                poziom_niżej_kandydat = True
                            elif poziom == poziom_d:
                                # Użyj poziom damski jako alternatywa
                                if poziom == poziom_d + 1:
                                    dopasowanie['poziom'] = ('orange', f'Narta słabsza o jeden poziom', f"PD{poziom_d} (PM{poziom_m})")
                                else:
                                    dopasowanie['poziom'] = ('orange', f'O {abs(poziom - poziom_d)} za łatwa (poziom damski)', f"PD{poziom_d} (PM{poziom_m})")
                                poziom_niżej_kandydat = True
                            elif poziom > poziom_m + 1:
                                # Sprawdź czy to dokładnie o 1 poziom za niski
                                if poziom == poziom_m + 1:
                                    dopasowanie['poziom'] = ('orange', f'Narta słabsza o jeden poziom', f"PM{poziom_m} (PD{poziom_d})")
                                    poziom_niżej_kandydat = True
                                else:
                                    # Więcej niż o 1 poziom za niski - wyklucz
                                    continue
                            else:
                                continue
                        else:  # Wszyscy
                            # Użyj niższego poziomu
                            poziom_min = min(poziom_m, poziom_d)
                            
                            if poziom == poziom_min:
                                dopasowanie['poziom'] = ('green', 'OK', f"PM{poziom_m}/PD{poziom_d}")
                                zielone_punkty += 1
                            elif poziom > poziom_min:
                                # Sprawdź czy to dokładnie o 1 poziom za niski
                                if poziom == poziom_min + 1:
                                    dopasowanie['poziom'] = ('orange', f'Narta słabsza o jeden poziom', f"PM{poziom_m}/PD{poziom_d}")
                                    poziom_niżej_kandydat = True
                                else:
                                    # Więcej niż o 1 poziom za niski - wyklucz
                                    continue
                            else:
                                continue
                    else:
                        # Normalna logika dla nart nie-unisex
                        if poziom == poziom_min:
                            # Klient ma dokładnie taki sam poziom jak narta - idealne dopasowanie
                            dopasowanie['poziom'] = ('green', 'OK', poziom_display)
                            zielone_punkty += 1
                        elif poziom == poziom_min + 1:
                            # Klient ma poziom o 1 wyższy niż narta - narta słabsza o jeden poziom
                            dopasowanie['poziom'] = ('orange', f'Narta słabsza o jeden poziom', poziom_display)
                            poziom_niżej_kandydat = True
                        elif poziom > poziom_min + 1:
                            # Klient ma poziom o 2+ wyższy niż narta - wyklucz całkowicie
                            continue
                        else:
                            continue
                    
                    if plec == "Wszyscy":
                        dopasowanie['plec'] = ('green', 'OK', narta_plec)
                        zielone_punkty += 1
                    elif plec == "Kobieta":
                        if narta_plec in ["K", "D", "U"]:  # Damskie i unisex - idealne
                            dopasowanie['plec'] = ('green', 'OK', narta_plec)
                            zielone_punkty += 1
                        elif narta_plec == "M":  # Męskie - pokazuj ale jako alternatywę
                            dopasowanie['plec'] = ('orange', 'Narta męska', narta_plec)
                        else:
                            dopasowanie['plec'] = ('orange', 'Nieznana płeć', narta_plec)
                    elif plec == "Mężczyzna":
                        if narta_plec in ["M", "U"]:  # Męskie i unisex - idealne
                            dopasowanie['plec'] = ('green', 'OK', narta_plec)
                            zielone_punkty += 1
                        elif narta_plec in ["K", "D"]:  # Damskie - pokazuj ale jako alternatywę
                            dopasowanie['plec'] = ('orange', 'Narta kobieca', narta_plec)
                        else:
                            dopasowanie['plec'] = ('orange', 'Nieznana płeć', narta_plec)

                    if waga_min <= waga <= waga_max:
                        dopasowanie['waga'] = ('green', 'OK', waga_min, waga_max)
                        zielone_punkty += 1
                    elif waga > waga_max and waga <= waga_max + WAGA_TOLERANCJA:
                        dopasowanie['waga'] = ('orange', f'O {waga - waga_max} kg za duża (miększa)', waga_min, waga_max)
                    elif waga < waga_min and waga >= waga_min - WAGA_TOLERANCJA:
                        dopasowanie['waga'] = ('orange', f'O {waga_min - waga} kg za mała (sztywniejsza)', waga_min, waga_max)
                    else:
                        dopasowanie['waga'] = ('red', 'Niedopasowana', waga_min, waga_max)

                    if min_wzrost_narciarza <= wzrost <= max_wzrost_narciarza:
                        dopasowanie['wzrost'] = ('green', 'OK', min_wzrost_narciarza, max_wzrost_narciarza)
                        zielone_punkty += 1
                    elif wzrost > max_wzrost_narciarza and wzrost <= max_wzrost_narciarza + WZROST_TOLERANCJA:
                        dopasowanie['wzrost'] = ('orange', f'O {wzrost - max_wzrost_narciarza} cm za duży (zwrotniejsza)', min_wzrost_narciarza, max_wzrost_narciarza)
                    elif wzrost < min_wzrost_narciarza and wzrost >= min_wzrost_narciarza - WZROST_TOLERANCJA:
                        dopasowanie['wzrost'] = ('orange', f'O {min_wzrost_narciarza - wzrost} cm za mały (stabilniejsza)', min_wzrost_narciarza, max_wzrost_narciarza)
                    else:
                        dopasowanie['wzrost'] = ('red', 'Niedopasowany', min_wzrost_narciarza, max_wzrost_narciarza)
                    
                    # Sprawdź przeznaczenie - 5. kryterium
                    if styl_jazdy and styl_jazdy != "Wszystkie":
                        przeznaczenie = row.get('PRZEZNACZENIE', '')
                        # Sprawdź czy wybrany styl jest w przeznaczeniu (elastyczne dopasowanie)
                        if przeznaczenie:
                            # Podziel przeznaczenie na części - obsługuj różne formaty (z spacją i bez)
                            przeznaczenia = [p.strip() for p in przeznaczenie.replace(',', ',').split(',')]
                            if styl_jazdy in przeznaczenia:
                                dopasowanie['przeznaczenie'] = ('green', 'OK', przeznaczenie)
                                zielone_punkty += 1
                            else:
                                dopasowanie['przeznaczenie'] = ('orange', f'Inne przeznaczenie ({przeznaczenie})', przeznaczenie)
                        else:
                            dopasowanie['przeznaczenie'] = ('orange', 'Brak przeznaczenia', '')
                    else:
                        # Gdy wybrano "Wszystkie" - przeznaczenie nie jest kryterium
                        dopasowanie['przeznaczenie'] = ('green', 'OK', row.get('PRZEZNACZENIE', ''))
                        # NIE dodajemy punktu za przeznaczenie gdy wybrano "Wszystkie"
                    
                    if any(v[0] == 'red' for v in dopasowanie.values()):
                        continue
                    
                    narta_info = {'dane': row, 'dopasowanie': dopasowanie}
                    
                    # ===== OBLICZ WSPÓŁCZYNNIK IDEALNOŚCI =====
                    wspolczynnik, detale_oceny = compatibility_scorer.oblicz_wspolczynnik_idealnosci(
                        dopasowanie, wzrost, waga, poziom, plec, styl_jazdy
                    )
                    
                    # Dodaj współczynnik do informacji o narcie
                    narta_info['wspolczynnik_idealnosci'] = wspolczynnik
                    narta_info['detale_oceny'] = detale_oceny
                    
                    logger.debug(f"Narta {row.get('MARKA')} {row.get('MODEL')} - współczynnik: {wspolczynnik}%")
                    # ===== KONIEC NOWEGO KODU =====
                    
                    # Sprawdź czy narta ma niepasującą płeć - jeśli tak, przenieś do "INNA PŁEĆ"
                    plec_status = dopasowanie.get('plec')
                    if plec_status and plec_status[1] not in ['OK']:  # Nie jest OK
                        # Sprawdź czy to rzeczywiście problem z płcią
                        if 'Narta męska' in plec_status[1] or 'Narta kobieca' in plec_status[1]:
                            # Przenieś do kategorii "Inna płeć" niezależnie od innych parametrów
                            inna_plec.append(narta_info)
                            continue  # Przenieś do kategorii "Inna płeć" i pomiń normalną kategoryzację
                    
                    # Sprawdź czy to kandydat do "poziom_niżej"
                    if poziom_niżej_kandydat:
                        # Sprawdź czy reszta parametrów jest OK (bez poziomu)
                        pozostałe_punkty = zielone_punkty  # Poziom już nie liczy się do punktów
                        max_pozostałe_punkty = (5 if (styl_jazdy and styl_jazdy != "Wszystkie") else 4) - 1
                        
                        if pozostałe_punkty == max_pozostałe_punkty:
                            poziom_niżej.append(narta_info)
                        else:
                            dobre_alternatywy.append(narta_info)
                    else:
                        # Normalna kategoryzacja
                        max_punkty = 5 if (styl_jazdy and styl_jazdy != "Wszystkie") else 4
                        if zielone_punkty == max_punkty:
                            idealne_dopasowanie.append(narta_info)
                        else:
                            dobre_alternatywy.append(narta_info)

                except (ValueError, TypeError) as e:
                    logger.warning(f"Pominięto wiersz z powodu błędu danych: {row} - {e}")
                    continue
        
        def sort_key(narta_info):
            narta_plec = narta_info['dane'].get('PLEC', 'U').upper()
            dopasowanie = narta_info['dopasowanie']
            
            # Pierwsze sortowanie: czy narta ma pasujący poziom i płeć
            ideal_match = 0
            poziom_status = dopasowanie.get('poziom')
            plec_status = dopasowanie.get('plec')
            
            if (poziom_status and poziom_status[1] == "OK" and 
                plec_status and plec_status[1] == "OK"):
                ideal_match = 0  # Idealne dopasowanie - pierwsze
            else:
                ideal_match = 1  # Nieidealne dopasowanie - drugie
            
            # Drugie sortowanie: płeć
            plec_priority = 0
            if plec == "Kobieta":
                if narta_plec in ['K', 'D']: plec_priority = 0
                elif narta_plec == 'U': plec_priority = 1
                else: plec_priority = 2
            elif plec == "Mężczyzna":
                if narta_plec == 'M': plec_priority = 0
                elif narta_plec == 'U': plec_priority = 1
                else: plec_priority = 2
            else:
                plec_priority = 0
            
            # Trzecie sortowanie: poziom
            poziom_priority = 0
            if poziom_status and poziom_status[1] == "OK":
                poziom_priority = 0  # Pasujący poziom
            else:
                poziom_priority = 1  # Niepasujący poziom
            
            # NOWE: Dodaj współczynnik jako czwarte kryterium sortowania
            wspolczynnik = narta_info.get('wspolczynnik_idealnosci', 0)
            # Minus przed współczynnikiem żeby sortować od najwyższego do najniższego
            return (ideal_match, plec_priority, poziom_priority, -wspolczynnik)

        idealne_dopasowanie.sort(key=sort_key)
        poziom_niżej.sort(key=sort_key)
        dobre_alternatywy.sort(key=sort_key)
        ponizej_poziomu.sort(key=sort_key)
        inna_plec.sort(key=sort_key)

    except FileNotFoundError:
        logger.error("Nie znaleziono pliku 'NOWABAZA_final.csv'")
        QMessageBox.critical(None, "Błąd Pliku", "Nie znaleziono pliku 'NOWABAZA_final.csv'.")
        return None, None, None
    except Exception as e:
        logger.error(f"Wystąpił nieoczekiwany błąd: {e}")
        QMessageBox.critical(None, "Błąd Krytyczny", f"Wystąpił nieoczekiwany błąd: {e}")
        return None, None, None

    logger.info(f"Znaleziono: {len(idealne_dopasowanie)} idealnych, {len(poziom_niżej)} poziom niżej, {len(dobre_alternatywy)} alternatyw, {len(ponizej_poziomu)} poniżej poziomu, {len(inna_plec)} inna płeć")
    return idealne_dopasowanie, poziom_niżej, dobre_alternatywy, ponizej_poziomu, inna_plec


# ===== DIALOG KALENDARZA =====
class DatePickerDialog(QDialog):
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
        ok_btn.setStyleSheet("""
            QPushButton {
                background-color: #4CAF50;
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }
        """)
        
        cancel_btn = QPushButton("Anuluj")
        cancel_btn.clicked.connect(self.reject)
        cancel_btn.setStyleSheet("""
            QPushButton {
                background-color: #f44336;
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }
        """)
        
        btn_layout.addWidget(ok_btn)
        btn_layout.addWidget(cancel_btn)
        layout.addLayout(btn_layout)
    
    def get_selected_date(self):
        return self.calendar.selectedDate()

# ===== GŁÓWNE OKNO APLIKACJI =====
class SkiApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("🎿 Asystent Doboru Nart v6.0 - PyQt5 Combined")
        self.setGeometry(100, 100, 1000, 700)  # Zmniejszone z 1200x800
        self.setup_ui()
        self.setup_styles()
        logger.info("Aplikacja uruchomiona")
        
    def setup_ui(self):
        """Konfiguruje interfejs użytkownika"""
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        # Główny layout
        main_layout = QVBoxLayout(central_widget)
        main_layout.setSpacing(12)  # Zmniejszone z 20
        main_layout.setContentsMargins(15, 15, 15, 15)  # Zmniejszone z 20
        
        # Nagłówek z logo, tytułem i formularzem (jak w combined)
        header_frame = self.create_header()
        main_layout.addWidget(header_frame)
        
        # Pole wyników
        results_group = self.create_results_group()
        main_layout.addWidget(results_group)
        
    def create_header(self):
        """Tworzy nagłówek z logo i tytułem jak w pliku combined"""
        # Główny kontener poziomy (jak w combined)
        top_frame = QFrame()
        top_frame.setStyleSheet(f"background-color: {ModernTheme.PRIMARY.name()}; border: 2px solid {ModernTheme.TERTIARY.name()};")
        
        header_layout = QHBoxLayout(top_frame)
        header_layout.setContentsMargins(15, 15, 15, 15)  # Zmniejszone z 20
        
        # Lewa strona - logo i tytuł jako jedność (jak w combined)
        left_side = QFrame()
        left_side.setStyleSheet(f"background-color: {ModernTheme.PRIMARY.name()};")
        left_side.setFixedWidth(350)  # Zmniejszone z 400
        
        # Kontener pionowy - logo na górze, tekst pod spodem
        unified_container = QVBoxLayout()
        unified_container.setContentsMargins(0, 0, 0, 0)
        unified_container.setAlignment(Qt.AlignCenter)
        
        # Logo na górze - większe, zajmuje 3/4 pola
        try:
            # Sprawdź ścieżkę do pliku
            current_dir = os.path.dirname(os.path.abspath(__file__))
            logo_path = os.path.join(current_dir, "narty.png")
            logger.info(f"Próbuję załadować logo z: {logo_path}")
            logger.info(f"Plik istnieje: {os.path.exists(logo_path)}")
            
            logo_pixmap = QPixmap(logo_path)
            if not logo_pixmap.isNull():
                # Skaluj logo do większego rozmiaru (3/4 z 350px = ~260px)
                scaled_logo = logo_pixmap.scaled(260, 260, Qt.KeepAspectRatio, Qt.SmoothTransformation)
                logo_label = QLabel()
                logo_label.setPixmap(scaled_logo)
                logo_label.setAlignment(Qt.AlignCenter)
                logo_label.setStyleSheet(f"background-color: {ModernTheme.PRIMARY.name()};")
                logo_label.setFixedSize(260, 260)
                unified_container.addWidget(logo_label)
            else:
                # Fallback jeśli obraz nie istnieje
                fallback_logo = QLabel("🎿")
                fallback_logo.setFont(QFont("Segoe UI", 120))  # Większa czcionka
                fallback_logo.setStyleSheet(f"color: {ModernTheme.ACCENT.name()}; background-color: {ModernTheme.PRIMARY.name()};")
                fallback_logo.setFixedSize(260, 260)
                fallback_logo.setAlignment(Qt.AlignCenter)
                unified_container.addWidget(fallback_logo)
        except Exception as e:
            logger.warning(f"Nie można załadować logo: {e}")
            # Fallback jeśli wystąpi błąd
            fallback_logo = QLabel("🎿")
            fallback_logo.setFont(QFont("Segoe UI", 120))  # Większa czcionka
            fallback_logo.setStyleSheet(f"color: {ModernTheme.ACCENT.name()}; background-color: {ModernTheme.PRIMARY.name()};")
            fallback_logo.setFixedSize(260, 260)
            fallback_logo.setAlignment(Qt.AlignCenter)
            unified_container.addWidget(fallback_logo)
        
        # Tekst pod logo - w jednym wierszu, mniejsza czcionka
        title_text = QLabel("System doboru nart")
        title_text.setFont(QFont("Segoe UI", 16, QFont.Bold))  # Zmniejszona czcionka
        title_text.setStyleSheet(f"color: {ModernTheme.ACCENT.name()}; background-color: {ModernTheme.PRIMARY.name()};")
        title_text.setAlignment(Qt.AlignCenter)
        unified_container.addWidget(title_text)
        
        left_side.setLayout(unified_container)
        header_layout.addWidget(left_side)
        
        # Prawa strona - formularz danych klienta (jak w combined)
        right_side = QFrame()
        right_side.setStyleSheet(f"background-color: {ModernTheme.SECONDARY.name()}; border: 2px solid {ModernTheme.TERTIARY.name()}; border-radius: 10px;")
        
        right_layout = QVBoxLayout(right_side)
        right_layout.setContentsMargins(12, 12, 12, 12)  # Zmniejszone z 15
        
        # Nagłówek "Dane Klienta" nad formularzem
        header_label = QLabel("📝 Dane Klienta")
        header_label.setFont(QFont("Segoe UI", 14, QFont.Bold))
        header_label.setStyleSheet(f"color: {ModernTheme.TEXT_PRIMARY.name()}; background-color: {ModernTheme.SECONDARY.name()};")
        right_layout.addWidget(header_label)
        
        # Formularz w 4 rzędach (jak w combined)
        form_layout = QVBoxLayout()
        form_layout.setSpacing(8)  # Zmniejszone odstępy między rzędami
        
        # RZĄD 1: Daty rezerwacji - 3 okienka koło siebie
        row1_layout = QVBoxLayout()
        
        # Data od
        od_layout = QHBoxLayout()
        od_layout.addWidget(QLabel("📅 Data od:"))
        
        # Dzień
        self.od_dzien = QLineEdit()
        self.od_dzien.setPlaceholderText("DD")
        self.od_dzien.setMaxLength(2)
        self.od_dzien.setFixedWidth(45)  # Zwiększone z 35 na 45
        od_layout.addWidget(self.od_dzien)
        
        # Miesiąc
        self.od_miesiac = QLineEdit()
        self.od_miesiac.setPlaceholderText("MM")
        self.od_miesiac.setMaxLength(2)
        self.od_miesiac.setFixedWidth(45)  # Zwiększone z 35 na 45
        od_layout.addWidget(self.od_miesiac)
        
        # Rok
        self.od_rok = QLineEdit()
        self.od_rok.setPlaceholderText("RR")
        self.od_rok.setMaxLength(4)
        self.od_rok.setFixedWidth(60)  # Zwiększone z 50 na 60
        od_layout.addWidget(self.od_rok)
        
        # Przycisk kalendarza
        self.cal_od_btn = QPushButton("📅")
        self.cal_od_btn.setFixedSize(25, 25)
        self.cal_od_btn.setToolTip("Otwórz kalendarz")
        self.cal_od_btn.clicked.connect(lambda: self.open_calendar("od"))
        
        self.cal_od_btn.setStyleSheet("""
            QPushButton {
                background-color: #2196F3;
                color: white;
                border: none;
                border-radius: 4px;
                font-weight: bold;
                font-size: 10px;
            }
            QPushButton:hover {
                background-color: #1976D2;
            }
        """)
        od_layout.addWidget(self.cal_od_btn)
        od_layout.addStretch()
        
        # Data do
        do_layout = QHBoxLayout()
        do_layout.addWidget(QLabel("📅 Data do:"))
        
        # Dzień
        self.do_dzien = QLineEdit()
        self.do_dzien.setPlaceholderText("DD")
        self.do_dzien.setMaxLength(2)
        self.do_dzien.setFixedWidth(45)  # Zwiększone z 35 na 45
        do_layout.addWidget(self.do_dzien)
        
        self.do_miesiac = QLineEdit()
        self.do_miesiac.setPlaceholderText("MM")
        self.do_miesiac.setMaxLength(2)
        self.do_miesiac.setFixedWidth(45)  # Zwiększone z 35 na 45
        do_layout.addWidget(self.do_miesiac)
        
        # Rok
        self.do_rok = QLineEdit()
        self.do_rok.setPlaceholderText("RR")
        self.do_rok.setMaxLength(4)
        self.do_rok.setFixedWidth(60)  # Zwiększone z 50 na 60
        do_layout.addWidget(self.do_rok)
        
        # Przycisk kalendarza
        self.cal_do_btn = QPushButton("📅")
        self.cal_do_btn.setFixedSize(25, 25)
        self.cal_do_btn.setToolTip("Otwórz kalendarz")
        self.cal_do_btn.clicked.connect(lambda: self.open_calendar("do"))
        self.cal_do_btn.setStyleSheet("""
            QPushButton {
                background-color: #2196F3;
                color: white;
                border: none;
                border-radius: 4px;
                font-weight: bold;
                font-size: 10px;
            }
            QPushButton:hover {
                background-color: #1976D2;
            }
        """)
        do_layout.addWidget(self.cal_do_btn)
        do_layout.addStretch()
        
        row1_layout.addLayout(od_layout)
        row1_layout.addLayout(do_layout)
        form_layout.addLayout(row1_layout)
        
        # Ustaw walidatory
        self.setup_date_validators()
        
        # RZĄD 2: Wzrost i Waga
        row2_layout = QHBoxLayout()
        row2_layout.addWidget(QLabel("📏 Wzrost (cm):"))
        self.wzrost_entry = QLineEdit()
        self.wzrost_entry.setFixedWidth(80)  # Zmniejszone z 100
        row2_layout.addWidget(self.wzrost_entry)
        row2_layout.addWidget(QLabel("⚖️ Waga (kg):"))
        self.waga_entry = QLineEdit()
        self.waga_entry.setFixedWidth(80)  # Zmniejszone z 100
        row2_layout.addWidget(self.waga_entry)
        row2_layout.addStretch()
        form_layout.addLayout(row2_layout)
        
        # RZĄD 3: Poziom i Płeć
        row3_layout = QHBoxLayout()
        row3_layout.addWidget(QLabel("🎯 Poziom:"))
        self.poziom_combo = QComboBox()
        poziomy = ["1 - Świeżak", "2 - Początkujący Turysta", "3 - Niedzielny Śmigacz", 
                  "4 - Zajakowicz", "5 - Zawodnik", "6 - Lokalna Legenda"]
        self.poziom_combo.addItems(poziomy)
        self.poziom_combo.setFixedWidth(150)  # Zmniejszone z 180
        row3_layout.addWidget(self.poziom_combo)
        row3_layout.addWidget(QLabel("👤 Płeć:"))
        
        # Radio buttony dla płci - utwórz grupę
        plec_group_widget = QGroupBox()
        plec_group_widget.setStyleSheet("QGroupBox { border: none; }")
        plec_layout = QHBoxLayout(plec_group_widget)
        self.plec_group = QRadioButton("👩")
        self.plec_group2 = QRadioButton("👨")
        self.plec_group3 = QRadioButton("👥")
        self.plec_group3.setChecked(True)
        plec_layout.addWidget(self.plec_group)
        plec_layout.addWidget(self.plec_group2)
        plec_layout.addWidget(self.plec_group3)
        row3_layout.addWidget(plec_group_widget)
        row3_layout.addStretch()
        form_layout.addLayout(row3_layout)
        
        # RZĄD 4: Przeznaczenie - podzielony na dwie linie
        row4_layout = QVBoxLayout()
        row4_layout.addWidget(QLabel("🎿 Przeznaczenie:"))
        
        # Utwórz grupę dla przeznaczenia
        styl_group_widget = QGroupBox()
        styl_group_widget.setStyleSheet("QGroupBox { border: none; }")
        styl_container_layout = QVBoxLayout(styl_group_widget)
        
        # Pierwsza linia stylów - rzeczywiste wartości z bazy danych
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
        
        # Przyciski - kompaktowe w formularzu
        button_layout = QHBoxLayout()
        button_layout.setSpacing(8)  # Zmniejszone odstępy między przyciskami
        self.znajdz_button = QPushButton("🔍 Znajdź")
        self.znajdz_button.setStyleSheet(f"""
            QPushButton {{
                background-color: {ModernTheme.SUCCESS.name()};
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }}
            QPushButton:hover {{
                background-color: #047857;
            }}
        """)
        self.znajdz_button.clicked.connect(self.znajdz_i_wyswietl)
        
        self.wyczysc_button = QPushButton("🗑️ Wyczyść")
        self.wyczysc_button.setStyleSheet(f"""
            QPushButton {{
                background-color: {ModernTheme.WARNING.name()};
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }}
            QPushButton:hover {{
                background-color: #B45309;
            }}
        """)
        self.wyczysc_button.clicked.connect(self.wyczysc_formularz)
        
        self.przegladaj_button = QPushButton("📋 Przeglądaj")
        self.przegladaj_button.setStyleSheet(f"""
            QPushButton {{
                background-color: {ModernTheme.ACCENT.name()};
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }}
            QPushButton:hover {{
                background-color: {ModernTheme.ACCENT_HOVER.name()};
            }}
        """)
        self.przegladaj_button.clicked.connect(self.pokaz_wszystkie_narty)
        
        self.odswiez_rezerwacje_button = QPushButton("🔄 Odśwież rezerwacje")
        self.odswiez_rezerwacje_button.setStyleSheet(f"""
            QPushButton {{
                background-color: {ModernTheme.INFO.name()};
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }}
            QPushButton:hover {{
                background-color: #B91C1C;
            }}
        """)
        self.odswiez_rezerwacje_button.clicked.connect(self.odswiez_rezerwacje)
        
        button_layout.addWidget(self.znajdz_button)
        button_layout.addWidget(self.wyczysc_button)
        button_layout.addWidget(self.przegladaj_button)
        button_layout.addWidget(self.odswiez_rezerwacje_button)
        button_layout.addStretch()
        
        form_layout.addLayout(button_layout)
        right_layout.addLayout(form_layout)
        
        header_layout.addWidget(right_side)
        
        # Ustaw obsługę automatycznego przechodzenia między polami (po utworzeniu wszystkich pól)
        self.setup_date_handlers()
        
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
        layout.setContentsMargins(15, 20, 15, 15)  # Zwiększone marginesy
        
        # Pole tekstowe na wyniki
        self.wyniki_text = QTextEdit()
        self.wyniki_text.setReadOnly(True)
        self.wyniki_text.setMinimumHeight(500)  # Zwiększona wysokość
        self.wyniki_text.setStyleSheet(f"""
            QTextEdit {{
                background-color: {ModernTheme.PRIMARY.name()};
                border: 2px solid {ModernTheme.TERTIARY.name()};
                border-radius: 8px;
                padding: 10px;  /* Zmniejszone z 12px */
                font-family: 'Segoe UI';
                font-size: 13px;  /* Zwiększona czcionka */
                line-height: 1.3;  /* Mniejszy odstęp między liniami */
                font-weight: 500;  /* Lekko pogrubiona czcionka */
            }}
        """)
        
        layout.addWidget(self.wyniki_text)
        
        return group
        
    def setup_styles(self):
        """Konfiguruje style aplikacji"""
        self.setStyleSheet(f"""
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
        """)
    
    def setup_date_validators(self):
        """Ustawia walidatory dla pól dat"""
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
        
        # Wzrost i waga - automatyczne przechodzenie
        self.wzrost_entry.textChanged.connect(lambda: self.auto_next_field(self.wzrost_entry, self.waga_entry))
    
    def auto_complete_year_safe(self, year_field):
        """Bezpieczne uzupełnianie roku i przechodzenie do następnego pola"""
        text = year_field.text()
        
        # Jeśli wpisano 2 cyfry, uzupełnij do pełnego roku
        if len(text) == 2 and text.isdigit():
            year = int(text)
            if year >= 0 and year <= 99:
                # Jeśli rok jest mniejszy niż 50, zakładamy że to 20xx, w przeciwnym razie 19xx
                if year < 50:
                    full_year = 2000 + year
                else:
                    full_year = 1900 + year
                
                year_field.setText(str(full_year))
                
                # Przejdź do następnego pola
                if year_field == self.od_rok:
                    self.do_dzien.setFocus()
                    self.do_dzien.selectAll()
                elif year_field == self.do_rok:
                    self.wzrost_entry.setFocus()
                    self.wzrost_entry.selectAll()
    
    def auto_next_field(self, current_field, next_field):
        """Automatyczne przechodzenie do następnego pola"""
        text = current_field.text()
        
        # Jeśli to pole roku - sprawdź czy ma 4 cyfry (pełny rok)
        if current_field in [self.od_rok, self.do_rok]:
            if len(text) == 4 and text.isdigit():
                next_field.setFocus()
                next_field.selectAll()
        # Jeśli to pole wzrostu - sprawdź czy ma 3 cyfry
        elif current_field == self.wzrost_entry:
            if len(text) == 3 and text.isdigit():
                next_field.setFocus()
                next_field.selectAll()
        # Jeśli to pole wagi - sprawdź czy ma 2-3 cyfry (20-200 kg)
        elif current_field == self.waga_entry:
            if len(text) >= 2 and text.isdigit():
                # Sprawdź czy to rozsądna waga (20-200 kg)
                try:
                    waga = int(text)
                    if 20 <= waga <= 200:
                        # Przejdź do poziomu (combo box)
                        self.poziom_combo.setFocus()
                except ValueError:
                    pass
        # Jeśli to inne pole - sprawdź czy ma 2 cyfry
        else:
            if len(text) == 2 and text.isdigit():
                next_field.setFocus()
                next_field.selectAll()
    
    
    def open_calendar(self, target):
        """Otwiera kalendarz dla wybranego pola"""
        dialog = DatePickerDialog(self)
        if dialog.exec_() == QDialog.Accepted:
            selected_date = dialog.get_selected_date()
            
            # Konwertuj na format DD/MM/RRRR
            day = selected_date.toString("dd")
            month = selected_date.toString("MM")
            year = selected_date.toString("yyyy")
            year_suffix = year[2:]  # Ostatnie 2 cyfry roku
            
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
        
        # Sprawdź czy pola nie są puste
        wzrost_text = self.wzrost_entry.text().strip()
        waga_text = self.waga_entry.text().strip()
        
        if not wzrost_text or not waga_text:
            QMessageBox.critical(self, "Błąd Danych", "Wypełnij pola Wzrost i Waga!")
            return
            
        # Sprawdź czy wzrost i waga to liczby
        try:
            wzrost_klienta = int(wzrost_text)
        except ValueError:
            QMessageBox.critical(self, "Błąd Danych", f"Wzrost musi być liczbą! Wpisałeś: '{wzrost_text}'")
            return
            
        try:
            waga_klienta = int(waga_text)
        except ValueError:
            QMessageBox.critical(self, "Błąd Danych", f"Waga musi być liczbą! Wpisałeś: '{waga_text}'")
            return
        
        # Sprawdź czy wartości są rozsądne
        if wzrost_klienta < 100 or wzrost_klienta > 250:
            QMessageBox.critical(self, "Błąd Danych", "Wzrost musi być między 100 a 250 cm!")
            return
            
        if waga_klienta < 20 or waga_klienta > 200:
            QMessageBox.critical(self, "Błąd Danych", "Waga musi być między 20 a 200 kg!")
            return
        
        poziom_text = self.poziom_combo.currentText()
        if not poziom_text:
            QMessageBox.critical(self, "Błąd Danych", "Wybierz poziom umiejętności.")
            return
            
        try:
            # Wyciągnij numer poziomu z tekstu (np. "1 - Świeżak" -> 1)
            poziom_klienta = int(poziom_text.split(' ')[0])
        except (ValueError, IndexError):
            QMessageBox.critical(self, "Błąd Danych", f"Błąd parsowania poziomu: '{poziom_text}'. Wybierz poziom z listy.")
            return

        # Pobierz płeć
        if self.plec_group.isChecked():
            plec_klienta = "Kobieta"
        elif self.plec_group2.isChecked():
            plec_klienta = "Mężczyzna"
        else:
            plec_klienta = "Wszyscy"
        
        # Pobierz daty rezerwacji z nowych pól
        od_dzien = self.od_dzien.text().strip()
        od_miesiac = self.od_miesiac.text().strip()
        od_rok = self.od_rok.text().strip()
        
        do_dzien = self.do_dzien.text().strip()
        do_miesiac = self.do_miesiac.text().strip()
        do_rok = self.do_rok.text().strip()
        
        # Sprawdź czy wszystkie pola dat są wypełnione
        if not all([od_dzien, od_miesiac, od_rok, do_dzien, do_miesiac, do_rok]):
            QMessageBox.warning(self, "Uwaga", "Wypełnij wszystkie pola dat rezerwacji!")
            return
            
        try:
            # Konwertuj na pełne daty - sprawdź czy rok ma już 4 cyfry
            if len(od_rok) == 4:
                od_full_year = od_rok
            else:
                od_full_year = f"20{od_rok}"
                
            if len(do_rok) == 4:
                do_full_year = do_rok
            else:
                do_full_year = f"20{do_rok}"
            
            # Stwórz daty w formacie YYYY-MM-DD dla parsowania
            data_od = pd.to_datetime(f"{od_full_year}-{od_miesiac}-{od_dzien}").date()
            data_do = pd.to_datetime(f"{do_full_year}-{do_miesiac}-{do_dzien}").date()
            
        except Exception as e:
            QMessageBox.critical(self, "Błąd Danych", f"Nieprawidłowa data: {e}\n\nSprawdź czy data istnieje (np. 31 lutego jest nieprawidłowe)")
            return
            
        if data_od > data_do:
            QMessageBox.critical(self, "Błąd Danych", "Data rozpoczęcia musi być wcześniejsza niż data zakończenia!")
            return
        
        # Pobierz styl jazdy - mapowanie na rzeczywiste skróty z bazy danych
        styl = "Wszystkie"
        if self.styl_group2.isChecked(): styl = "SL"      # Slalom
        elif self.styl_group3.isChecked(): styl = "G"     # Gigant
        elif self.styl_group4.isChecked(): styl = "SLG"   # Performance
        elif self.styl_group5.isChecked(): styl = "C"     # Cały dzień
        elif self.styl_group6.isChecked(): styl = "OFF"   # Poza trasę
        
        logger.info(f"Wywołuję dobierz_narty z parametrami: wzrost={wzrost_klienta}, waga={waga_klienta}, poziom={poziom_klienta}, plec={plec_klienta}, styl={styl}")
        
        idealne, poziom_niżej, alternatywy, ponizej, inna_plec = dobierz_narty(wzrost_klienta, waga_klienta, poziom_klienta, plec_klienta, styl)
        
        logger.info(f"Wyniki dobierz_narty: idealne={len(idealne) if idealne else 'None'}, poziom_niżej={len(poziom_niżej) if poziom_niżej else 'None'}, alternatywy={len(alternatywy) if alternatywy else 'None'}, ponizej={len(ponizej) if ponizej else 'None'}, inna_plec={len(inna_plec) if inna_plec else 'None'}")
        
        # Wyczyść pole tekstowe
        self.wyniki_text.clear()
        
        if idealne is None:
            logger.error("dobierz_narty zwróciło None - błąd w funkcji")
            QMessageBox.critical(self, "Błąd", "Wystąpił błąd podczas dobierania nart. Sprawdź logi.")
            return

        # Wyświetl wyniki w polu tekstowym
        if idealne:
            self.wyniki_text.append("✅ IDEALNE DOPASOWANIA:")
            self.wyniki_text.append("=" * 50)
            for narta_info in idealne:
                self.wyswietl_jedna_narte(narta_info, wzrost_klienta, waga_klienta, poziom_klienta, plec_klienta, data_od, data_do)
            self.wyniki_text.append("")
        
        if poziom_niżej:
            self.wyniki_text.append("🟡 POZIOM NIŻEJ (narty z niższym poziomem wymagania, reszta OK):")
            self.wyniki_text.append("=" * 50)
            for narta_info in poziom_niżej:
                self.wyswietl_jedna_narte(narta_info, wzrost_klienta, waga_klienta, poziom_klienta, plec_klienta, data_od, data_do)
            self.wyniki_text.append("")
        
        if alternatywy:
            self.wyniki_text.append("⚠️ ALTERNATYWY:")
            self.wyniki_text.append("=" * 50)
            for narta_info in alternatywy:
                self.wyswietl_jedna_narte(narta_info, wzrost_klienta, waga_klienta, poziom_klienta, plec_klienta, data_od, data_do)
            self.wyniki_text.append("")
        
        if ponizej:
            self.wyniki_text.append("🔻 PONIŻEJ POZIOMU (2+ poziomy za niskie):")
            self.wyniki_text.append("=" * 50)
            for narta_info in ponizej:
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
        """Wyświetla informacje o jednej narcie w kompaktowej formie"""
        narta = narta_info['dane']
        dopasowanie = narta_info['dopasowanie']
        
        # ===== WYŚWIETL WSPÓŁCZYNNIK IDEALNOŚCI =====
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
        # ===== KONIEC NOWEGO KODU =====
        
        # 1. Nazwa narty i długość z współczynnikiem
        self.wyniki_text.append(f"► {narta['MARKA']} {narta['MODEL']} ({narta['DLUGOSC']} cm) {wspolczynnik_emoji} {wspolczynnik}%")
        
        # 2. Sprawdź rezerwacje dla tej narty
        ilosc_sztuk = int(narta.get('ILOSC', '1') or '1')
        dostepnosc_text = "   📦 Dostępność: "
        
        # Sprawdź każdą sztukę narty
        for i in range(ilosc_sztuk):
            # Sprawdź czy konkretna sztuka jest zarezerwowana
            jest_zarezerwowana, okres_rezerwacji, numer_narty = sprawdz_czy_narta_zarezerwowana(
                narta['MARKA'], narta['MODEL'], narta['DLUGOSC'], data_od, data_do
            )
            
            # Sprawdź czy to konkretna sztuka (jeśli mamy numer narty)
            if jest_zarezerwowana and numer_narty:
                # Sprawdź czy to ta sama sztuka (porównaj numery)
                if f"//{i+1:02d}" in numer_narty or f"//{i+1}" in numer_narty:
                    # To konkretna sztuka - czerwony kwadracik
                    dostepnosc_text += f"🔴{i+1} "
                else:
                    # Inna sztuka - zielony kwadracik
                    dostepnosc_text += f"🟩{i+1} "
            elif jest_zarezerwowana and not numer_narty:
                # Zarezerwowana ale bez numeru - wszystkie sztuki czerwone
                dostepnosc_text += f"🔴{i+1} "
            else:
                # Narta dostępna - zielony kwadracik
                dostepnosc_text += f"🟩{i+1} "
        
        self.wyniki_text.append(dostepnosc_text)
        
        # 3. Informacje o rezerwacjach (jeśli są)
        if jest_zarezerwowana and okres_rezerwacji:
            rezerwacja_text = f"   🚫 Zarezerwowana: {okres_rezerwacji}"
            if numer_narty:
                rezerwacja_text += f" (Nr: {numer_narty})"
            self.wyniki_text.append(rezerwacja_text)
        
        # 4. Dopasowanie (w jednej linii) z kolorowym podświetlaniem
        poziom_status = dopasowanie.get('poziom')
        plec_status = dopasowanie.get('plec')
        waga_status = dopasowanie.get('waga')
        wzrost_status = dopasowanie.get('wzrost')
        przeznaczenie_status = dopasowanie.get('przeznaczenie')
        
        # Tworzenie tekstu z kolorowym podświetlaniem
        dopasowanie_text = "   📊 Dopasowanie: "
        
        # Poziom - zielony jeśli OK, żółty jeśli nie do końca
        poziom_color = "🟢" if poziom_status[1] == "OK" else "🟡"
        dopasowanie_text += f"{poziom_color} P:{p}({poziom_status[2]})→{poziom_status[1]} | "
        
        # Płeć - zielony jeśli OK, żółty jeśli nie do końca
        plec_color = "🟢" if plec_status[1] == "OK" else "🟡"
        # Wyświetl płeć klienta i narty
        plec_klienta_display = "D" if plec_klienta == "Wszyscy" else plec_klienta[0]
        plec_narty_display = plec_status[2]  # Płeć narty z dopasowania
        dopasowanie_text += f"{plec_color} Pł:{plec_klienta_display}({plec_narty_display})→{plec_status[1]} | "
        
        # Waga - zielony jeśli OK, żółty jeśli nie do końca
        waga_color = "🟢" if waga_status[1] == "OK" else "🟡"
        dopasowanie_text += f"{waga_color} W:{s}kg({waga_status[2]}-{waga_status[3]})→{waga_status[1]} | "
        
        # Wzrost - zielony jeśli OK, żółty jeśli nie do końca
        wzrost_color = "🟢" if wzrost_status[1] == "OK" else "🟡"
        dopasowanie_text += f"{wzrost_color} Wz:{w}cm({wzrost_status[2]}-{wzrost_status[3]})→{wzrost_status[1]} | "
        
        # Przeznaczenie - zielony jeśli OK, żółty jeśli nie do końca
        przeznaczenie_color = "🟢" if przeznaczenie_status[1] == "OK" else "🟡"
        dopasowanie_text += f"{przeznaczenie_color} Pr:{przeznaczenie_status[2]}→{przeznaczenie_status[1]}"
        
        self.wyniki_text.append(dopasowanie_text)

        # 5. Informacje i uwagi (w dwóch liniach)
        promien = narta.get('PROMIEN', 'Brak')  # Bez polskich znaków
        pod_butem = narta.get('POD_BUTEM', 'Brak')
        uwagi = narta.get('UWAGI', 'Brak')
        
        # Wyczyść promień - tylko zamień przecinek na kropkę, zachowaj format
        if promien and promien != 'Brak':
            # Zamień przecinek na kropkę dla lepszej czytelności, zachowaj resztę
            promien_clean = str(promien).replace(',', '.')
        else:
            promien_clean = 'Brak'
        
        # Pierwsza linia - podstawowe informacje
        info_text = f"   ℹ️ Promień: {promien_clean} | Pod butem: {pod_butem}mm"
        self.wyniki_text.append(info_text)
        
        # Druga linia - uwagi (jeśli są)
        if uwagi and uwagi != 'Brak':
            uwagi_text = f"   📝 Uwagi: {uwagi}"
            self.wyniki_text.append(uwagi_text)
        
        # Kreska oddzielająca pozycje
        self.wyniki_text.append("   " + "─" * 80)
    
    def wyczysc_formularz(self):
        """Czyści formularz"""
        self.wzrost_entry.clear()
        self.waga_entry.clear()
        self.poziom_combo.setCurrentIndex(0)
        self.plec_group3.setChecked(True)
        self.styl_group.setChecked(True)
        
        # Wyczyść nowe pola dat i ustaw domyślne wartości
        now = datetime.now()
        future = now + timedelta(days=7)
        
        # Data od (dzisiaj)
        self.od_dzien.setText(now.strftime("%d"))
        self.od_miesiac.setText(now.strftime("%m"))
        self.od_rok.setText(now.strftime("%y"))
        
        # Data do (za tydzień)
        self.do_dzien.setText(future.strftime("%d"))
        self.do_miesiac.setText(future.strftime("%m"))
        self.do_rok.setText(future.strftime("%y"))
        
        # Wyczyść pole tekstowe wyników
        self.wyniki_text.clear()
        logger.info("Formularz wyczyszczony")
    
    def odswiez_rezerwacje(self):
        """Odświeża rezerwacje z pliku FireSnow - NAPRAWIONA WERSJA"""
        logger.info("Odświeżanie rezerwacji z FireSnow...")
        
        try:
            # Wyczyść pole wyników
            self.wyniki_text.clear()
            
            # Sprawdź czy plik rez.csv istnieje (w katalogu programu)
            current_dir = os.path.dirname(os.path.abspath(__file__))
            rez_file = os.path.join(current_dir, 'rez.csv')
            
            if not os.path.exists(rez_file):
                self.wyniki_text.append("❌ BŁĄD: Plik rez.csv nie istnieje!")
                self.wyniki_text.append(f"Szukam w: {current_dir}")
                self.wyniki_text.append("Sprawdź czy plik rez.csv jest w tym samym katalogu co program.")
                return
            
            # Wczytaj dane bezpośrednio z rez.csv
            self.wyniki_text.append("🔄 REZERWACJE Z FIRESNOW")
            self.wyniki_text.append("=" * 50)
            
            # Wczytaj plik CSV - spróbuj różne formaty
            try:
                df = pd.read_csv(rez_file, encoding='utf-8-sig', header=1)
                logger.info(f"Wczytano {len(df)} wierszy z rez.csv (header=1)")
            except Exception as e:
                logger.warning(f"Błąd z header=1, próbuję header=0: {e}")
                df = pd.read_csv(rez_file, encoding='utf-8-sig', header=0)
                logger.info(f"Wczytano {len(df)} wierszy z rez.csv (header=0)")
            
            # Sprawdź czy kolumny istnieją
            if 'Od' in df.columns and 'Do' in df.columns and 'Sprzęt' in df.columns:
                # Nowy format z polskimi nazwami kolumn
                df_rezerwacje = df.dropna(subset=['Od', 'Do']).copy()
                logger.info(f"Znaleziono {len(df_rezerwacje)} wierszy z datami")
                df_narty = df_rezerwacje[df_rezerwacje['Sprzęt'].str.contains('NARTY', na=False)].copy()
            else:
                logger.warning(f"Nieznany format kolumn: {list(df.columns)}")
                self.wyniki_text.append(f"❌ BŁĄD: Nieznany format kolumn w pliku rez.csv")
                self.wyniki_text.append(f"Dostępne kolumny: {', '.join(df.columns)}")
                return
            logger.info(f"Znaleziono {len(df_narty)} rezerwacji nart")
            
            if len(df_narty) == 0:
                self.wyniki_text.append("ℹ️ Brak rezerwacji nart w pliku")
                return
            
            # Wyświetl rezerwacje
            self.wyniki_text.append(f"📊 Znaleziono {len(df_narty)} rezerwacji nart")
            self.wyniki_text.append("")
            
            for i, (_, rez) in enumerate(df_narty.iterrows(), 1):
                # Wyciągnij informacje o narcie z opisu sprzętu
                sprzet = rez.get('Sprzęt', '')
                if 'NARTY' in sprzet:
                    # Przykład: "NARTY KNEISSL MY STAR XC 144cm /2024 //01"
                    parts = sprzet.split()
                    if len(parts) >= 4:
                        marka = parts[1] if len(parts) > 1 else "Nieznana"
                        # Znajdź długość
                        dlugosc = "Nieznana"
                        for part in parts:
                            if 'cm' in part:
                                dlugosc = part.replace('cm', '').strip()
                                break
                        # Znajdź numer narty
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
                
                # Konwertuj daty
                try:
                    data_od = pd.to_datetime(rez['Od']).strftime('%Y-%m-%d')
                    data_do = pd.to_datetime(rez['Do']).strftime('%Y-%m-%d')
                except:
                    data_od = "Brak daty"
                    data_do = "Brak daty"
                
                klient = rez.get('Klient', 'Nieznany')
                
                # Wyświetl rezerwację
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
    
    def pokaz_wszystkie_narty(self):
        """Pokazuje okno przeglądania wszystkich nart z tabelą"""
        logger.info("Otwieranie okna przeglądania nart")
        
        # Utwórz nowe okno
        self.narty_window = QMainWindow()
        self.narty_window.setWindowTitle("🎿 Zaawansowany Przegląd Nart")
        self.narty_window.setGeometry(200, 200, 1400, 800)
        
        # Główny widget
        central_widget = QWidget()
        self.narty_window.setCentralWidget(central_widget)
        
        # Layout główny
        main_layout = QVBoxLayout(central_widget)
        
        # Nagłówek
        header_layout = QHBoxLayout()
        title_label = QLabel("🎿 Zaawansowany Przegląd Nart")
        title_label.setFont(QFont("Segoe UI", 20, QFont.Bold))
        title_label.setStyleSheet(f"color: {ModernTheme.TEXT_PRIMARY.name()};")
        header_layout.addWidget(title_label)
        
        self.count_label = QLabel("")
        self.count_label.setFont(QFont("Segoe UI", 12))
        self.count_label.setStyleSheet(f"color: {ModernTheme.TEXT_SECONDARY.name()};")
        header_layout.addStretch()
        header_layout.addWidget(self.count_label)
        
        main_layout.addLayout(header_layout)
        
        # Panel filtrów
        filter_group = QGroupBox("🔍 Filtry i Wyszukiwanie")
        filter_layout = QVBoxLayout(filter_group)
        
        # Wyszukiwanie
        search_layout = QHBoxLayout()
        search_layout.addWidget(QLabel("🔍 Szukaj:"))
        self.search_entry = QLineEdit()
        self.search_entry.setPlaceholderText("Wpisz markę lub model...")
        self.search_entry.textChanged.connect(self.apply_filters)
        search_layout.addWidget(self.search_entry)
        search_layout.addStretch()
        
        # Filtry
        filters_layout = QHBoxLayout()
        filters_layout.addWidget(QLabel("Marka:"))
        self.marka_combo = QComboBox()
        self.marka_combo.currentTextChanged.connect(self.apply_filters)
        filters_layout.addWidget(self.marka_combo)
        
        filters_layout.addWidget(QLabel("Poziom:"))
        self.poziom_combo = QComboBox()
        self.poziom_combo.currentTextChanged.connect(self.apply_filters)
        filters_layout.addWidget(self.poziom_combo)
        
        filters_layout.addWidget(QLabel("Płeć:"))
        self.plec_combo = QComboBox()
        self.plec_combo.currentTextChanged.connect(self.apply_filters)
        filters_layout.addWidget(self.plec_combo)
        
        filter_button = QPushButton("🔄 Filtruj")
        filter_button.clicked.connect(self.apply_filters)
        filters_layout.addWidget(filter_button)
        
        clear_button = QPushButton("🗑️ Wyczyść")
        clear_button.clicked.connect(self.clear_filters)
        filters_layout.addWidget(clear_button)
        
        # Przyciski zarządzania danymi
        manage_button = QPushButton("💾 Zapisz zmiany")
        manage_button.clicked.connect(self.save_changes)
        manage_button.setStyleSheet("""
            QPushButton {
                background-color: #10B981;
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #047857;
            }
        """)
        filters_layout.addWidget(manage_button)
        
        add_button = QPushButton("➕ Dodaj nartę")
        add_button.clicked.connect(self.add_new_ski)
        add_button.setStyleSheet("""
            QPushButton {
                background-color: #DC2626;
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #B91C1C;
            }
        """)
        filters_layout.addWidget(add_button)
        
        delete_button = QPushButton("🗑️ Usuń wybrane")
        delete_button.clicked.connect(self.delete_selected)
        delete_button.setStyleSheet("""
            QPushButton {
                background-color: #EF4444;
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #DC2626;
            }
        """)
        filters_layout.addWidget(delete_button)
        
        filter_layout.addLayout(search_layout)
        filter_layout.addLayout(filters_layout)
        main_layout.addWidget(filter_group)
        
        # Tabela nart
        self.table = QTableWidget()
        self.table.setAlternatingRowColors(True)
        self.table.setSelectionBehavior(QTableWidget.SelectRows)
        self.table.setSortingEnabled(True)
        self.table.setEditTriggers(QTableWidget.DoubleClicked | QTableWidget.EditKeyPressed)  # Włącz edycję
        self.table.setWordWrap(True)  # Włącz zawijanie tekstu
        self.table.verticalHeader().setDefaultSectionSize(60)  # Zwiększ wysokość wierszy
        
        # Kolumny tabeli
        columns = ["ID", "Marka", "Model", "Długość", "Szt.", "Poziom", "Płeć", "Waga Min", "Waga Max", 
                  "Wzrost Min", "Wzrost Max", "Przeznaczenie", "Rok", "Uwagi"]
        self.table.setColumnCount(len(columns))
        self.table.setHorizontalHeaderLabels(columns)
        
        # Ustaw szerokości kolumn
        column_widths = [40, 80, 180, 60, 50, 80, 70, 70, 70, 75, 75, 100, 60, 800]
        for i, width in enumerate(column_widths):
            self.table.setColumnWidth(i, width)
        
        main_layout.addWidget(self.table)
        
        # Załaduj dane
        self.load_data()
        
        # Pokaż okno
        self.narty_window.show()
    
    def load_data(self):
        """Ładuje dane z CSV do tabeli"""
        try:
            # Sprawdź w katalogu programu
            current_dir = os.path.dirname(os.path.abspath(__file__))
            csv_file = os.path.join(current_dir, 'NOWABAZA_final.csv')
            
            with open(csv_file, 'r', newline='', encoding='utf-8-sig') as file:
                reader = csv.DictReader(file)
                self.all_data = list(reader)
                
                # Wypełnij comboboxy filtrów
                marki = sorted(set(item.get('MARKA', '') for item in self.all_data if item.get('MARKA')))
                poziomy = sorted(set(item.get('POZIOM', '') for item in self.all_data if item.get('POZIOM')))
                plcie = sorted(set(item.get('PLEC', '') for item in self.all_data if item.get('PLEC')))
                
                self.marka_combo.addItems(['Wszystkie'] + marki)
                self.poziom_combo.addItems(['Wszystkie'] + poziomy)
                self.plec_combo.addItems(['Wszystkie'] + plcie)
                
                # Ustaw domyślne wartości
                self.marka_combo.setCurrentText('Wszystkie')
                self.poziom_combo.setCurrentText('Wszystkie')
                self.plec_combo.setCurrentText('Wszystkie')
                
                self.apply_filters()
                logger.info(f"Załadowano {len(self.all_data)} nart")
                
        except Exception as e:
            logger.error(f"Błąd podczas ładowania danych: {e}")
            QMessageBox.critical(self.narty_window, "Błąd", f"Nie można załadować danych: {e}")
    
    def apply_filters(self):
        """Stosuje filtry do danych i grupuje identyczne narty"""
        if not hasattr(self, 'all_data'):
            return
            
        filtered = self.all_data.copy()
        
        # Filtr wyszukiwania
        search_text = self.search_entry.text().lower()
        if search_text:
            filtered = [item for item in filtered if 
                       search_text in f"{item.get('MARKA', '')} {item.get('MODEL', '')}".lower()]
        
        # Filtry combobox
        if self.marka_combo.currentText() != 'Wszystkie':
            filtered = [item for item in filtered if item.get('MARKA') == self.marka_combo.currentText()]
        if self.poziom_combo.currentText() != 'Wszystkie':
            poziom_filter = self.poziom_combo.currentText()
            filtered = [item for item in filtered if item.get('POZIOM') == poziom_filter]
        if self.plec_combo.currentText() != 'Wszystkie':
            filtered = [item for item in filtered if item.get('PLEC') == self.plec_combo.currentText()]
        
        # Grupowanie identycznych nart i liczenie ilości
        grouped_data = {}
        for item in filtered:
            # Klucz grupowania - wszystkie parametry oprócz ID i Ilosc
            key = (
                item.get('MARKA', ''),
                item.get('MODEL', ''),
                item.get('DLUGOSC', ''),
                item.get('POZIOM', ''),
                item.get('PLEC', ''),
                item.get('WAGA_MIN', ''),
                item.get('WAGA_MAX', ''),
                item.get('WZROST_MIN', ''),
                item.get('WZROST_MAX', ''),
                item.get('PRZEZNACZENIE', ''),
                item.get('ROK', ''),
                item.get('UWAGI', '')
            )
            
            if key in grouped_data:
                # Zwiększ ilość
                current_qty = int(grouped_data[key].get('ILOSC', '1') or '1')
                item_qty = int(item.get('ILOSC', '1') or '1')
                grouped_data[key]['ILOSC'] = str(current_qty + item_qty)
            else:
                # Dodaj nowy element
                grouped_data[key] = item.copy()
                if 'ILOSC' not in grouped_data[key] or not grouped_data[key]['ILOSC']:
                    grouped_data[key]['ILOSC'] = '1'
        
        self.filtered_data = list(grouped_data.values())
        self.update_table()
    
    def clear_filters(self):
        """Czyści wszystkie filtry"""
        self.search_entry.clear()
        self.marka_combo.setCurrentText('Wszystkie')
        self.poziom_combo.setCurrentText('Wszystkie')
        self.plec_combo.setCurrentText('Wszystkie')
        self.apply_filters()
    
    def clean_uwagi(self, uwagi_text):
        """Czyści uwagi z informacji o dostępności"""
        if not uwagi_text or uwagi_text == '':
            return ''
        
        # Usuń informacje o dostępności (np. "Dostępne: 2 szt.")
        import re
        cleaned = re.sub(r'\s*Dostępne:\s*\d+\s*szt\.?\s*', '', uwagi_text)
        cleaned = re.sub(r'\s*,\s*$', '', cleaned)  # Usuń przecinek na końcu
        cleaned = cleaned.strip()
        
        return cleaned if cleaned else ''

    def update_table(self):
        """Aktualizuje tabelę z przefiltrowanymi danymi"""
        if not hasattr(self, 'filtered_data'):
            return
            
        # Ustaw liczbę wierszy
        self.table.setRowCount(len(self.filtered_data))
        
        # Dodaj dane
        for i, narta in enumerate(self.filtered_data):
            # Wyczyść uwagi z informacji o dostępności
            uwagi_cleaned = self.clean_uwagi(narta.get('UWAGI', ''))
            
            values = [
                i+1,
                narta.get('MARKA', ''),
                narta.get('MODEL', ''),
                narta.get('DLUGOSC', ''),
                narta.get('ILOSC', '1'),
                narta.get('POZIOM', ''),
                narta.get('PLEC', ''),
                narta.get('WAGA_MIN', ''),
                narta.get('WAGA_MAX', ''),
                narta.get('WZROST_MIN', ''),
                narta.get('WZROST_MAX', ''),
                narta.get('PRZEZNACZENIE', ''),
                narta.get('ROK', ''),
                narta.get('UWAGI', '')
            ]
            
            for j, value in enumerate(values):
                item = QTableWidgetItem(str(value))
                self.table.setItem(i, j, item)
        
        # Aktualizuj licznik
        self.count_label.setText(f"Wyświetlane: {len(self.filtered_data)} / {len(self.all_data)} nart")
    
    def save_changes(self):
        """Zapisuje zmiany do pliku CSV"""
        try:
            # Przygotuj dane do zapisania
            data_to_save = []
            for i in range(self.table.rowCount()):
                row_data = {}
                for j in range(self.table.columnCount()):
                    item = self.table.item(i, j)
                    if item:
                        column_name = self.table.horizontalHeaderItem(j).text()
                        # Mapuj nazwy kolumn na nazwy w CSV
                        column_mapping = {
                            "ID": "ID",
                            "Marka": "MARKA", 
                            "Model": "MODEL",
                            "Długość": "DLUGOSC",
                            "Szt.": "ILOSC",
                            "Poziom": "POZIOM",
                            "Płeć": "PLEC",
                            "Waga Min": "WAGA_MIN",
                            "Waga Max": "WAGA_MAX",
                            "Wzrost Min": "WZROST_MIN",
                            "Wzrost Max": "WZROST_MAX",
                            "Przeznaczenie": "PRZEZNACZENIE",
                            "Rok": "ROK",
                            "Uwagi": "UWAGI"
                        }
                        csv_column = column_mapping.get(column_name, column_name)
                        row_data[csv_column] = item.text()
                if row_data:  # Tylko jeśli wiersz nie jest pusty
                    data_to_save.append(row_data)
            
            # Zapisz do pliku
            if data_to_save:
                with open('NOWABAZA_final.csv', 'w', newline='', encoding='utf-8-sig') as file:
                    fieldnames = data_to_save[0].keys()
                    writer = csv.DictWriter(file, fieldnames=fieldnames)
                    writer.writeheader()
                    writer.writerows(data_to_save)
                
                QMessageBox.information(self.narty_window, "Sukces", f"Zapisano {len(data_to_save)} nart do pliku!")
                logger.info(f"Zapisano {len(data_to_save)} nart do CSV")
            else:
                QMessageBox.warning(self.narty_window, "Uwaga", "Brak danych do zapisania!")
                
        except Exception as e:
            QMessageBox.critical(self.narty_window, "Błąd", f"Nie można zapisać danych: {e}")
            logger.error(f"Błąd podczas zapisywania: {e}")
    
    def add_new_ski(self):
        """Dodaje nową nartę do tabeli"""
        # Dodaj nowy wiersz na końcu tabeli
        row_count = self.table.rowCount()
        self.table.insertRow(row_count)
        
        # Wypełnij domyślnymi wartościami
        default_values = [
            str(row_count + 1),  # ID
            "Nowa marka",        # Marka
            "Nowy model",        # Model
            "150",               # Długość
            "1",                 # Szt.
            "1M/1D",             # Poziom
            "U",                 # Płeć
            "50",                # Waga Min
            "100",               # Waga Max
            "150",               # Wzrost Min
            "200",               # Wzrost Max
            "SLG",               # Przeznaczenie
            "2024",              # Rok
            ""                   # Uwagi
        ]
        
        for j, value in enumerate(default_values):
            item = QTableWidgetItem(value)
            self.table.setItem(row_count, j, item)
        
        # Przewiń do nowego wiersza
        self.table.scrollToItem(self.table.item(row_count, 0))
        self.table.selectRow(row_count)
        
        QMessageBox.information(self.narty_window, "Sukces", "Dodano nową nartę! Edytuj parametry i zapisz zmiany.")
        logger.info("Dodano nową nartę do tabeli")
    
    def delete_selected(self):
        """Usuwa wybrane wiersze z tabeli"""
        selected_rows = set()
        for item in self.table.selectedItems():
            selected_rows.add(item.row())
        
        if not selected_rows:
            QMessageBox.warning(self.narty_window, "Uwaga", "Wybierz wiersze do usunięcia!")
            return
        
        # Potwierdź usunięcie
        reply = QMessageBox.question(
            self.narty_window, 
            "Potwierdź usunięcie", 
            f"Czy na pewno chcesz usunąć {len(selected_rows)} wybranych nart?",
            QMessageBox.Yes | QMessageBox.No
        )
        
        if reply == QMessageBox.Yes:
            # Usuń wiersze w odwrotnej kolejności (od końca)
            for row in sorted(selected_rows, reverse=True):
                self.table.removeRow(row)
            
            # Aktualizuj ID
            for i in range(self.table.rowCount()):
                id_item = self.table.item(i, 0)
                if id_item:
                    id_item.setText(str(i + 1))
            
            QMessageBox.information(self.narty_window, "Sukces", f"Usunięto {len(selected_rows)} nart!")
            logger.info(f"Usunięto {len(selected_rows)} nart z tabeli")

# ===== GŁÓWNA FUNKCJA =====
def main():
    app = QApplication(sys.argv)
    
    # Ustawienia aplikacji
    app.setApplicationName("Asystent Doboru Nart")
    app.setApplicationVersion("6.0")
    app.setOrganizationName("WYPAS Ski Rental")
    
    # Stwórz i pokaż główne okno
    window = SkiApp()
    window.show()
    
    # Uruchom aplikację
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()
