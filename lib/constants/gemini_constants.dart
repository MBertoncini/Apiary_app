// lib/constants/gemini_constants.dart
//
// Costanti condivise per le chiamate dirette a Gemini dal client.
// Centralizzate qui per evitare drift fra ChatService e GeminiAudioProcessor.

const String kGeminiBaseUrl =
    'https://generativelanguage.googleapis.com/v1beta/models';

/// Lista ordinata di modelli Gemini provati in cascata su 429 / errori
/// transitori. Tenere il più capace per primo.
/// ATTENZIONE: ogni tentativo fallito ri-carica l'audio base64 (fino a ~20MB),
/// quindi la lista va tenuta corta e priva di modelli ritirati. Google risponde
/// 404 NOT_FOUND sui modelli dismessi, non 400, quindi la rotazione li prova
/// tutti prima di arrendersi.
const List<String> kGeminiModelFallbacks = [
  'gemini-3.8-flash',
  'gemini-3.6-flash',
  'gemini-3.5-flash-lite',
];
