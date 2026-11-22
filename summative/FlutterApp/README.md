# Bus Delay Predictor (Flutter app)

A one-page mobile app that predicts how many minutes a bus will be delayed. It sends the trip details to the live Bus Delay Prediction API:

`POST https://bus-delay-prediction-api.onrender.com/predict`

## Inputs

| Field | Allowed values |
|---|---|
| Route number | 1 to 999, e.g. 29 |
| Direction | N, S, E or W |
| Incident code | e.g. MFDV (on diversion), MFUS, EFO, or OTHER |
| Hour of the day | 0 to 23 |
| Day of the week | 0 = Monday ... 6 = Sunday |
| Month | 1 to 12 |

Direction, incident code and day of the week also have a list button: tap it to choose a value from a list with plain descriptions (for example *Bus on diversion* for `MFDV`), and it is filled into the text field.

Press **Predict** to see the predicted delay in minutes. If a value is missing, the wrong type or out of range, the app shows the reason instead.

## How to run

Requirements: the [Flutter SDK](https://docs.flutter.dev/get-started/install) and an iOS simulator or Android emulator (or a phone connected by USB).

```bash
cd summative/FlutterApp
flutter pub get
flutter devices          # find the id of your simulator / emulator
flutter run -d <device-id>
```

The API runs on Render's free plan, which sleeps when idle, so the first prediction can take up to a minute while the server wakes up.

## Tests

```bash
flutter analyze
flutter test
```
