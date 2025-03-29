// lib/config/google_credentials.dart
// Questo file dovrebbe essere in .gitignore per non esporre le credenziali

class GoogleCredentials {
  static const String serviceAccountJson = '''
{
  "type": "service_account",
  "project_id": "gen-lang-client-0768336901",
  "private_key_id": "your-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC7VJTUt9Us\\n...MOLTE ALTRE RIGHE...\\n-----END PRIVATE KEY-----\\n",
  "client_email": "apiario-speech@gen-lang-client-0768336901.iam.gserviceaccount.com",
  "client_id": "1027906615551",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/apiario-speech%40apiario-manager.iam.gserviceaccount.com"
}
''';
}