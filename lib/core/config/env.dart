/// Build-time configuration, shared by the portal and the crew app.
///
/// ```
/// flutter run -t lib/main_crew.dart --dart-define=API_BASE_URL=http://localhost:8080/v1 --dart-define=USE_FAKE_DATA=false
/// ```
abstract final class Env {
  /// Tenant API base URL (see `servers:` in tm-clock-api/api/openapi.yaml).
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/v1',
  );

  /// true → repositories return built-in sample data, no backend needed.
  /// Flip to false once the API is running; no screen code changes.
  static const useFakeData = bool.fromEnvironment('USE_FAKE_DATA', defaultValue: true);
}
