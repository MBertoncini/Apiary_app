import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/theme_constants.dart';
import '../../models/notifica.dart';
import '../../services/notification_navigator.dart';
import '../../services/notification_polling_service.dart';

/// Centro notifiche dell'utente. Mostra sia notifiche legacy (inviti,
/// scadenze) sia comunicazioni broadcast dagli admin con body HTML ricco.
///
/// UI moderna a card raggruppate per data, con badge icona colorati per
/// categoria, evidenziazione delle non lette e foglio di dettaglio rifinito.
class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifiche'),
        actions: [
          Consumer<NotificationPollingService>(
            builder: (_, svc, __) {
              final enabled = svc.unreadCount > 0;
              return IconButton(
                tooltip: 'Segna tutte come lette',
                icon: const Icon(Icons.done_all_rounded),
                color: enabled ? Colors.white : Colors.white38,
                onPressed: enabled ? svc.markAllAsRead : null,
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationPollingService>(
        builder: (context, svc, _) {
          return RefreshIndicator(
            color: ThemeConstants.primaryColor,
            onRefresh: svc.refresh,
            child: _buildBody(context, svc),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationPollingService svc) {
    if (svc.isLoading && svc.notifiche.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: ThemeConstants.primaryColor),
      );
    }
    if (svc.notifiche.isEmpty) {
      return const _EmptyState();
    }

    final groups = _groupByDate(svc.notifiche);
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: groups.length,
      itemBuilder: (_, i) {
        final g = groups[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(label: g.label, count: g.unreadCount),
            ...g.items.map((n) => _NotificaCard(notifica: n)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  /// Raggruppa le notifiche in fasce temporali leggibili.
  List<_DateGroup> _groupByDate(List<Notifica> items) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final buckets = <String, List<Notifica>>{
      'Oggi': [],
      'Ieri': [],
      'Ultimi 7 giorni': [],
      'Precedenti': [],
    };

    for (final n in items) {
      DateTime? dt;
      try {
        dt = DateTime.parse(n.dataCreazione).toLocal();
      } catch (_) {}
      final day = dt == null ? null : DateTime(dt.year, dt.month, dt.day);
      String key;
      if (day == null) {
        key = 'Precedenti';
      } else if (day == today) {
        key = 'Oggi';
      } else if (day == yesterday) {
        key = 'Ieri';
      } else if (day.isAfter(weekAgo)) {
        key = 'Ultimi 7 giorni';
      } else {
        key = 'Precedenti';
      }
      buckets[key]!.add(n);
    }

    return buckets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => _DateGroup(
              label: e.key,
              items: e.value,
              unreadCount: e.value.where((n) => !n.letta).length,
            ))
        .toList(growable: false);
  }
}

class _DateGroup {
  final String label;
  final List<Notifica> items;
  final int unreadCount;
  const _DateGroup({
    required this.label,
    required this.items,
    required this.unreadCount,
  });
}

// ─────────────────────────────────────────────────────────────────────────
// Stile per categoria: ogni tipo ha icona e colore dedicati.
// ─────────────────────────────────────────────────────────────────────────

class _NotificaStyle {
  final IconData icon;
  final Color color;
  final String label;
  const _NotificaStyle(this.icon, this.color, this.label);

  static _NotificaStyle of(Notifica n) {
    switch (n.tipo) {
      case 'broadcast':
        return const _NotificaStyle(
            Icons.campaign_rounded, ThemeConstants.primaryColor, 'Comunicazione');
      case 'invito_gruppo':
        return const _NotificaStyle(
            Icons.group_add_rounded, Color(0xFF3F7FB5), 'Invito');
      case 'membro_aggiunto':
      case 'membro_rimosso':
      case 'invito_accettato':
      case 'invito_rifiutato':
        return const _NotificaStyle(
            Icons.groups_rounded, Color(0xFF3F7FB5), 'Gruppo');
      case 'controllo_scaduto':
        return const _NotificaStyle(
            Icons.event_busy_rounded, Color(0xFFC0622A), 'Controllo');
      case 'trattamento_scaduto':
      case 'trattamento_promemoria':
        return const _NotificaStyle(
            Icons.medical_services_rounded, Color(0xFF7E57A8), 'Trattamento');
      case 'fioritura_vicina':
        return const _NotificaStyle(
            Icons.local_florist_rounded, ThemeConstants.successColor, 'Fioritura');
      case 'regina_assente':
        return const _NotificaStyle(
            Icons.warning_amber_rounded, ThemeConstants.errorColor, 'Avviso');
      default:
        return const _NotificaStyle(Icons.notifications_rounded,
            ThemeConstants.secondaryColor, 'Notifica');
    }
  }

  /// Il colore prevale sulla priorità: alta → errore, bassa → tenue.
  Color resolvedColor(String priorita) {
    if (priorita == 'alta') return ThemeConstants.errorColor;
    return color;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Header di sezione (Oggi / Ieri / …)
// ─────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: ThemeConstants.textSecondaryColor,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: ThemeConstants.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Card singola notifica
// ─────────────────────────────────────────────────────────────────────────

class _NotificaCard extends StatelessWidget {
  final Notifica notifica;
  const _NotificaCard({required this.notifica});

  @override
  Widget build(BuildContext context) {
    final isUnread = !notifica.letta;
    final style = _NotificaStyle.of(notifica);
    final accent = style.resolvedColor(notifica.priorita);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isUnread
            ? accent.withOpacity(0.06)
            : ThemeConstants.cardColor,
        borderRadius: BorderRadius.circular(16),
        elevation: isUnread ? 0 : 1,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUnread
                    ? accent.withOpacity(0.35)
                    : ThemeConstants.dividerColor.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barretta d'accento per le non lette
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isUnread ? 4 : 0,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _IconBadge(icon: style.icon, color: accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notifica.titolo,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.2,
                                          fontWeight: isUnread
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color:
                                              ThemeConstants.textPrimaryColor,
                                        ),
                                      ),
                                    ),
                                    if (isUnread) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (notifica.messaggio.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    notifica.messaggio,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color:
                                          ThemeConstants.textSecondaryColor,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _CategoryChip(
                                        label: style.label, color: accent),
                                    const SizedBox(width: 8),
                                    if (notifica.priorita == 'alta')
                                      const _PriorityChip(),
                                    const Spacer(),
                                    Icon(Icons.schedule_rounded,
                                        size: 13,
                                        color: ThemeConstants
                                            .textSecondaryColor
                                            .withOpacity(0.7)),
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatRelative(notifica.dataCreazione),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: ThemeConstants
                                            .textSecondaryColor
                                            .withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final svc = context.read<NotificationPollingService>();
    if (!notifica.letta) {
      await svc.markAsRead(notifica.id);
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificaDetailSheet(notifica: notifica),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.22), color.withOpacity(0.10)],
        ),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ThemeConstants.errorColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded,
              size: 12, color: ThemeConstants.errorColor),
          SizedBox(width: 2),
          Text(
            'Urgente',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ThemeConstants.errorColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 110),
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ThemeConstants.primaryColor.withOpacity(0.10),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: ThemeConstants.primaryColor.withOpacity(0.7),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Tutto tranquillo',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: ThemeConstants.textPrimaryColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Non hai nessuna notifica.\nNovità e comunicazioni appariranno qui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: ThemeConstants.textSecondaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Bottom sheet di dettaglio
// ─────────────────────────────────────────────────────────────────────────

class _NotificaDetailSheet extends StatelessWidget {
  final Notifica notifica;
  const _NotificaDetailSheet({required this.notifica});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _NotificaStyle.of(notifica);
    final accent = style.resolvedColor(notifica.priorita);
    final hasImage =
        notifica.immagineUrl != null && notifica.immagineUrl!.isNotEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: ThemeConstants.backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Maniglia
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                decoration: BoxDecoration(
                  color: ThemeConstants.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  children: [
                    // Intestazione: badge + categoria + data
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IconBadge(icon: style.icon, color: accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _CategoryChip(
                                      label: style.label, color: accent),
                                  if (notifica.priorita == 'alta') ...[
                                    const SizedBox(width: 8),
                                    const _PriorityChip(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatFull(notifica.dataCreazione),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: ThemeConstants.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      notifica.titolo,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ThemeConstants.textPrimaryColor,
                        height: 1.2,
                      ),
                    ),
                    if (notifica.mittenteUsername != null &&
                        notifica.mittenteUsername!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 15,
                              color: ThemeConstants.textSecondaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'da ${notifica.mittenteUsername}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: ThemeConstants.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (hasImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            notifica.immagineUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: ThemeConstants.primaryColor10,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ThemeConstants.primaryColor,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    if (hasImage) const SizedBox(height: 16),
                    // Corpo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ThemeConstants.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              ThemeConstants.dividerColor.withOpacity(0.6),
                        ),
                      ),
                      child: notifica.hasHtml
                          ? Html(
                              data: notifica.messaggioHtml,
                              onLinkTap: (url, _, __) {
                                if (url != null) {
                                  launchUrl(Uri.parse(url),
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                            )
                          : Text(
                              notifica.messaggio,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: ThemeConstants.textPrimaryColor,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    if (notifica.linkRoute.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text(
                            'Apri nell\'app',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            NotificationNavigator.navigate(
                              linkRoute: notifica.linkRoute,
                              linkParam: notifica.linkParam,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Formattazione date (helper top-level condivisi)
// ─────────────────────────────────────────────────────────────────────────

String _formatRelative(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'adesso';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min fa';
    if (diff.inHours < 24) return '${diff.inHours} h fa';
    if (diff.inDays < 7) return '${diff.inDays} g fa';
    return DateFormat('dd/MM/y').format(dt);
  } catch (_) {
    return iso;
  }
}

const _mesiIt = [
  '', 'gennaio', 'febbraio', 'marzo', 'aprile', 'maggio', 'giugno',
  'luglio', 'agosto', 'settembre', 'ottobre', 'novembre', 'dicembre',
];

String _formatFull(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final ora = DateFormat('HH:mm').format(dt);
    return '${dt.day} ${_mesiIt[dt.month]} ${dt.year} alle $ora';
  } catch (_) {
    return iso;
  }
}
