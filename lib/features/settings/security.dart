import 'package:swappro/barrel.dart';

class Security extends StatelessWidget {
  const Security({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      title: 'Password & Security',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: SettingsMenuCard(
          child: Column(
            children: [
              SettingsMenuTile(
                title: 'Change Password',
                icon: Icons.lock_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RecoverAccount()),
                  );
                },
              ),
              SettingsMenuTile(
                title: '2 Factor Authentication',
                icon: Icons.security_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TwoFactorAuthPage()),
                  );
                },
                showDivider: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
