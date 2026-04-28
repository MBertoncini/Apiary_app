// lib/constants/gemini_constants.dart
//
// Costanti condivise per le chiamate dirette a Gemini dal client.
// Centralizzate qui per evitare drift fra ChatService e GeminiAudioProcessor.

const String kGeminiBaseUrl =
    'https://generativelanguage.googleapis.com/v1beta/models';

/// Lista ordinata di modelli Gemini provati in cascata su 429 / errori
/// transitori. Tenere il più capace per primo.
const List<String> kGeminiModelFallbacks = [
  'gemini-2.5-flash',
  'gemini-2.5-flash-lite',
  'gemini-3-flash-preview',
  'gemini-3.1-flash-lite-preview',
];
