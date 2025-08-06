# README - BierClicker Game

## Overzicht
BierClicker is een idle game voor iOS, waarin spelers bier verzamelen door op een bierdop te klikken en automatische bierproductie opbouwen door verschillende items te kopen.

## Hoofdfuncties

### Basis Gameplay
- Tik op de bierdop om handmatig bier te verzamelen
- Koop items die automatisch bier genereren:
  - Bierfles: produceert 0.1 bier per seconde
  - Bierkrat: produceert 0.3 bier per seconde
  - Bierfust: produceert 1.0 bier per seconde
- Items verschijnen visueel rondom de bierdop en roteren in een cirkel

### Winkel
- Toegankelijk via de winkelknop rechtsonder
- Items worden duurder naarmate je verder komt
- Visuele feedback bij aankopen (succesvol/mislukt)
- Automatisch sluiten bij tikken buiten het winkelvenster

### Progressie en Opslag
- Automatisch opslaan van spelvoortgang elke 30 seconden
- Voortgang wordt bewaard bij sluiten van de app
- Offline productie: verdien bier ook als de app gesloten is
- Welkomstbericht met offline verdiensten bij terugkeer

### Visuele Effecten
- Animatie van de bierdop bij tikken
- Zwevende items die rond de bierdop draaien
- Verhoogde rotatiesnelheid bij sneller tikken
- Items verschijnen proportioneel aan je bezittingen

### Overige Functies
- Reset-knop om het spel opnieuw te beginnen
- Weergave van bier per seconde
- Offline inkomsten gebaseerd op je bezittingen

## Technische Details

### Opslag
- Gegevens worden opgeslagen in UserDefaults
- Opgeslagen waardes:
  - bierCount: totaal aantal bier
  - bierFlesCount: aantal bierflessen
  - kratCount: aantal bierkratten
  - bierFustCount: aantal bierfusten
  - lastSaveTime: tijdstip van laatste opslag

### UI Componenten
- UIViewController als hoofdcontroller
- UIImageView voor de bierdop en zwevende items
- UILabels voor tellingen en statistieken
- UIView voor het winkelvenster
- UIButtons voor winkel en reset functionaliteit

### Animaties
- Rotatie van items rondom de bierdop
- Schaal- en kleuranimaties bij tikken en aankopen
- Vloeiende animatie van winkel openen/sluiten

## Vereisten
- iOS apparaat/simulator
- Afbeeldingen nodig: "bierdop", "bierfles", "bierkrat", "bierfust"

## Toekomstige Verbeteringen
- Meer items toevoegen voor grotere diversiteit
- Achievements systeem
- Prestigesysteem voor langdurige spelervaring

---

Veel plezier met BierClicker! 🍻
