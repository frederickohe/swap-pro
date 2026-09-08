import 'package:swappro/barrel.dart';

class UserAvatar extends StatelessWidget {
  final double size;
  final String? avatarUrl;
  final String? initials;
  final VoidCallback? onTap;

  /// When true (e.g. white or light screen background), matches "Your listings"
  /// — no border, grey placeholder with gold person icon.
  /// Otherwise initials are white on a bordered circle (dark / gold screens).
  final bool onLightBackground;

  const UserAvatar({
    this.size = SettingsScreenStyle.chromeButtonSize,
    this.avatarUrl,
    this.initials,
    this.onTap,
    this.onLightBackground = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String? url = avatarUrl;
        String chars = initials ?? 'U';

        if (url == null && state is Authenticated) {
          final u = state.user;
          chars = (u['fullname'] ?? u['email'] ?? 'User')
              .toString()
              .trim()
              .split(' ')
              .first
              .substring(0, 1)
              .toUpperCase();
          url = (u['profile_picture_url'] ??
                  u['avatar'] ??
                  u['avatar_url'] ??
                  u['photo'] ??
                  u['photo_url'])
              ?.toString();
          if (url != null && url.trim().isEmpty) url = null;
        }

        final child = onLightBackground
            ? _buildLightAvatar(url, chars)
            : _buildDarkAvatar(url, chars);

        return GestureDetector(
          onTap:
              onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Profile()),
                );
              },
          child: child,
        );
      },
    );
  }

  Widget _buildLightAvatar(String? url, String chars) {
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url != null
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _lightPlaceholder(chars),
              )
            : _lightPlaceholder(chars),
      ),
    );
  }

  Widget _lightPlaceholder(String chars) {
    return Container(
      color: SettingsScreenStyle.backButtonBg,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        size: size * 0.45,
        color: SettingsScreenStyle.gold,
      ),
    );
  }

  Widget _buildDarkAvatar(String? url, String chars) {
    final fontSize = (size * 0.35).clamp(12, 20).toDouble();
    final textStyle = AppTypography.style(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: CustColors.mainCol, width: 1),
      ),
      alignment: Alignment.center,
      child: CircleAvatar(
        radius: (size / 2) - 1,
        backgroundColor: Colors.transparent,
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null ? Text(chars, style: textStyle) : null,
      ),
    );
  }
}

/// Dashboard-style user control — white circle, light border, Remix user-3 icon.
class HeaderUserButton extends StatelessWidget {
  const HeaderUserButton({
    this.size = SettingsScreenStyle.chromeButtonSize,
    this.onTap,
    super.key,
  });

  final double size;
  final VoidCallback? onTap;

  static const Color _border = Color(0xFFDFDFDF);
  static const Color _ink = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Profile()),
            );
          },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: _border, width: 1.2),
        ),
        alignment: Alignment.center,
        child: Iconify(
          Ri.user_3_line,
          size: size * 0.4,
          color: _ink,
        ),
      ),
    );
  }
}
