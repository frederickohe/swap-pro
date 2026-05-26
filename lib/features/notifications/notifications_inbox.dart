import 'package:swappro/barrel.dart';

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
      context.showAppSnackBar('Could not mark notification as read');
    } finally {
      if (mounted) {
        setState(() => _markingIds.remove(notification.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      title: 'Notifications',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                  style: AppTypography.style(
                    color: SettingsScreenStyle.subtleText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              );
            }

            final items = snap.data ?? const [];
            if (items.isEmpty) {
              return Center(
                child: Text(
                  'No notifications yet',
                  style: AppTypography.style(
                    color: SettingsScreenStyle.subtleText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
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
                      color: SettingsScreenStyle.backButtonBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SettingsScreenStyle.cardBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFD5F4A),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.displayText.isNotEmpty
                                    ? n.displayText
                                    : n.title,
                                style: AppTypography.style(
                                  color: SettingsScreenStyle.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (subtitle.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  subtitle,
                                  style: AppTypography.style(
                                    color: SettingsScreenStyle.subtleText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: marking ? null : () => _markAsRead(n),
                          style: TextButton.styleFrom(
                            foregroundColor: SettingsScreenStyle.gold,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: marking
                              ? const SwapproLoadingIndicator(size: 16)
                              : Text(
                                  'Mark read',
                                  style: AppTypography.style(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: SettingsScreenStyle.gold,
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
    );
  }
}
