/// Interfaccia astratta per fornire token di autenticazione.
/// Implementata sia da AuthService (Provider/ChangeNotifier) che da
/// AuthStateNotifier (Riverpod) per permettere ad ApiService di funzionare
/// con entrambi i sistemi di state management.
abstract class AuthTokenProvider {
  Future<String?> getToken();
  Future<bool> refreshToken();
  /// Called when the session is definitively expired and the user must re-login.
  /// Implementations should clear stored tokens and reset auth state.
  Future<void> onSessionExpired() async {}
}
