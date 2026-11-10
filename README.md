# NEXUS LOOP

Native Android-App (Flutter) im Spotify-Stil – ein Endlosschleifen-Video-Player mit echter Hintergrundwiedergabe.

**Kein Base44. Keine Webseite. Eine echte APK.**

## Download

Aktuelle Version: **[v2.0.1](https://github.com/Baschar2010/NEXUS_LOOP/releases/latest)**

APK herunterladen, installieren, fertig.

## Features

- Spotify-artiges Dark-Design (Schwarz/Grün)
- Playlists mit Tabs und „+ NEU“
- Videos aus der Galerie hinzufügen (nur Videos, keine Fotos)
- Grid- und Listen-Ansicht mit Suche
- Fullscreen-Player mit Wisch-Gesten
- Lautstärke-Regler
- Endlosschleife
- Löschen (einzeln oder alle)
- Verschieben zwischen Playlists
- Export
- Große, gut treffbare Buttons unten
- **In-App-Update:** Meldet neue Versionen automatisch, lädt und installiert sie mit einem Tipp auf „Aktualisieren“

## Neu in v2.0.1

- **Hintergrundwiedergabe wirklich durchgehend:** Musik läuft weiter, wenn die App minimiert, verlassen oder der Bildschirm ausgeschaltet wird – auch wenn man vom Player zurück zur Übersicht geht
- **Ursache behoben:** Beim Verlassen des Players wurde die Wiedergabe bisher aktiv gestoppt; außerdem wurde der Vordergrunddienst bei Pause beendet
- Eigene Media-Benachrichtigung mit korrektem Icon und Play/Pause
- Mini-Player auf der Startseite (Pause / Stopp), wenn im Hintergrund weiterläuft
- Einmalige Nachfrage nach Akku-Optimierung (verhindert, dass Hersteller die Wiedergabe beenden)
- In-App-Update repariert: Internet- und Installations-Berechtigung fehlten in der Release-APK

## Neu in v2.0.0

- **Echte Hintergrundwiedergabe wie Spotify:** Audio läuft weiter, wenn die App verlassen wird oder der Bildschirm ausgeht
- Media-Benachrichtigung mit Play/Pause (Sperrbildschirm & Benachrichtigungsleiste)
- Video und Audio bleiben synchron – beim Zurückkehren in die App springt das Video an die aktuelle Position

## Technik

- Flutter (Dart)
- `video_player` für die Anzeige
- `just_audio` + `audio_service` für die Hintergrundwiedergabe
- `sqflite` für die lokale Datenbank
- `image_picker` für den Video-Import
