class Validators {
  // Validatore per campi non vuoti
  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obbligatorio';
    }
    return null;
  }
  
  // Validatore per email
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci un indirizzo email';
    }
    
    final RegExp emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (!emailRegExp.hasMatch(value)) {
      return 'Inserisci un indirizzo email valido';
    }
    
    return null;
  }
  
  // Validatore per password
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci una password';
    }
    
    if (value.length < 8) {
      return 'La password deve contenere almeno 8 caratteri';
    }
    
    return null;
  }
  
  // Validatore per numeri interi
  static String? integer(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci un valore';
    }
    
    if (int.tryParse(value) == null) {
      return 'Inserisci un numero intero valido';
    }
    
    return null;
  }
  
  // Validatore per numeri interi positivi
  static String? positiveInteger(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci un valore';
    }
    
    final intValue = int.tryParse(value);
    
    if (intValue == null) {
      return 'Inserisci un numero intero valido';
    }
    
    if (intValue < 0) {
      return 'Inserisci un numero intero positivo';
    }
    
    return null;
  }
  
  // Validatore per numeri decimali
  static String? decimal(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci un valore';
    }
    
    if (double.tryParse(value) == null) {
      return 'Inserisci un numero valido';
    }
    
    return null;
  }
  
  // Validatore per coordinate di latitudine
  static String? latitude(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Latitudine opzionale
    }
    
    final doubleValue = double.tryParse(value);
    
    if (doubleValue == null) {
      return 'Inserisci un numero valido';
    }
    
    if (doubleValue < -90 || doubleValue > 90) {
      return 'La latitudine deve essere compresa tra -90 e 90';
    }
    
    return null;
  }
  
  // Validatore per coordinate di longitudine
  static String? longitude(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Longitudine opzionale
    }
    
    final doubleValue = double.tryParse(value);
    
    if (doubleValue == null) {
      return 'Inserisci un numero valido';
    }
    
    if (doubleValue < -180 || doubleValue > 180) {
      return 'La longitudine deve essere compresa tra -180 e 180';
    }
    
    return null;
  }
  
  // Validatore per date in formato yyyy-MM-dd
  static String? dateIso(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci una data';
    }
    
    final RegExp dateRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    
    if (!dateRegExp.hasMatch(value)) {
      return 'Formato data non valido (YYYY-MM-DD)';
    }
    
    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();
      
      if (date.isAfter(now)) {
        return 'La data non può essere nel futuro';
      }
    } catch (e) {
      return 'Data non valida';
    }
    
    return null;
  }
}