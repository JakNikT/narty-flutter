"""
Moduł głównej logiki dobierania nart
Zawiera funkcje wyszukiwania i kategoryzacji nart
"""
import logging
from logika.ocena_dopasowania import compatibility_scorer
from logika.parsowanie_poziomow import parsuj_poziom

logger = logging.getLogger(__name__)

def sprawdz_dopasowanie_narty(row, wzrost, waga, poziom, plec, styl_jazdy):
    """Sprawdza dopasowanie pojedynczej narty do kryteriów klienta"""
    try:
        if not all(key in row and row[key] for key in ['POZIOM', 'WAGA_MIN', 'WAGA_MAX', 'WZROST_MIN', 'WZROST_MAX', 'DLUGOSC', 'PLEC']):
            return None

        waga_min = int(float(row['WAGA_MIN']))
        waga_max = int(float(row['WAGA_MAX']))
        min_wzrost_narciarza = int(float(row['WZROST_MIN']))
        max_wzrost_narciarza = int(float(row['WZROST_MAX']))
        narta_plec = row.get('PLEC', 'U').strip() or 'U'

        # Parsuj poziom w zależności od formatu
        poziom_text = row.get('POZIOM', '').strip()
        poziom_min, poziom_display = parsuj_poziom(poziom_text, plec)
        if poziom_min is None:
            return None

        # Sprawdź czy poziom nie jest o 2+ za niski - wyklucz całkowicie
        POZIOM_TOLERANCJA_W_DOL = 2
        if poziom < poziom_min - POZIOM_TOLERANCJA_W_DOL:
            return None

        dopasowanie = {}
        zielone_punkty = 0
        poziom_niżej_kandydat = False

        # Sprawdź poziom
        if poziom == poziom_min:
            dopasowanie['poziom'] = ('green', 'OK', poziom_display)
            zielone_punkty += 1
        elif poziom == poziom_min + 1:
            dopasowanie['poziom'] = ('orange', f'Narta słabsza o jeden poziom', poziom_display)
            poziom_niżej_kandydat = True
        elif poziom > poziom_min + 1:
            return None  # Wyklucz całkowicie
        else:
            return None

        # Sprawdź płeć
        if plec == "Wszyscy":
            dopasowanie['plec'] = ('green', 'OK', narta_plec)
            zielone_punkty += 1
        elif plec == "Kobieta":
            if narta_plec in ["K", "D", "U"]:
                dopasowanie['plec'] = ('green', 'OK', narta_plec)
                zielone_punkty += 1
            elif narta_plec == "M":
                dopasowanie['plec'] = ('orange', 'Narta męska', narta_plec)
            else:
                dopasowanie['plec'] = ('orange', 'Nieznana płeć', narta_plec)
        elif plec == "Mężczyzna":
            if narta_plec in ["M", "U"]:
                dopasowanie['plec'] = ('green', 'OK', narta_plec)
                zielone_punkty += 1
            elif narta_plec in ["K", "D"]:
                dopasowanie['plec'] = ('orange', 'Narta kobieca', narta_plec)
            else:
                dopasowanie['plec'] = ('orange', 'Nieznana płeć', narta_plec)

        # Sprawdź wagę
        WAGA_TOLERANCJA = 5
        if waga_min <= waga <= waga_max:
            dopasowanie['waga'] = ('green', 'OK', waga_min, waga_max)
            zielone_punkty += 1
        elif waga > waga_max and waga <= waga_max + WAGA_TOLERANCJA:
            dopasowanie['waga'] = ('orange', f'O {waga - waga_max} kg za duża (miększa)', waga_min, waga_max)
        elif waga < waga_min and waga >= waga_min - WAGA_TOLERANCJA:
            dopasowanie['waga'] = ('orange', f'O {waga_min - waga} kg za mała (sztywniejsza)', waga_min, waga_max)
        else:
            dopasowanie['waga'] = ('red', 'Niedopasowana', waga_min, waga_max)

        # Sprawdź wzrost
        WZROST_TOLERANCJA = 5
        if min_wzrost_narciarza <= wzrost <= max_wzrost_narciarza:
            dopasowanie['wzrost'] = ('green', 'OK', min_wzrost_narciarza, max_wzrost_narciarza)
            zielone_punkty += 1
        elif wzrost > max_wzrost_narciarza and wzrost <= max_wzrost_narciarza + WZROST_TOLERANCJA:
            dopasowanie['wzrost'] = ('orange', f'O {wzrost - max_wzrost_narciarza} cm za duży (zwrotniejsza)', min_wzrost_narciarza, max_wzrost_narciarza)
        elif wzrost < min_wzrost_narciarza and wzrost >= min_wzrost_narciarza - WZROST_TOLERANCJA:
            dopasowanie['wzrost'] = ('orange', f'O {min_wzrost_narciarza - wzrost} cm za mały (stabilniejsza)', min_wzrost_narciarza, max_wzrost_narciarza)
        else:
            dopasowanie['wzrost'] = ('red', 'Niedopasowany', min_wzrost_narciarza, max_wzrost_narciarza)

        # Sprawdź przeznaczenie
        if styl_jazdy and styl_jazdy != "Wszystkie":
            przeznaczenie = row.get('PRZEZNACZENIE', '')
            if przeznaczenie:
                przeznaczenia = [p.strip() for p in przeznaczenie.replace(',', ',').split(',')]
                if styl_jazdy in przeznaczenia:
                    dopasowanie['przeznaczenie'] = ('green', 'OK', przeznaczenie)
                    zielone_punkty += 1
                else:
                    dopasowanie['przeznaczenie'] = ('orange', f'Inne przeznaczenie ({przeznaczenie})', przeznaczenie)
            else:
                dopasowanie['przeznaczenie'] = ('orange', 'Brak przeznaczenia', '')
        else:
            dopasowanie['przeznaczenie'] = ('green', 'OK', row.get('PRZEZNACZENIE', ''))

        # Wyklucz narty z czerwonymi kryteriami
        if any(v[0] == 'red' for v in dopasowanie.values()):
            return None

        # Oblicz współczynnik idealności
        wspolczynnik, detale_oceny = compatibility_scorer.oblicz_wspolczynnik_idealnosci(
            dopasowanie, wzrost, waga, poziom, plec, styl_jazdy
        )

        return {
            'dane': row,
            'dopasowanie': dopasowanie,
            'wspolczynnik_idealnosci': wspolczynnik,
            'detale_oceny': detale_oceny,
            'zielone_punkty': zielone_punkty,
            'poziom_niżej_kandydat': poziom_niżej_kandydat
        }

    except (ValueError, TypeError) as e:
        logger.warning(f"Pominięto wiersz z powodu błędu danych: {row} - {e}")
        return None

def znajdz_idealne_dopasowania(narty, wzrost, waga, poziom, plec, styl_jazdy):
    """Znajduje narty z idealnym dopasowaniem (wszystkie kryteria spełnione)"""
    idealne = []
    max_punkty = 5 if (styl_jazdy and styl_jazdy != "Wszystkie") else 4
    
    for row in narty:
        narta_info = sprawdz_dopasowanie_narty(row, wzrost, waga, poziom, plec, styl_jazdy)
        if narta_info and narta_info['zielone_punkty'] == max_punkty:
            # Sprawdź czy to nie problem z płcią
            plec_status = narta_info['dopasowanie'].get('plec')
            if plec_status and plec_status[1] not in ['OK']:
                if 'Narta męska' in plec_status[1] or 'Narta kobieca' in plec_status[1]:
                    continue  # Pomiń - to będzie w "INNA PŁEĆ"
            idealne.append(narta_info)
    
    return idealne

def znajdz_poziom_za_nisko(narty, wzrost, waga, poziom, plec, styl_jazdy):
    """Znajduje narty z poziomem za niskim (wszystkie inne kryteria OK)"""
    poziom_za_nisko = []
    max_punkty = 5 if (styl_jazdy and styl_jazdy != "Wszystkie") else 4
    
    for row in narty:
        narta_info = sprawdz_dopasowanie_narty(row, wzrost, waga, poziom, plec, styl_jazdy)
        if narta_info and narta_info['poziom_niżej_kandydat']:
            # Sprawdź czy reszta kryteriów jest OK
            pozostałe_punkty = narta_info['zielone_punkty']
            max_pozostałe_punkty = max_punkty - 1
            
            if pozostałe_punkty == max_pozostałe_punkty:
                # Sprawdź czy to nie problem z płcią - jeśli tak, pomiń (będzie w "INNA PŁEĆ")
                plec_status = narta_info['dopasowanie'].get('plec')
                if plec_status and plec_status[1] not in ['OK']:
                    if 'Narta męska' in plec_status[1] or 'Narta kobieca' in plec_status[1]:
                        continue  # Pomiń - to będzie w "INNA PŁEĆ"
                poziom_za_nisko.append(narta_info)
    
    return poziom_za_nisko

def znajdz_alternatywy(narty, wzrost, waga, poziom, plec, styl_jazdy):
    """Znajduje narty alternatywne (poziom OK, ale inne kryteria nie idealne)"""
    alternatywy = []
    max_punkty = 5 if (styl_jazdy and styl_jazdy != "Wszystkie") else 4
    
    for row in narty:
        narta_info = sprawdz_dopasowanie_narty(row, wzrost, waga, poziom, plec, styl_jazdy)
        if narta_info and not narta_info['poziom_niżej_kandydat'] and narta_info['zielone_punkty'] < max_punkty:
            # Sprawdź czy to nie problem z płcią - jeśli tak, pomiń (będzie w "INNA PŁEĆ")
            plec_status = narta_info['dopasowanie'].get('plec')
            if plec_status and plec_status[1] not in ['OK']:
                if 'Narta męska' in plec_status[1] or 'Narta kobieca' in plec_status[1]:
                    continue  # Pomiń - to będzie w "INNA PŁEĆ"
            alternatywy.append(narta_info)
    
    return alternatywy

def znajdz_inna_plec(narty, wzrost, waga, poziom, plec, styl_jazdy):
    """Znajduje narty z niepasującą płcią (wszystkie inne kryteria OK)"""
    inna_plec = []
    max_punkty = 5 if (styl_jazdy and styl_jazdy != "Wszystkie") else 4
    
    for row in narty:
        narta_info = sprawdz_dopasowanie_narty(row, wzrost, waga, poziom, plec, styl_jazdy)
        if narta_info and not narta_info['poziom_niżej_kandydat']:
            # Sprawdź czy to problem z płcią
            plec_status = narta_info['dopasowanie'].get('plec')
            if plec_status and plec_status[1] not in ['OK']:
                if 'Narta męska' in plec_status[1] or 'Narta kobieca' in plec_status[1]:
                    # Sprawdź czy reszta kryteriów jest OK (poziom OK, waga OK, wzrost OK, przeznaczenie OK)
                    pozostałe_punkty = narta_info['zielone_punkty']
                    max_pozostałe_punkty = max_punkty - 1  # Płeć nie liczy się do punktów
                    
                    if pozostałe_punkty == max_pozostałe_punkty:
                        inna_plec.append(narta_info)
    
    return inna_plec

def dobierz_narty(wzrost, waga, poziom, plec, styl_jazdy=None):
    """Główna funkcja dobierania nart - teraz z osobnymi wyszukiwaniami dla każdej kategorii"""
    logger.info(f"Szukanie nart: wzrost={wzrost}, waga={waga}, poziom={poziom}, plec={plec}, styl={styl_jazdy}")
    
    try:
        # Import tutaj aby uniknąć cyklicznych importów
        from dane.wczytywanie_danych import wczytaj_narty
        
        # Wczytaj wszystkie narty
        wszystkie_narty = wczytaj_narty()
        if not wszystkie_narty:
            logger.error("Nie znaleziono nart w bazie danych")
            return None, None, None, None

        # Znajdź narty w każdej kategorii osobno
        idealne = znajdz_idealne_dopasowania(wszystkie_narty, wzrost, waga, poziom, plec, styl_jazdy)
        poziom_za_nisko = znajdz_poziom_za_nisko(wszystkie_narty, wzrost, waga, poziom, plec, styl_jazdy)
        alternatywy = znajdz_alternatywy(wszystkie_narty, wzrost, waga, poziom, plec, styl_jazdy)
        inna_plec = znajdz_inna_plec(wszystkie_narty, wzrost, waga, poziom, plec, styl_jazdy)

        # Sortuj wyniki
        def sort_key(narta_info):
            wspolczynnik = narta_info.get('wspolczynnik_idealnosci', 0)
            return -wspolczynnik  # Od najwyższego do najniższego

        idealne.sort(key=sort_key)
        poziom_za_nisko.sort(key=sort_key)
        alternatywy.sort(key=sort_key)
        inna_plec.sort(key=sort_key)

        logger.info(f"Znaleziono: {len(idealne)} idealnych, {len(poziom_za_nisko)} poziom za nisko, {len(alternatywy)} alternatyw, {len(inna_plec)} inna płeć")
        return idealne, poziom_za_nisko, alternatywy, inna_plec

    except Exception as e:
        logger.error(f"Wystąpił nieoczekiwany błąd: {e}")
        from PyQt5.QtWidgets import QMessageBox
        QMessageBox.critical(None, "Błąd Krytyczny", f"Wystąpił nieoczekiwany błąd: {e}")
        return None, None, None, None
