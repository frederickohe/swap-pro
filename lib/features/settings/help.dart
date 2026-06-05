import 'package:swappro/barrel.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@useswappro.com',
      query: 'subject=Help Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://www.useswappro.com');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenScaffold(
      title: 'Help & Support',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
        child: Column(
          children: [
            SettingsMenuTile(
              title: 'Email Support',
              subtitle: 'support@useswappro.com',
              icon: Icons.email_outlined,
              onTap: _launchEmail,
            ),
            SettingsMenuTile(
              title: 'Our Website',
              subtitle: 'www.useswappro.com',
              icon: Icons.language_outlined,
              onTap: _launchWebsite,
              showDivider: true,
            ),
          ],
        ),
      ),
    );
  }
}
