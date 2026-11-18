"""Bus Delay Prediction API.

Serves the best model from multivariate.ipynb (a scikit-learn Pipeline with
one-hot encoding, StandardScaler and a RandomForestRegressor) to predict how
many minutes a bus will be delayed, so a schedule platform can publish
adjusted arrival times.

Run locally:  uvicorn prediction:app --reload
"""

import io
import threading
from pathlib import Path
from typing import Literal, get_args

import joblib
import pandas as pd
from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, ConfigDict, Field
from sklearn.base import clone
from sklearn.metrics import mean_squared_error

BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "best_model.pkl"
TRAINING_DATA_PATH = BASE_DIR / "training_data.csv"
TARGET = "Min Delay"
MAX_DELAY = 120  # same outlier rule as the notebook (Section 2.2)

# Column order the pipeline was trained with (Section 2.3 of the notebook)
FEATURES = [
    "route_number", "direction", "incident_code",
    "hour", "day_of_week", "month", "is_weekend", "is_night",
]

# Incident codes the model was trained on (codes seen at least 100 times,
# everything rarer was grouped into "OTHER")
IncidentCode = Literal[
    "EFAS", "EFB", "EFCEL", "EFD", "EFFL", "EFHVA", "EFLT", "EFO", "EFP",
    "EFRA", "EFSD", "EFTI", "EFTRM", "EFVIS", "MFBIO", "MFDV", "MFESA",
    "MFFL", "MFGD", "MFO", "MFPI", "MFSAN", "MFSH", "MFTO", "MFUI", "MFUIR",
    "MFUS", "MFVIS", "MFWEA", "OTHER", "SFAE", "SFAP", "SFDP", "SFL", "SFO",
    "SFPOL", "TFCNO", "TFO", "TFOI", "TFOR", "TFPD", "TFPI",
]

INPUT_COLUMNS = ["route_number", "direction", "incident_code", "hour", "day_of_week", "month"]
KNOWN_CODES = set(get_args(IncidentCode))

# The model and the original training data are loaded once at startup from
# the repository files and kept in memory. /retrain replaces both objects, so
# /predict uses the new model straight away without a redeploy.
# (Render's free plan does not keep files written at runtime, so after a
# restart the service starts again from the model in the repository.)
model = joblib.load(MODEL_PATH)
model.set_params(model__n_jobs=1)  # Render's free plan has a single CPU
training_data = pd.read_csv(TRAINING_DATA_PATH)
retrain_lock = threading.Lock()


app = FastAPI(
    title="Bus Delay Prediction API",
    description=(
        "Predicts how many minutes a public bus will be delayed from its route, "
        "direction, incident type and time, so a schedule platform can publish "
        "adjusted arrival times. Trained on TTC Bus Delay Data (City of Toronto "
        "Open Data, Jan 2025 - Sep 2026)."
    ),
    version="1.0.0",
)

# CORS (Cross-Origin Resource Sharing) decides which WEBSITES may call this API
# from a browser. It does not restrict the Flutter mobile app, because a phone
# app is not a browser and does not send CORS checks.
#
# What I allow:
#   - allow_origins: only the two browser origins that need the API, namely the
#     deployed Render site (where the Swagger UI is served) and the local
#     Flutter web debug server (flutter run -d chrome --web-port 8080). No "*"
#     wildcard: with "*", any website on the internet could use this API from
#     its visitors' browsers and run up traffic on the free Render service.
#   - allow_methods: only GET (docs) and POST (/predict and /retrain), the only
#     methods this API uses. PUT, PATCH and DELETE are refused because there is
#     nothing to update or delete.
#   - allow_headers: only Content-Type (JSON bodies and CSV uploads) and Accept,
#     the only headers the app and Swagger send. Anything else is refused.
#   - allow_credentials=False: the API has no logins, cookies or sessions, so
#     browsers must not send the user's cookies or auth headers with requests.
ALLOWED_ORIGINS = [
    "https://bus-delay-prediction-api.onrender.com",  # deployed API + Swagger UI on Render
    "http://localhost:8080",                          # Flutter web debug server
    "http://127.0.0.1:8080",                          # same, by IP address
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Accept"],
    allow_credentials=False,
)


class BusTrip(BaseModel):
    """Input variables for one bus trip. Every field is required."""

    # strict=True: "12" (a string) is rejected for an int field instead of
    # being silently converted, so a wrong type always returns an error.
    # extra="forbid": unknown fields are rejected too.
    model_config = ConfigDict(
        strict=True,
        extra="forbid",
        json_schema_extra={
            "example": {
                "route_number": 29,
                "direction": "N",
                "incident_code": "MFDV",
                "hour": 8,
                "day_of_week": 1,
                "month": 3,
            }
        },
    )

    route_number: int = Field(..., ge=1, le=999, description="Bus route number (1-999)")
    direction: Literal["N", "S", "E", "W"] = Field(..., description="Direction of travel: N, S, E or W")
    incident_code: IncidentCode = Field(..., description="Incident type code, e.g. MFDV = on diversion")
    hour: int = Field(..., ge=0, le=23, description="Hour of the day (0-23)")
    day_of_week: int = Field(..., ge=0, le=6, description="Day of the week (0 = Monday ... 6 = Sunday)")
    month: int = Field(..., ge=1, le=12, description="Month (1-12)")


class PredictionResponse(BaseModel):
    predicted_delay_minutes: float = Field(..., description="Predicted delay in minutes")


class RetrainResponse(BaseModel):
    message: str
    rows_uploaded: int = Field(..., description="Rows in the uploaded CSV")
    rows_used: int = Field(..., description="Valid rows added to the training data")
    rows_dropped: int = Field(..., description="Rows dropped because a value was missing, the wrong type or out of range")
    total_training_rows: int = Field(..., description="Original rows + new rows the model was refitted on")
    new_data_mse_before: float = Field(..., description="MSE of the old model on the uploaded rows")
    new_data_mse_after: float = Field(..., description="MSE of the retrained model on the uploaded rows")


def add_derived_features(frame: pd.DataFrame) -> pd.DataFrame:
    """Add is_weekend and is_night, computed the same way as in the notebook."""
    frame = frame.copy()
    frame["is_weekend"] = (frame["day_of_week"] >= 5).astype(int)
    frame["is_night"] = ((frame["hour"] >= 21) | (frame["hour"] < 5)).astype(int)
    return frame


def predict_delay(pipeline, route_number, direction, incident_code, hour, day_of_week, month) -> float:
    """Predict the bus delay in minutes for one trip (same function as in the notebook)."""
    row = pd.DataFrame([{
        "route_number": route_number,
        "direction": direction,
        "incident_code": incident_code,
        "hour": hour,
        "day_of_week": day_of_week,
        "month": month,
    }])
    row = add_derived_features(row)[FEATURES]
    prediction = float(pipeline.predict(row)[0])
    return round(max(prediction, 0.0), 2)  # a delay cannot be negative


@app.get("/", include_in_schema=False)
def root():
    return {"message": "Bus Delay Prediction API. Open /docs for the Swagger UI."}


@app.post("/predict", response_model=PredictionResponse)
def predict(trip: BusTrip):
    """Predict the delay in minutes for one bus trip."""
    delay = predict_delay(model, **trip.model_dump())
    return PredictionResponse(predicted_delay_minutes=delay)


def clean_new_rows(raw: pd.DataFrame) -> pd.DataFrame:
    """Apply the notebook's cleaning rules to uploaded rows and drop invalid ones."""
    df = raw[INPUT_COLUMNS + [TARGET]].dropna().copy()  # rows with a missing value
    for col in ["route_number", "hour", "day_of_week", "month", TARGET]:
        df[col] = pd.to_numeric(df[col], errors="coerce")  # wrong types become NaN
    df["direction"] = df["direction"].astype(str).str.strip().str.upper()
    df["incident_code"] = df["incident_code"].astype(str).str.strip().str.upper()
    df = df.dropna()

    valid = (
        df["route_number"].between(1, 999)
        & df["direction"].isin(["N", "S", "E", "W"])
        & df["hour"].between(0, 23)
        & df["day_of_week"].between(0, 6)
        & df["month"].between(1, 12)
        & df[TARGET].between(0, MAX_DELAY)
    )
    df = df[valid]
    for col in ["route_number", "hour", "day_of_week", "month", TARGET]:
        df = df[df[col] % 1 == 0]  # whole numbers only
        df[col] = df[col].astype(int)

    # codes the model was not trained on are grouped into OTHER, as in the notebook
    df["incident_code"] = df["incident_code"].where(df["incident_code"].isin(KNOWN_CODES), "OTHER")
    return add_derived_features(df)[FEATURES + [TARGET]]


@app.post("/retrain", response_model=RetrainResponse)
def retrain(file: UploadFile = File(..., description="CSV with the training data columns")):
    """Upload a CSV of new bus delay records; the model is refitted and used straight away.

    Required columns: route_number, direction, incident_code, hour, day_of_week,
    month, Min Delay (is_weekend and is_night are optional; they are recomputed).
    The best model is a RandomForestRegressor, which cannot learn incrementally,
    so it is refitted on the original training data plus the new rows.
    """
    global model, training_data

    if not (file.filename or "").lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Please upload a .csv file.")
    try:
        raw = pd.read_csv(io.BytesIO(file.file.read()))
    except Exception:
        raise HTTPException(status_code=400, detail="The file could not be read as a CSV.")

    missing = [c for c in INPUT_COLUMNS + [TARGET] if c not in raw.columns]
    if missing:
        raise HTTPException(
            status_code=400,
            detail=f"Missing column(s): {', '.join(missing)}. "
                   f"Required: {', '.join(INPUT_COLUMNS + [TARGET])}.",
        )

    new_rows = clean_new_rows(raw)
    if new_rows.empty:
        raise HTTPException(status_code=400, detail="No valid rows found in the uploaded file.")

    if not retrain_lock.acquire(blocking=False):
        raise HTTPException(status_code=409, detail="A retraining is already running. Try again shortly.")
    try:
        X_new, y_new = new_rows[FEATURES], new_rows[TARGET]
        mse_before = mean_squared_error(y_new, model.predict(X_new))

        combined = pd.concat([training_data, new_rows], ignore_index=True)
        new_model = clone(model)
        # sparse one-hot output gives the same model but uses far less memory,
        # which keeps retraining within Render's 512 MB free plan
        new_model.set_params(preprocess__categorical__sparse_output=True)
        new_model.fit(combined[FEATURES], combined[TARGET])

        mse_after = mean_squared_error(y_new, new_model.predict(X_new))
        model, training_data = new_model, combined  # /predict now uses the new model
    finally:
        retrain_lock.release()

    return RetrainResponse(
        message="Model retrained on the original data plus the new rows and is now in use.",
        rows_uploaded=len(raw),
        rows_used=len(new_rows),
        rows_dropped=len(raw) - len(new_rows),
        total_training_rows=len(combined),
        new_data_mse_before=round(mse_before, 2),
        new_data_mse_after=round(mse_after, 2),
    )
