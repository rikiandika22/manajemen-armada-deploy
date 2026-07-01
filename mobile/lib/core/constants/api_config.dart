import 'dart:io' show Platform;

class ApiConfig {
  // Using 10.0.2.2 for Android Emulator, 127.0.0.1 for iOS Simulator
  // You can change this to your production IP later using flutter run --dart-define=API_BASE_URL=http://<IP>:8000/api
  
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    try {
      // Menggunakan IP lokal Mac untuk physical device
      return Platform.isIOS ? 'http://192.168.77.65:8000/api' : 'http://192.168.77.65:8000/api';
    } catch (_) {
      return 'http://localhost:8000/api';
    }
  }

  static String get baseHost {
    const envHost = String.fromEnvironment('API_BASE_HOST');
    if (envHost.isNotEmpty) return envHost;
    try {
      return Platform.isIOS ? 'http://192.168.77.65:8000' : 'http://192.168.77.65:8000';
    } catch (_) {
      return 'http://localhost:8000';
    }
  }

  static String? resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '$baseHost$path';
    return '$baseHost/$path';
  }
}
