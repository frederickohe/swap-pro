import 'package:swappro/barrel.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final ApiService _apiService;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool showNotifications = true;
  bool smsNotifications = true;
  String sound = 'Pulse';

  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiService>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _apiService.getUserProfile();
      if (!mounted) return;

      final inApp =
          user['in_app_notification'] ?? user['in_app_notifications'];
      final sms =
          user['sms_notification'] ??
          user['sms_notifications'] ??
          user['sms_nofiticaitons'];

      setState(() {
        showNotifications = inApp is bool ? inApp : true;
        smsNotifications = sms is bool ? sms : true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _persist({
    bool? inAppNotifications,
    bool? smsNotifications,
    required VoidCallback rollback,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await _apiService.patchMyNotificationSettings(
        inAppNotification: inAppNotifications,
        smsNotification: smsNotifications,
      );

      final updated = await _apiService.getUserProfile();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(updated));
      } catch (_) {}
    } catch (e) {
      rollback();
      if (!mounted) return;
      context.showAppSnackBar('Failed to update notification settings: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      title: 'Notifications',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: SettingsMenuCard(
          child: Column(
            children: [
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_error != null && _error!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    _error!,
                    style: AppTypography.style(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
              _PreferenceSwitchTile(
                title: 'Show Notifications',
                value: showNotifications,
                enabled: !(_loading || _saving),
                onChanged: (val) {
                  final prev = showNotifications;
                  setState(() => showNotifications = val);
                  _persist(
                    inAppNotifications: val,
                    rollback: () =>
                        setState(() => showNotifications = prev),
                  );
                },
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: SettingsScreenStyle.divider,
                indent: 16,
                endIndent: 16,
              ),
              SettingsMenuTile(
                title: 'Sound',
                onTap: () {},
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sound,
                      style: SettingsScreenStyle.menuSubtitleStyle(),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: SettingsScreenStyle.menuText,
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: SettingsScreenStyle.divider,
                indent: 16,
                endIndent: 16,
              ),
              _PreferenceSwitchTile(
                title: 'SMS Notifications',
                value: smsNotifications,
                enabled: !(_loading || _saving),
                onChanged: (val) {
                  final prev = smsNotifications;
                  setState(() => smsNotifications = val);
                  _persist(
                    smsNotifications: val,
                    rollback: () =>
                        setState(() => smsNotifications = prev),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceSwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _PreferenceSwitchTile({
    required this.title,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: SettingsScreenStyle.menuTitleStyle()),
            ),
            SettingsToggleSwitch(value: value, enabled: enabled),
          ],
        ),
      ),
    );
  }
}
