import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';
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
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
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
        title: const Text('Сменить пароль'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Текущий пароль'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Новый пароль'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Реализовать через AuthService
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Функция в разработке')),
              );
            },
            child: const Text('Сохранить'),
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
      appBar: AppBar(title: const Text('Профиль и настройки')),
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
          _sectionHeader(context, 'Настройки'),

          // Тема
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Тёмная тема'),
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
              title: const Text('Уведомления'),
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
              title: const Text('Тестовое уведомление'),
              subtitle: const Text('Проверить работу уведомлений'),
              onTap: () async {
                await NotificationService().showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Уведомление отправлено'),
                    ),
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
              title: const Text('Язык приложения'),
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
          _sectionHeader(context, 'Аккаунт'),

          // Сменить пароль
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Сменить пароль'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changePassword,
            ),
          ),

          const SizedBox(height: 8),

          // Экспорт в PDF
          Card(
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Экспорт в PDF'),
              subtitle: const Text('Отчёт по привычкам и эко-эффекту'),
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
              title: const Text(
                'Выйти из аккаунта',
                style: TextStyle(color: Colors.red),
              ),
              onTap: _signOut,
            ),
          ),

          const SizedBox(height: 32),

          // Версия
          Center(
            child: Text(
              'Версия 1.0.0',
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
