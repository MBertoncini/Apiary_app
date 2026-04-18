// lib/models/user.dart

/// Tier AI disponibili — corrispondono ai valori nel backend Django.
enum AiTier {
  free,
  apicoltore,
  professionale;

  static AiTier fromString(String? value) {
    switch (value) {
      case 'apicoltore':
        return AiTier.apicoltore;
      case 'professionale':
        return AiTier.professionale;
      default:
        return AiTier.free;
    }
  }

  String get label {
    switch (this) {
      case AiTier.free:
        return 'Free';
      case AiTier.apicoltore:
        return 'Apicoltore';
      case AiTier.professionale:
        return 'Professionale';
    }
  }

  /// Limiti giornalieri di fallback — usati SOLO se il backend non ha ancora
  /// risposto. La fonte autoritativa è `GET /ai/quota/` → `all_tier_limits`.
  static const Map<String, ({int chat, int voice, int total})> _fallbackLimits = {
    'free':          (chat: 10,  voice: 5,   total: 15),
    'apicoltore':    (chat: 30,  voice: 30,  total: 60),
    'professionale': (chat: 200, voice: 100, total: 300),
  };

  ({int chat, int voice, int total}) get fallbackLimits =>
      _fallbackLimits[name] ?? (chat: 10, voice: 5, total: 15);

  /// Risolve i limiti: preferisce quelli del backend se disponibili.
  ({int chat, int voice, int total}) resolvedLimits(
      Map<String, dynamic>? allTierLimits) {
    if (allTierLimits != null && allTierLimits.containsKey(name)) {
      final m = Map<String, dynamic>.from(allTierLimits[name] as Map);
      return (
        chat:  (m['chat']  as num?)?.toInt() ?? fallbackLimits.chat,
        voice: (m['voice'] as num?)?.toInt() ?? fallbackLimits.voice,
        total: (m['total'] as num?)?.toInt() ?? fallbackLimits.total,
      );
    }
    return fallbackLimits;
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final DateTime? dateJoined;
  final bool isActive;
  final String geminiApiKey;
  final AiTier aiTier;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.dateJoined,
    required this.isActive,
    this.geminiApiKey = '',
    this.aiTier = AiTier.free,
  });

  // Proprietà calcolata per il nome completo
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else {
      return username;
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profileImage: json['profile_image'],
      dateJoined: json['date_joined'] != null
          ? DateTime.tryParse(json['date_joined'].toString())
          : null,
      isActive: json['is_active'] ?? true,
      geminiApiKey: json['gemini_api_key'] ?? '',
      aiTier: AiTier.fromString(json['ai_tier']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'profile_image': profileImage,
      'date_joined': dateJoined?.toIso8601String(),
      'is_active': isActive,
      'gemini_api_key': geminiApiKey,
      'ai_tier': aiTier.name,
    };
  }
}