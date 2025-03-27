// lib/config/google_credentials.dart
// Questo file dovrebbe essere in .gitignore per non esporre le credenziali

class GoogleCredentials {
  static const String serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "apiario-manager",
  "private_key_id": "your-private-key-id",
  "private_key": "your-private-key",
  "client_email": "apiario-speech@apiario-manager.iam.gserviceaccount.com",
  "client_id": "your-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/apiario-speech%40apiario-manager.iam.gserviceaccount.com"
}
''';
}