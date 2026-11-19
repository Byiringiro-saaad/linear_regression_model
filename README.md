# Bus Delay Prediction

## Mission and problem

My mission is to give commuters in fast-growing African cities precise, reliable bus schedules.
Buses are often late, and fixed timetables do not show by how much, so passengers cannot plan their trips.
This project predicts a bus's delay in minutes from its route, direction, incident type and time,
so a schedule platform can publish adjusted arrival times.

## Dataset

**TTC Bus Delay Data** from the City of Toronto Open Data portal: [open.toronto.ca/dataset/ttc-bus-delay-data](https://open.toronto.ca/dataset/ttc-bus-delay-data/).
It has 107,349 recorded bus delays (January 2025 to September 2026), each with the route, direction, incident code, date, time and delay in minutes. African cities do not yet publish open bus delay data, so this well-documented dataset is used to build and test the prototype; the same approach can be retrained on local data once it is collected. After cleaning, 81,967 rows and 8 features were used. The best model is a Random Forest (test MSE 107.9, compared with 198.4 for always predicting the average).

## API (Swagger UI)

**https://bus-delay-prediction-api.onrender.com/docs**

- `POST /predict`: predicts the delay in minutes for one trip.
- `POST /retrain`: upload a CSV of new delay records (for example `summative/API/sample_retrain_data.csv`) to refit the model.

The API runs on Render's free plan, which sleeps when idle, so the first request can take up to a minute.

## Video demo

YouTube: **[ADD YOUTUBE LINK]**

## How to run the mobile app

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) and check it with `flutter doctor`.
2. Start an emulator or simulator, or connect a phone by USB:
   - **iOS (macOS only):** `open -a Simulator`
   - **Android:** open Android Studio > Device Manager and start a virtual device.
3. Clone the repository and open the app folder:
   ```bash
   git clone https://github.com/Byiringiro-saaad/linear_regression_model.git
   cd linear_regression_model/summative/FlutterApp
   ```
4. Install the dependencies:
   ```bash
   flutter pub get
   ```
5. Find your device id and run the app:
   ```bash
   flutter devices
   flutter run -d <device-id>
   ```
6. Fill in the 6 fields (for example route `29`, direction `N`, incident code `MFDV`, hour `8`, day of week `1`, month `3`) and press **Predict**. The predicted delay appears below the button; if a value is missing, the wrong type or out of range, an error message appears there instead.

## Run the notebook and the API locally (optional)

Requires [uv](https://docs.astral.sh/uv/).

```bash
cd summative
uv sync
uv run jupyter notebook linear_regression/multivariate.ipynb   # the notebook
cd API && uv run uvicorn prediction:app --reload                # the API at http://127.0.0.1:8000/docs
```
