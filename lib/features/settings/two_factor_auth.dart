import 'package:swappro/barrel.dart';

class TwoFactorAuthPage extends StatefulWidget {
  const TwoFactorAuthPage({super.key});

  @override
  State<TwoFactorAuthPage> createState() => _TwoFactorAuthPageState();
}

class _TwoFactorAuthPageState extends State<TwoFactorAuthPage> {
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await context.read<ApiService>().getUserProfile();
      if (!mounted) return;
      final raw = user['two_factor_enabled'] ?? user['is_2fa_enabled'];
      setState(() => _enabled = raw is bool ? raw : false);
    } catch (_) {
      // Keep default off when profile has no 2FA field yet.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(bool value) async {
    if (_saving) return;
    final prev = _enabled;
    setState(() => _enabled = value);
    setState(() => _saving = true);
    try {
      // Backend 2FA toggle endpoint can be wired here when available.
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      context.showAppSnackBar(
        value
            ? 'Two-factor authentication will be available soon'
            : 'Two-factor authentication disabled',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _enabled = prev);
      context.showAppSnackBar('Could not update 2FA: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      title: '2 Factor Auth',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add an extra layer of security to your account.',
              style: AppTypography.style(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: SettingsScreenStyle.subtleText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SettingsMenuCard(
              child: Column(
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(minHeight: 2),
                    )
                  else
                    InkWell(
                      onTap: _saving ? null : () => _toggle(!_enabled),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.security_outlined,
                              size: 20,
                              color: SettingsScreenStyle.gold,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Enable 2FA',
                                style: SettingsScreenStyle.menuTitleStyle(),
                              ),
                            ),
                            SettingsToggleSwitch(
                              value: _enabled,
                              enabled: !_saving,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: SettingsScreenStyle.divider,
                    indent: 16,
                    endIndent: 16,
                  ),
                  SettingsMenuTile(
                    title: 'Authenticator app',
                    subtitle: 'Use an app like Google Authenticator',
                    icon: Icons.phonelink_lock_outlined,
                    onTap: () => context.showAppSnackBar('Coming soon'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
