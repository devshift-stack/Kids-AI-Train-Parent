# Test Prompts für Kids-AI-Train-Parent (ParentsDash)

Generiert vom Lianko-Agent für konsistente Unit Tests über alle Repos.

---

## 1. Models

### 1.1 Child

**Datei:** `lib/models/child.dart`
**Speichern in:** `test/models/child_test.dart`
**Beschreibung:** Kind-Model mit allen Einstellungen

#### Klassen zu testen:
1. `Child`
   - `create()` - Factory für neues Kind
   - `fromFirestore()` - Parsed Firestore Document
   - `toFirestore()` - Konvertiert zu Firestore Map
   - `copyWith()` - Erstellt Kopie mit Änderungen

2. `GameSettings`
   - `fromMap()` / `toMap()`
   - `copyWith()`

#### Zu testende Szenarien:
- [ ] create() setzt parentCodeExpiresAt auf +7 Tage
- [ ] create() generiert Default TimeLimit
- [ ] fromFirestore parsed alle Felder
- [ ] fromFirestore mit fehlenden Feldern gibt Defaults
- [ ] toFirestore/fromFirestore Roundtrip
- [ ] copyWith ändert nur angegebene Felder
- [ ] GameSettings Defaults sind korrekt

#### Edge Cases:
- Leere linkedDeviceIds
- Null avatarUrl
- Leere gameSettings Map
- Timestamp Conversion

#### Beispiel-Test:
```dart
test('create() setzt parentCodeExpiresAt korrekt', () {
  final now = DateTime.now();
  final child = Child.create(
    id: 'test-id',
    name: 'Max',
    age: 6,
    parentCode: 'ABC123',
  );
  expect(child.parentCodeExpiresAt.isAfter(now.add(Duration(days: 6))), isTrue);
});
```

#### Abhängigkeiten: Keine (nur Firestore Types)

---

### 1.2 TimeLimit

**Datei:** `lib/models/time_limit.dart`
**Speichern in:** `test/models/time_limit_test.dart`
**Beschreibung:** Zeitlimit-Einstellungen für Kinder

#### Klassen zu testen:
1. `TimeLimit`
   - `defaultLimit()` - Factory für Standard-Limits
   - `fromMap()` / `toMap()`
   - `isCurrentlyBedtime()` - Prüft Schlafenszeit
   - `getLimitForDay()` - Gibt Limit für Wochentag

2. `TimeOfDay`
   - `format()` - Formatiert als HH:MM

#### Zu testende Szenarien:
- [ ] defaultLimit hat korrekte Werte
- [ ] isCurrentlyBedtime erkennt Schlafenszeit
- [ ] isCurrentlyBedtime funktioniert über Mitternacht
- [ ] getLimitForDay gibt weekdayLimits wenn gesetzt
- [ ] getLimitForDay gibt dailyMinutes als Fallback
- [ ] TimeOfDay.format() formatiert korrekt

#### Edge Cases:
- bedtimeEnabled = false
- Schlafenszeit genau über Mitternacht (20:00 - 07:00)
- Schlafenszeit am selben Tag (13:00 - 15:00)
- Leere weekdayLimits

#### Beispiel-Test:
```dart
test('isCurrentlyBedtime erkennt Schlafenszeit über Mitternacht', () {
  final limit = TimeLimit(
    bedtimeStart: TimeOfDay(hour: 20, minute: 0),
    bedtimeEnd: TimeOfDay(hour: 7, minute: 0),
    bedtimeEnabled: true,
  );
  // Test um 22:00 - sollte Schlafenszeit sein
  // Test um 10:00 - sollte KEINE Schlafenszeit sein
});

test('TimeOfDay.format() formatiert korrekt', () {
  expect(TimeOfDay(hour: 8, minute: 5).format(), equals('08:05'));
  expect(TimeOfDay(hour: 20, minute: 30).format(), equals('20:30'));
});
```

#### Abhängigkeiten: Keine

---

### 1.3 AccessibilitySettings

**Datei:** `lib/models/accessibility_settings.dart`
**Speichern in:** `test/models/accessibility_settings_test.dart`
**Beschreibung:** Barrierefreiheit-Einstellungen (Untertitel)

#### Klassen zu testen:
1. `AccessibilitySettings`
   - `fromMap()` / `toMap()`
   - `copyWith()`
   - `currentLanguageName` - Gibt Sprachname zurück

2. `SubtitleLanguage` - Statische Daten

#### Zu testende Szenarien:
- [ ] Default subtitlesEnabled ist false
- [ ] currentLanguageName gibt korrekten Namen
- [ ] availableLanguages enthält alle erwarteten Sprachen
- [ ] fromMap mit fehlenden Feldern gibt Defaults

#### Edge Cases:
- subtitleLanguage mit ungültigem Code

#### Beispiel-Test:
```dart
test('currentLanguageName gibt korrekten Namen', () {
  final settings = AccessibilitySettings(
    subtitlesEnabled: true,
    subtitleLanguage: 'de',
  );
  expect(settings.currentLanguageName, equals('Deutsch'));
});
```

#### Abhängigkeiten: Keine

---

## 2. Services

### 2.1 PinService

**Datei:** `lib/services/pin_service.dart`
**Speichern in:** `test/services/pin_service_test.dart`
**Beschreibung:** PIN-Schutz für Eltern-Dashboard

#### Klassen zu testen:
1. `PinService`
   - `isPinEnabled()` - Prüft ob PIN aktiviert
   - `isLockedOut()` - Prüft ob gesperrt
   - `getRemainingLockoutSeconds()` - Verbleibende Sperrzeit
   - `getRemainingAttempts()` - Verbleibende Versuche
   - `setPin()` - Setzt neuen PIN
   - `verifyPin()` - Verifiziert PIN
   - `changePin()` - Ändert PIN
   - `disablePin()` - Deaktiviert PIN

2. `PinVerificationResult`
   - Factory Methods: success(), wrongPin(), lockedOut(), noPinSet()

#### Zu testende Szenarien:
- [ ] setPin akzeptiert nur 4 Ziffern
- [ ] setPin hasht PIN korrekt
- [ ] verifyPin gibt success bei korrektem PIN
- [ ] verifyPin gibt wrongPin bei falschem PIN
- [ ] verifyPin zählt Fehlversuche
- [ ] Nach 5 Fehlversuchen: lockout für 15 Min
- [ ] isLockedOut wird nach Ablauf automatisch zurückgesetzt
- [ ] changePin benötigt korrekten alten PIN
- [ ] disablePin benötigt korrekten PIN

#### Edge Cases:
- PIN = "0000" (gültig)
- PIN mit Buchstaben (ungültig)
- PIN mit weniger/mehr als 4 Zeichen
- Lockout genau abgelaufen

#### Beispiel-Test:
```dart
test('setPin akzeptiert nur 4 Ziffern', () async {
  final prefs = MockSharedPreferences();
  final service = PinService(prefs);

  expect(await service.setPin('1234'), isTrue);
  expect(await service.setPin('123'), isFalse);  // Zu kurz
  expect(await service.setPin('12345'), isFalse); // Zu lang
  expect(await service.setPin('abcd'), isFalse);  // Keine Ziffern
});

test('verifyPin sperrt nach 5 Fehlversuchen', () async {
  // 5x falscher PIN eingeben
  // Dann prüfen ob isLockedOut() true ist
});
```

#### Abhängigkeiten:
- Mock für SharedPreferences

---

### 2.2 ChildrenService

**Datei:** `lib/services/children_service.dart`
**Speichern in:** `test/services/children_service_test.dart`
**Beschreibung:** CRUD für Kinder in Firestore

#### Klassen zu testen:
1. `ChildrenService`
   - `watchChildren()` - Stream von Kindern
   - `getChild()` - Einzelnes Kind laden
   - `createChild()` - Kind erstellen
   - `updateChild()` - Kind aktualisieren
   - `deleteChild()` - Kind löschen
   - `updateTimeLimit()` - Zeitlimit aktualisieren
   - `updateGameSettings()` - Spieleinstellungen aktualisieren
   - `regenerateParentCode()` - Neuen ParentCode generieren
   - `unlinkDevice()` - Gerät entfernen

#### Zu testende Szenarien:
- [ ] createChild generiert einzigartigen ParentCode
- [ ] createChild speichert in Firestore
- [ ] getChild gibt null bei nicht existierendem Kind
- [ ] updateTimeLimit aktualisiert nur timeLimit Feld
- [ ] unlinkDevice entfernt deviceId aus Array

#### Edge Cases:
- Kind existiert nicht
- Firestore Fehler

#### Beispiel-Test:
```dart
test('createChild generiert einzigartigen ParentCode', () async {
  // Mock Firestore und ParentCodeService
  // createChild aufrufen
  // Prüfen dass ParentCode generiert wurde
});
```

#### Abhängigkeiten:
- Mock für FirebaseFirestore
- Mock für ParentCodeService

---

### 2.3 NotificationService

**Datei:** `lib/services/notification_service.dart`
**Speichern in:** `test/services/notification_service_test.dart`
**Beschreibung:** Push Notifications für Eltern

#### Klassen zu testen:
1. `NotificationService`
   - `initialize()` - Initialisiert Service
   - `showLocalNotification()` - Zeigt lokale Notification
   - `getToken()` - Holt FCM Token
   - `subscribeToTopic()` / `unsubscribeFromTopic()`
   - `subscribeToChild()` / `unsubscribeFromChild()`

#### Zu testende Szenarien:
- [ ] initialize wird nur einmal ausgeführt
- [ ] subscribeToChild subscribed zu 'child_{id}' Topic
- [ ] showLocalNotification zeigt Notification

#### Edge Cases:
- Permissions nicht erteilt
- FCM Token null

#### Abhängigkeiten:
- Mock für FirebaseMessaging
- Mock für FlutterLocalNotificationsPlugin
- Mock für FirebaseFirestore
- Mock für FirebaseAuth

---

## 3. Providers

### 3.1 ChildrenProvider

**Datei:** `lib/providers/children_provider.dart`
**Speichern in:** `test/providers/children_provider_test.dart`
**Beschreibung:** State Management für Kinder

#### Zu testende Szenarien:
- [ ] Provider lädt Kinder korrekt
- [ ] Provider reagiert auf Auth-Änderungen

---

### 3.2 PinProvider

**Datei:** `lib/providers/pin_provider.dart`
**Speichern in:** `test/providers/pin_provider_test.dart`
**Beschreibung:** State Management für PIN

#### Zu testende Szenarien:
- [ ] Provider Status nach Lock/Unlock

---

## Zusammenfassung

| Modul | Priorität | Komplexität |
|-------|-----------|-------------|
| Child Model | Hoch | Niedrig |
| TimeLimit Model | Hoch | Mittel |
| AccessibilitySettings | Mittel | Niedrig |
| PinService | Hoch | Mittel |
| ChildrenService | Hoch | Hoch (Firestore) |
| NotificationService | Mittel | Hoch (ext. APIs) |
