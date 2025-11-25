import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Tracks if NotificationsScreen is currently on top to avoid duplicate pushes
bool notificationsScreenOpen = false;

enum NotifType { system, game, studio, community }

class IncomingNotification {
  final String id;
  final String title;
  final String body;
  final NotifType type;
  final DateTime createdAt;
  final bool read;
  final String? imageUrl;

  const IncomingNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.read,
    this.imageUrl,
  });
}

class NotificationsPage extends StatefulWidget {
  final List<IncomingNotification> items;
  final void Function(String id) onTap;
  final void Function(String id) onDelete;
  final void Function(String id, bool nextReadState) onToggleRead;

  const NotificationsPage({
    super.key,
    required this.items,
    required this.onTap,
    required this.onDelete,
    required this.onToggleRead,
  });

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  static const double leftPadding = 16.0;
  NotifType? _activeFilter;

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black.withValues(alpha: 0.6),
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF5A5A5A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Are you sure?',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Poppins')),
                    const SizedBox(height: 6),
                    const Text('You are removing your notification',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins')),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(255, 141, 131, 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(41)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Yes Remove',
                              style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.black, fontSize: 20, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = (_activeFilter == null)
  ? [...widget.items]
  : widget.items.where((n) => n.type == _activeFilter).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: const Color.fromRGBO(49, 49, 49, 1),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 92,
              child: Stack(
                children: [
                  const Center(
                    child: Text(
                      'Notification',
                      style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w600,
                        color: Colors.white, fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  Positioned(
                    left: leftPadding,
                    top: 10,
                    child: Container(
                      width: 71, height: 71,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                      child: IconButton(
                        icon: SvgPicture.asset('assets/arrow.svg', width: 36, height: 36),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50.0),
              child: Container(height: 1, color: Colors.white.withValues(alpha: 0.20)),
            ),
            const SizedBox(height: 12),
            _CategoryChips(
              active: _activeFilter,
              onSelected: (t) => setState(() => _activeFilter = t),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Builder(
                builder: (_) {
                  if (widget.items.isEmpty) {
                    return const _EmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final n = filtered[i];
                      return _NotificationTile(
                        data: n,
                        onTap: () => widget.onTap(n.id),
                        onDelete: () async {
                          final ok = await _confirmDelete(context);
                          if (ok) widget.onDelete(n.id);
                        },
                        onToggleRead: () => widget.onToggleRead(n.id, !n.read),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final NotifType? active;
  final ValueChanged<NotifType?> onSelected;
  const _CategoryChips({required this.active, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const labels = {
      null: 'All',
      NotifType.system: 'System',
      NotifType.game: 'Games',
      NotifType.studio: 'Studio',
      NotifType.community: 'Community',
    };

    List<Widget> chips = [];
    for (final entry in labels.entries) {
      final isActive = active == entry.key;
      chips.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: ChoiceChip(
            label: Text(entry.value,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white70,
                  fontFamily: 'Poppins',
                )),
            selected: isActive,
            onSelected: (_) => onSelected(entry.key),
            selectedColor: const Color.fromRGBO(147, 255, 131, 1),
            backgroundColor: const Color(0xFF2F2F2F),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(children: chips),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IncomingNotification data;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleRead;

  const _NotificationTile({
    required this.data,
    required this.onTap,
    required this.onDelete,
    required this.onToggleRead,
  });

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFF2F2F2F);
    final titleStyle = TextStyle(
      color: Colors.white,
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: data.read ? FontWeight.w500 : FontWeight.w600,
    );

    return Dismissible(
      key: ValueKey(data.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: const Color.fromRGBO(255, 141, 131, 1),
        child: const Icon(Icons.delete, color: Colors.black),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: const Color(0xFF6FCF97),
        child: Icon(
          data.read ? Icons.mark_email_unread : Icons.mark_email_read,
          color: Colors.black,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onDelete();
        } else {
          onToggleRead();
        }
        return false;
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _LeadingIconOrThumb(type: data.type, imageUrl: data.imageUrl, unread: !data.read),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  data.body,
                  style: const TextStyle(color: Colors.white70, fontFamily: 'Poppins', fontSize: 13, height: 1.35),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  _timeAgo(data.createdAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

class _LeadingIconOrThumb extends StatelessWidget {
  final NotifType type;
  final String? imageUrl;
  final bool unread;
  const _LeadingIconOrThumb({required this.type, this.imageUrl, required this.unread});

  IconData _iconFor(NotifType t) {
    switch (t) {
      case NotifType.system: return Icons.bluetooth_rounded;
      case NotifType.game: return Icons.sports_esports_rounded;
      case NotifType.studio: return Icons.brush_rounded;
      case NotifType.community: return Icons.public_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
  ? Icon(_iconFor(type), color: Colors.white70)
  : Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(_iconFor(type), color: Colors.white70),
    ),

    );

    return Stack(
      alignment: Alignment.topRight,
      children: [
        box,
        if (unread)
          Container(
            width: 10, height: 10,
            decoration: const BoxDecoration(color: Color.fromRGBO(147, 255, 131, 1), shape: BoxShape.circle),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 120),
        Icon(Icons.notifications_none, color: Colors.white24, size: 72),
        SizedBox(height: 16),
        Center(
          child: Text('No notifications yet',
              style: TextStyle(color: Colors.white70, fontFamily: 'Poppins')),
        ),
        SizedBox(height: 300),
      ],
    );
  }
}

NotifType _notifTypeFromName(String? name) {
  switch ((name ?? 'system').toLowerCase()) {
    case 'game':
      return NotifType.game;
    case 'studio':
      return NotifType.studio;
    case 'community':
      return NotifType.community;
    default:
      return NotifType.system;
  }
}

Map<String, dynamic> incomingToJson(IncomingNotification n) => {
  'id': n.id,
  'title': n.title,
  'body': n.body,
  'type': n.type.name,
  'createdAt': n.createdAt.toIso8601String(),
  'read': n.read,
  'imageUrl': n.imageUrl,
};

IncomingNotification incomingFromJson(Map<String, dynamic> j) => IncomingNotification(
  id: (j['id'] as String?) ?? DateTime.now().toIso8601String(),
  title: (j['title'] as String?) ?? '',
  body: (j['body'] as String?) ?? '',
  type: _notifTypeFromName(j['type'] as String?),
  createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ?? DateTime.now(),
  read: (j['read'] as bool?) ?? false,
  imageUrl: j['imageUrl'] as String?,
);

class NotificationStore {
  static const _prefsKey = 'pixply_notifications_v1';
  final List<IncomingNotification> _items = [];

  List<IncomingNotification> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    _items
      ..clear()
      ..addAll(list.map((s) => incomingFromJson(jsonDecode(s))));
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _items.map((n) => jsonEncode(incomingToJson(n))).toList(),
    );
  }

  Future<void> add(IncomingNotification n) async {
    _items.removeWhere((x) => x.id == n.id);
    _items.insert(0, n);
      // cap size to avoid huge prefs
  const cap = 200;
  if (_items.length > cap) {
    _items.removeRange(cap, _items.length);
  }
    await save();
  }

  Future<void> toggleRead(String id, bool next) async {
    for (var i = 0; i < _items.length; i++) {
      final n = _items[i];
      if (n.id == id) {
        _items[i] = IncomingNotification(
          id: n.id, title: n.title, body: n.body, type: n.type,
          createdAt: n.createdAt, read: next, imageUrl: n.imageUrl,
        );
        break;
      }
    }
    await save();
  }

  Future<void> delete(String id) async {
    _items.removeWhere((n) => n.id == id);
    await save();
  }
}

// Stable ID generator to dedupe the same FCM message
// across background and opened-app handlers.
String _stableMessageId(RemoteMessage msg) {
  final baseId = msg.messageId;
  if (baseId != null && baseId.isNotEmpty) return baseId;

  final sent = msg.sentTime?.millisecondsSinceEpoch;
  if (sent != null) return 'sent:$sent';

  final t = msg.notification?.title ?? '';
  final b = msg.notification?.body ?? '';
  final typ = (msg.data['type'] as String?) ?? '';
  return 'h:${t.trim()}|${b.trim()}|${typ.trim()}';
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage msg) async {
  try { await Firebase.initializeApp(); } catch (_) {}
  final prefs = await SharedPreferences.getInstance();
  const key = 'pixply_notifications_v1';
  final List<String> list = prefs.getStringList(key) ?? <String>[];
  final notif = IncomingNotification(
    id: _stableMessageId(msg),
    title: msg.notification?.title ?? '',
    body: msg.notification?.body ?? '',
    type: _notifTypeFromName(msg.data['type'] as String?),
    createdAt: DateTime.now(),
    read: false,
    imageUrl: msg.data['image'] as String?,
  );
  list.insert(0, jsonEncode(incomingToJson(notif)));
  await prefs.setStringList(key, list);
}

Future<void> _storeRemoteMessage(RemoteMessage msg) async {
  final store = NotificationStore();
  await store.load();
  final notif = IncomingNotification(
    id: _stableMessageId(msg),
    title: msg.notification?.title ?? '',
    body: msg.notification?.body ?? '',
    type: _notifTypeFromName(msg.data['type'] as String?),
    createdAt: DateTime.now(),
    read: false,
    imageUrl: msg.data['image'] as String?,
  );
  await store.add(notif);
}

Future<void> setupNotificationListeners(GlobalKey<NavigatorState> navigatorKey) async {
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    await _storeRemoteMessage(message);
    final navState = navigatorKey.currentState;
    if (navState != null && !notificationsScreenOpen) {
      navState.push(MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ));
    }
  });

  final RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    await _storeRemoteMessage(initialMessage);
    final navState = navigatorKey.currentState;
    if (navState != null && !notificationsScreenOpen) {
      navState.push(MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ));
    }
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _store = NotificationStore();
  bool _ready = false;
  StreamSubscription<RemoteMessage>? _subOnMessage;

  @override
  void initState() {
    super.initState();
    notificationsScreenOpen = true;
    _bootstrap();
  }

  @override
  void dispose() {
    _subOnMessage?.cancel(); // NEW
    notificationsScreenOpen = false;
    super.dispose();
  }
  Future<void> _bootstrap() async {
    await _store.load();
    _wireFCM();
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _ready = true);
  }

  void _wireFCM() {
    _subOnMessage = FirebaseMessaging.onMessage.listen((_) async {
      await _store.load();
      if (mounted) setState(() {});
    });

    // Future<void> _onRemote(RemoteMessage msg) async {
    // await _store.load();
    // if (mounted) setState(() {});
    // }

  FirebaseMessaging.onMessageOpenedApp.listen((_) async {
    await _store.load();
    if (mounted) setState(() {});
  });
  }


  // Future<void> _onRemote(RemoteMessage msg) async {
  //   final notif = IncomingNotification(
  //     id: msg.messageId ?? DateTime.now().toIso8601String(),
  //     title: msg.notification?.title ?? '',
  //     body: msg.notification?.body ?? '',
  //     type: _notifTypeFromName(msg.data['type'] as String?),
  //     createdAt: DateTime.now(),
  //     read: false,
  //     imageUrl: msg.data['image'] as String?,
  //   );
  //   await _store.add(notif);
  //   if (mounted) setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return NotificationsPage(
      items: _store.items,
      onTap: (id) {},
      onDelete: (id) async {
        await _store.delete(id);
        if (mounted) setState(() {});
      },
      onToggleRead: (id, next) async {
        await _store.toggleRead(id, next);
        if (mounted) setState(() {});
      },
    );
  }
}
