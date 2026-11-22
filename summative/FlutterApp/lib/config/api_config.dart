/// Settings for the Bus Delay Prediction API on Render.
class ApiConfig {
  ApiConfig._();

  /// Live prediction endpoint.
  static const String predictUrl =
      'https://bus-delay-prediction-api.onrender.com/predict';

  /// The free Render service sleeps when idle and can take up to a minute to
  /// wake up, so the timeout is generous.
  static const Duration timeout = Duration(seconds: 90);
}
