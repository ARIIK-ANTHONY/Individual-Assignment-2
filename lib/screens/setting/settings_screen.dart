import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/listings_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<ap.AuthProvider>(builder: (_, auth, __) {
        final profile = auth.userProfile;
        final user = auth.user;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.divider)),
              child: Row(children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.accentGold.withValues(alpha: 0.2),
                  child: Text(
                      _initials(profile?.displayName ?? user?.email ?? 'U'),
                      style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.displayName ?? user?.displayName ?? 'User',
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(user?.email ?? '',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(
                          user?.emailVerified ?? false
                              ? Icons.verified
                              : Icons.warning_amber,
                          size: 14,
                          color: user?.emailVerified ?? false
                              ? AppTheme.successGreen
                              : AppTheme.accentGold),
                      const SizedBox(width: 4),
                      Text(
                          user?.emailVerified ?? false
                              ? 'Verified'
                              : 'Email not verified',
                          style: TextStyle(
                              color: user?.emailVerified ?? false
                                  ? AppTheme.successGreen
                                  : AppTheme.accentGold,
                              fontSize: 12)),
                    ]),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 24),

            // Stats
            Consumer<ListingsProvider>(
              builder: (_, listings, __) => Row(children: [
                _StatCard('My Listings',
                    listings.userListings.length.toString(), Icons.bookmark),
                const SizedBox(width: 12),
                _StatCard('Total Listings',
                    listings.allListings.length.toString(), Icons.explore),
              ]),
            ),
            const SizedBox(height: 28),

            const Text('Preferences',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            _SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'Location Notifications',
              subtitle: 'Receive alerts for nearby services',
              trailing: Switch(
                value: profile?.notificationsEnabled ?? true,
                onChanged: auth.updateNotificationPreference,
                activeThumbColor: AppTheme.accentGold,
                activeTrackColor: AppTheme.accentGold.withValues(alpha: 0.3),
                inactiveThumbColor: AppTheme.textSecondary,
                inactiveTrackColor: AppTheme.divider,
              ),
            ),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Mode',
              subtitle: 'Currently active',
              trailing: Switch(
                  value: true,
                  onChanged: null,
                  activeThumbColor: AppTheme.accentGold,
                  activeTrackColor: AppTheme.accentGold.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 28),

            const Text('About',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const _SettingsTile(
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: '1.0.0'),
            const SizedBox(height: 8),
            const _SettingsTile(
                icon: Icons.location_city_outlined,
                title: 'Kigali City Directory',
                subtitle: 'Helping residents find essential services'),

            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context, auth),
              icon: const Icon(Icons.logout, color: AppTheme.errorRed),
              label: const Text('Sign Out',
                  style: TextStyle(color: AppTheme.errorRed)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppTheme.errorRed),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
          ]),
        );
      }),
    );
  }

  void _confirmSignOut(BuildContext context, ap.AuthProvider auth) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.cardDark,
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    auth.signOut();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                      minimumSize: const Size(80, 40)),
                  child: const Text('Sign Out',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ));
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider)),
          child: Column(children: [
            Icon(icon, color: AppTheme.accentGold, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ]),
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Widget? trailing;
  const _SettingsTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.trailing});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.divider)),
        child: Row(children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: AppTheme.chipBackground,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppTheme.accentGold, size: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ])),
          if (trailing != null) trailing!,
        ]),
      );
}
