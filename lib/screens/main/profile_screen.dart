import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';
import '../../helpers/localization.dart';
import 'export_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await NotificationService().areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('confirm_exit')),
        content: Text(context.tr('confirm_exit_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('exit')),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().signOut();
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('change_password')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: InputDecoration(labelText: context.tr('password')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: InputDecoration(labelText: context.tr('password')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.tr('change_password'))),
              );
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Профиль
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.email ?? 'user@example.com',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Настройки
          _sectionHeader(context, context.tr('settings')),

          // Тема
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: Text(context.tr('dark_mode')),
              value: themeProvider.isDarkMode,
              onChanged: (value) {
                themeProvider.setDarkMode(value);
              },
            ),
          ),

          const SizedBox(height: 8),

          // Уведомления
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: Text(context.tr('notifications')),
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                await NotificationService().setNotificationsEnabled(value);
              },
            ),
          ),

          const SizedBox(height: 8),

          // Тестовое уведомление
          Card(
            child: ListTile(
              leading: const Icon(Icons.notification_add),
              title: Text(context.tr('test_notification')),
              subtitle: Text(context.tr('test_notification_subtitle')),
              onTap: () async {
                await NotificationService().showTestNotification();
                final messenger = ScaffoldMessenger.of(context);
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text(context.tr('notification_sent'))),
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 8),

          // Язык
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(context.tr('language')),
              subtitle: Text(
                themeProvider.languageCode == 'ru' ? 'Русский' : 'English',
              ),
              trailing: DropdownButton<String>(
                value: themeProvider.languageCode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'ru', child: Text('Русский')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setLanguage(value);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Аккаунт
          _sectionHeader(context, context.tr('account')),

          // Сменить пароль
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(context.tr('change_password')),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
            ),
          ),

          const SizedBox(height: 8),

          // Экспорт в PDF
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: Text(context.tr('export_pdf')),
              subtitle: Text(context.tr('export_subtitle')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExportScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Выйти
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                context.tr('sign_out'),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: _signOut,
            ),
          ),

          const SizedBox(height: 32),

          // Версия
          Center(
            child: Text(
              context.tr('version'),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
