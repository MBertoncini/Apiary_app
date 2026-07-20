import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notifica.dart';
import 'api_service.dart';
import 'notification_service.dart';

/// Mantiene in memoria il centro notifiche dell'utente e fa polling leggero
/// del backend per le comunicazioni broadcast inviate dagli admin.
///
/// Strategia volutamente semplice — niente WebSocket, niente FCM:
///  - `refresh()` viene chiamato all'`start()`, al resume dell'app e ogni
///    [_pollInterval] mentre l'app è in foreground.
///  - Le notifiche nuove (id > `last_seen_id` salvato in SharedPreferences)
///    vengono ri-emesse come local notification così l'utente si accorge
///    anche se il centro notifiche non è aperto.
///
/// È un [ChangeNotifier]: gli screen possono ascoltare per badge counter o
/// per la lista in tempo reale.
class NotificationPollingService extends ChangeNotifier
    with WidgetsBindingObserver {
  final ApiService _api;
  final NotificationService _local;

  static const _lastSeenIdKey = 'notifiche_last_seen_id';
  static const _pollInterval = Duration(minutes: 30);

  List<Notifica> _notifiche = const [];
  int _unreadCount = 0;
  int _lastSeenId = 0;
  Timer? _timer;
  bool _isLoading = false;
  bool _started = false;
  DateTime? _lastFetch;

  NotificationPollingService(this._api, this._local);

  List<Notifica> get notifiche => List.unmodifiable(_notifiche);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  DateTime? get lastFetch => _lastFetch;

  /// Avvia il polling. Chiamare dopo il login (auth ok) — è idempotente.
  Future<void> start() async {
    if (_started) return;
    _started = true;

    final prefs = await SharedPreferences.getInstance();
    _lastSeenId = prefs.getInt(_lastSeenIdKey) ?? 0;

    final binding = SchedulerBinding.instance;
    WidgetsBinding.instance.addObserver(this);

    // Prima refresh dopo il primo frame, così non blocca il boot.
    binding.addPostFrameCallback((_) => refresh());
    _scheduleNext();
  }

  /// Ferma il polling. Da chiamare a logout.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
    _notifiche = const [];
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started) return;
    if (state == AppLifecycleState.resumed) {
      refresh();
      _scheduleNext();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(_pollInterval, () {
      refresh();
      _scheduleNext();
    });
  }

  /// Forza una refresh dal backend. È usata anche da pull-to-refresh.
  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final raw = await _api.getNotifiche();
      final list = raw
          .map((j) => Notifica.fromJson(j as Map<String, dynamic>))
          .toList(growable: false);
      _notifiche = list;
      _unreadCount = list.where((n) => !n.letta).length;
      _lastFetch = DateTime.now();

      await _emitLocalForNew(list);
    } catch (e) {
      debugPrint('NotificationPolling.refresh error → $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Per ogni notifica con id > last_seen e non letta, mostra una local
  /// notification e avanza il puntatore. Idempotente: se l'utente ha già
  /// visto quella notifica, non viene ri-mostrata.
  Future<void> _emitLocalForNew(List<Notifica> list) async {
    if (list.isEmpty) return;
    final newOnes =
        list.where((n) => n.id > _lastSeenId && !n.letta).toList(growable: false);
    for (final n in newOnes) {
      await _local.showNotification(
        id: n.id, // id del backend = id locale (univoco)
        title: n.titolo,
        body: n.messaggio.isNotEmpty ? n.messaggio : ' ',
        payload: 'notifica:${n.id}',
        channelId: 'broadcast_channel',
      );
    }
    final maxId = list.map((n) => n.id).fold<int>(0, (a, b) => a > b ? a : b);
    if (maxId > _lastSeenId) {
      _lastSeenId = maxId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSeenIdKey, maxId);
    }
  }

  /// Marca una notifica come letta — ottimisticamente in locale + push al
  /// server. Se il server fallisce, il prossimo refresh allineerà di nuovo.
  Future<void> markAsRead(int id) async {
    final idx = _notifiche.indexWhere((n) => n.id == id);
    if (idx < 0 || _notifiche[idx].letta) return;
    final updated = List<Notifica>.of(_notifiche);
    updated[idx] = updated[idx].copyWith(letta: true);
    _notifiche = updated;
    _unreadCount = (_unreadCount - 1).clamp(0, 1 << 31);
    notifyListeners();
    try {
      await _api.markNotificaRead(id);
    } catch (e) {
      debugPrint('NotificationPolling.markAsRead error → $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;
    _notifiche =
        _notifiche.map((n) => n.copyWith(letta: true)).toList(growable: false);
    _unreadCount = 0;
    notifyListeners();
    try {
      await _api.markAllNotificheRead();
    } catch (e) {
      debugPrint('NotificationPolling.markAllAsRead error → $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
