/// API base URL: pass at build/run time with
/// `--dart-define=API_BASE_URL=https://your-api.example.com`
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);

/// Browser Maps JavaScript API key (`GOOGLE_MAPS_JS_API_KEY` in `.env`).
/// `--dart-define=GOOGLE_MAPS_JS_API_KEY=your_key`
const String googleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_JS_API_KEY',
  defaultValue: 'your_google_maps_js_api_key_here',
);

/// Walking route destination (Disneyland main gates).
const String disneylandDestination = String.fromEnvironment(
  'DISNEYLAND_DESTINATION',
  defaultValue: '1313 S Harbor Blvd, Anaheim, CA 92802',
);
