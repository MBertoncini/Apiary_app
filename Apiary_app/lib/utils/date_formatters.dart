import 'package:intl/intl.dart';

class DateFormatter {
  // Formatta una stringa data in formato 'yyyy-MM-dd' in 'dd/MM/yyyy'
  static String formatDate(String date) {
    if (date.isEmpty) return '';
    
    try {
      final DateTime dateTime = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return date;
    }
  }
  
  // Formatta una stringa data in formato 'yyyy-MM-dd' in formato personalizzato
  static String formatDateCustom(String date, String format) {
    if (date.isEmpty) return '';
    
    try {
      final DateTime dateTime = DateTime.parse(date);
      return DateFormat(format).format(dateTime);
    } catch (e) {
      return date;
    }
  }
  
  // Formatta una stringa datetime in formato 'yyyy-MM-ddTHH:mm:ss' in 'dd/MM/yyyy HH:mm'
  static String formatDateTime(String dateTime) {
    if (dateTime.isEmpty) return '';
    
    try {
      final DateTime dt = DateTime.parse(dateTime);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dateTime;
    }
  }
  
  // Converte DateTime in stringa formato ISO ('yyyy-MM-dd')
  static String toIsoDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
  
  // Converte una data in formato italiano ('dd/MM/yyyy') in formato ISO ('yyyy-MM-dd')
  static String italianToIsoDate(String italianDate) {
    if (italianDate.isEmpty) return '';
    
    try {
      final DateFormat italianFormat = DateFormat('dd/MM/yyyy');
      final DateTime date = italianFormat.parse(italianDate);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return italianDate;
    }
  }
  
  // Calcola la differenza in giorni tra due date
  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
  
  // Verifica se una data è oggi
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
  
  // Restituisce il nome del mese in italiano
  static String getMonthName(int month) {
    const months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    
    if (month < 1 || month > 12) {
      return '';
    }
    
    return months[month - 1];
  }
  
  // Restituisce il numero di giorni in un mese
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}