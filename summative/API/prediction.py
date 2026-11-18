"""Bus Delay Prediction API.

Serves the best model from multivariate.ipynb (a scikit-learn Pipeline with
one-hot encoding, StandardScaler and a RandomForestRegressor) to predict how
many minutes a bus will be delayed, so a schedule platform can publish
adjusted arrival times.

Run locally:  uvicorn prediction:app --reload
"""

from pathlib import Path
from typing import Literal

import joblib
import pandas as pd
from fastapi import FastAPI
from pydantic import BaseModel, ConfigDict, Field

BASE_DIR = Path(__file__).resolve().parent
MODEL_PATH = BASE_DIR / "best_model.pkl"

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

# The model is loaded once at startup from the repository file and kept in
# memory. /retrain replaces this object, so /predict uses the new model
# straight away without a redeploy.
model = joblib.load(MODEL_PATH)


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
