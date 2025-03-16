// services/jokes_service.dart
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class JokesService {
  static const String _shownJokesKey = 'shown_bee_jokes';
  
  // Lista di 35 freddure sulle api
  static final List<String> _apiFreddure = [
    "Qual è il cantante preferito delle api? Bee Gees!",
    "Qual è il supereroe preferito delle api? Wasp!",
    "Cosa dice un'ape quando torna a casa? Honey, I'm home!",
    "Qual è il film preferito delle api? The Bee Movie!",
    "L'ape è andata dal dottore. Ha la febbre al-veare!",
    "Qual è lo sport preferito delle api? Bee-liardo!",
    "Qual è il motto delle api? Bee yourself!",
    "Qual è il politico preferito delle api? Bee-rlusconi!"
    "Qual è l'attore preferito delle api? Leonardo Di C-api!",
    "Perché le api non usano il telefono? Perché preferiscono il buzz-er!",
    "Qual è il social media preferito delle api? BeeChat!",
    "Come si chiama un'ape filosofa? Api-stotele!",
    "Come si chiama un'ape che adora viaggiare? Honey-moon!",
    "Qual è la città preferita dalle api? Miel-bourne!",
    "Qual è la serie TV preferita dalle api? Breaking Buzz!",
    "Cosa dice un'ape alle amiche? Ci vediamo all'apiritivo alle 7!",
    "Come si chiama un'ape musicista? Bee-thoven!",
    "Qual è la canzone preferita delle api? Stinging in the Rain!",
    "Come si chiama un'ape che gioca a calcio? Lionel Bee-ssi!",
    "Qual è il programma TV preferito delle api? Un posto al fiore!",
    "Qual è lo strumento musicale preferito dalle api? Il saxofavo!",
    "Come si chiama un'ape campione di nuoto? Michael Bee-lps!",
    "Come si chiama un'ape scienziata? Albert Ein-sting!",
    "Qual è la festa preferita dalle api? Il Capodanno, quando tutte in coro urlano il conto alla ro-vespa!"
  ];
  
  // Ottieni una freddura casuale
  static Future<String> getRandomJoke() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Recupera le freddure già mostrate
    List<String> shownJokes = prefs.getStringList(_shownJokesKey) ?? [];
    
    // Se tutte le freddure sono state mostrate, resetta la lista
    if (shownJokes.length >= _apiFreddure.length) {
      shownJokes = [];
      await prefs.setStringList(_shownJokesKey, shownJokes);
    }
    
    // Filtra le freddure che non sono ancora state mostrate
    List<String> availableJokes = _apiFreddure.where((joke) => !shownJokes.contains(joke)).toList();
    
    // Seleziona una freddura casuale
    final random = Random();
    final joke = availableJokes[random.nextInt(availableJokes.length)];
    
    // Aggiungi la freddura alla lista delle freddure mostrate
    shownJokes.add(joke);
    await prefs.setStringList(_shownJokesKey, shownJokes);
    
    return joke;
  }
  
  // Resetta la lista delle freddure mostrate
  static Future<void> resetShownJokes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_shownJokesKey, []);
  }
}