import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:apiary_app/constants/api_constants.dart';
import 'package:apiary_app/models/user.dart';
import 'package:apiary_app/services/ai_quota_service.dart';
import 'package:apiary_app/services/api_service.dart';
import 'package:apiary_app/services/auth_token_provider.dart';

class _NoAuth implements AuthTokenProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('auth non usata nei test');
}

/// ApiService finto: risponde a GET /ai/quota/ con [quota] e registra i POST.
class _FakeApi extends ApiService {
  _FakeApi(this.quota) : super(_NoAuth());

  Map<String, dynamic> quota;
  final List<String> posts = [];

  @override
  Future<dynamic> get(String endpoint) async {
    if (endpoint == ApiConstants.aiQuotaUrl) return quota;
    throw StateError('GET inatteso: $endpoint');
  }

  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    posts.add(endpoint);
    return <String, dynamic>{};
  }
}

Map<String, dynamic> _quota({
  int chat = 0,
  int voice = 0,
  int stats = 0,
  int systemRequests = 0,
  bool statsPerTier = true,
}) =>
    {
      'daily_limit': 1500,
      'all_tier_limits': {
        'free': {
          'chat': 10,
          'voice': 5,
          'total': 15,
          if (statsPerTier) 'stats': 10,
        },
      },
      'usage': {
        'chat_today': chat,
        'voice_today': voice,
        'total_today': chat + voice,
        if (statsPerTier) 'stats_today': stats,
      },
      'personal': {'requests_today': chat + voice, 'reset_at': null},
      'system': {'requests_today': systemRequests, 'reset_at': null},
    };

Future<AiQuotaService> _service(_FakeApi api) async {
  final service = AiQuotaService(api);
  service.setTier(AiTier.free);
  await service.refresh();
  return service;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('chiave Gemini personale', () {
    test('senza chiave la chat si blocca al limite del tier', () async {
      final service = await _service(_FakeApi(_quota(chat: 10)));
      expect(service.canCall(AiFeature.chat), isFalse);
    });

    test('con la chiave chat e voce non sono limitate dal tier', () async {
      final service = await _service(_FakeApi(_quota(chat: 10, voice: 5)));
      service.setHasPersonalGeminiKey(true);
      expect(service.canCall(AiFeature.chat), isTrue);
      expect(service.canCall(AiFeature.voice), isTrue);
    });

    test('una chiamata riuscita non marca la quota come esaurita', () async {
      final api = _FakeApi(_quota(chat: 10));
      final service = await _service(api);
      service.setHasPersonalGeminiKey(true);

      service.recordOptimisticCall(AiFeature.chat);
      await service.recordChatCallToBackend();

      expect(service.canCall(AiFeature.chat), isTrue);
      expect(service.usedFor(AiFeature.chat), 10);
      // Nessuna telemetria: la chiamata non consuma il tier.
      expect(api.posts, isEmpty);
    });
  });

  group('quota statistiche', () {
    test('usa il contatore per utente quando il backend lo espone', () async {
      // 900 richieste globali sulla chiave di sistema non devono comparire
      // come utilizzo dell\'utente.
      final service =
          await _service(_FakeApi(_quota(stats: 3, systemRequests: 900)));
      expect(service.limitFor(AiFeature.stats), 10);
      expect(service.usedFor(AiFeature.stats), 3);
      expect(service.canCall(AiFeature.stats), isTrue);
    });

    test('si blocca al limite del tier', () async {
      final service = await _service(_FakeApi(_quota(stats: 10)));
      expect(service.blockStatus(AiFeature.stats), AiQuotaBlock.exceeded);
    });

    test('con un backend vecchio resta il pool di sistema', () async {
      final service = await _service(
          _FakeApi(_quota(systemRequests: 40, statsPerTier: false)));
      expect(service.limitFor(AiFeature.stats), 1500);
      expect(service.usedFor(AiFeature.stats), 40);
    });
  });

  test('un mark di esaurimento non sopravvive al reset di mezzanotte UTC',
      () async {
    final service = await _service(_FakeApi(_quota()));
    final now = DateTime.now().toUtc();
    final ieri = DateTime.utc(now.year, now.month, now.day)
        .subtract(const Duration(minutes: 5));

    service.debugSetExceededAt(AiFeature.chat, ieri);
    expect(service.canCall(AiFeature.chat), isTrue);

    // Un mark di oggi invece resta fino al prossimo reset.
    service.markExceeded(AiFeature.voice);
    expect(service.canCall(AiFeature.voice), isFalse);
  });
}
