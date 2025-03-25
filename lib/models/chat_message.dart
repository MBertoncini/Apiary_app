// lib/models/chat_message.dart
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool hasChart;         // Indica se il messaggio contiene un grafico
  final String? chartType;     // Tipo di grafico (line, bar, etc.)
  final Map<String, dynamic>? chartData;  // Dati per il grafico
  final Map<String, dynamic>? metadata;   // Added metadata field based on copyWith method
  
  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.hasChart = false,
    this.chartType,
    this.chartData,
    this.metadata,
  });

  // Crea una copia del messaggio con attributi potenzialmente modificati
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      hasChart: this.hasChart,
      chartType: this.chartType,
      chartData: this.chartData,
    );
  }

  // Factory constructor per deserializzare da JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata'] as Map) 
          : null,
      hasChart: json['hasChart'] as bool? ?? false,
      chartType: json['chartType'] as String?,
      chartData: json['chartData'] != null
          ? Map<String, dynamic>.from(json['chartData'] as Map)
          : null,
    );
  }

  // Serializza in JSON
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'hasChart': hasChart,
      'chartType': chartType,
      'chartData': chartData,
    };
  }
}