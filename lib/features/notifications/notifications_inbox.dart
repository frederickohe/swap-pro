import 'package:swappro/barrel.dart';
import 'models/app_notification.dart';

class NotificationsInboxPage extends StatefulWidget {
  const NotificationsInboxPage({super.key});

  @override
  State<NotificationsInboxPage> createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends State<NotificationsInboxPage> {
  late Future<List<AppNotification>> _future;
  final Set<String> _markingIds = {};

  @override
  void initState() {
    super.initState();
    _future = _loadUnread();
  }

  Future<List<AppNotification>> _loadUnread() {
    return context.read<ApiService>().getUnreadNotifications();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadUnread();
    });
    await _future;
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (_markingIds.contains(notification.id)) return;
    setState(() => _markingIds.add(notification.id));
    try {
      await context.read<ApiService>().markNotificationAsRead(notification.id);
      if (!mounted) return;
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not mark notification as read',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w300),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _markingIds.remove(notification.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DecoratedBox(
        decoration: ManageScreenStyle.homeDashboardBodyDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ManageScreenBackButton(),
                    Text(
                      'Notifications',
                      style: ManageScreenStyle.headerTitleStyle(),
                    ),
                    const SizedBox(width: 48, height: 48),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: FutureBuilder<List<AppNotification>>(
                    future: _future,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: SwapproLoadingIndicator());
                      }
                      if (snap.hasError) {
                        return Center(
                          child: Text(
                            'Failed to load notifications',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        );
                      }

                      final items = snap.data ?? const [];
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            'No notifications yet',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final n = items[i];
                            final created = n.createdAt;
                            final subtitle = [
                              if (created != null)
                                '${created.toLocal()}'.split('.').first,
                            ].join('\n');
                            final marking = _markingIds.contains(n.id);

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF3F1163),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(top: 6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          n.displayText.isNotEmpty
                                              ? n.displayText
                                              : n.title,
                                          style: GoogleFonts.montserrat(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        if (subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            subtitle,
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: marking
                                        ? null
                                        : () => _markAsRead(n),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFFA855F7),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: marking
                                        ? const SwapproLoadingIndicator(
                                            size: 16,
                                          )
                                        : Text(
                                            'Mark read',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
