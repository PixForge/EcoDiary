import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/notification_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_profile.dart';
import '../../helpers/localization.dart';
import 'export_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _imagePicker = ImagePicker();
  bool _notificationsEnabled = true;
  bool _isSaving = false;

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
              decoration: InputDecoration(labelText: context.tr('current_password')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: InputDecoration(labelText: context.tr('new_password')),
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
                SnackBar(content: Text(context.tr('password_changed'))),
              );
            },
            child: Text(context.tr('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDisplayName(UserProfile profile) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите имя')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestoreService.updateProfileFields(user.uid, {
        'displayName': name,
      });

      // Синхронизировать с друзьями
      await _firestoreService.syncProfileWithFriends(
        userId: user.uid,
        displayName: name,
        avatarBase64: profile.avatarBase64,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('name_saved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final XFile? image;
    try {
      image = await _imagePicker.pickImage(source: source);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выбора фото: $e')),
      );
      return;
    }

    if (image == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final bytes = await image.readAsBytes();
      final avatarBase64 = base64Encode(bytes);

      await _firestoreService.updateProfileFields(user.uid, {
        'avatarBase64': avatarBase64,
      });

      // Синхронизировать с друзьями
      await _firestoreService.syncProfileWithFriends(
        userId: user.uid,
        displayName: _nameController.text.trim().isEmpty
            ? (user.displayName ?? user.email ?? '')
            : _nameController.text.trim(),
        avatarBase64: avatarBase64,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('avatar_updated'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showAvatarPicker() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.tr('camera')),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.tr('gallery')),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setVisibility(String value) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    await _firestoreService.updateProfileFields(user.uid, {
      'progressVisibility': value,
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('visibility_saved'))),
    );
  }

  Future<void> _exportUserData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    try {
      final data = await _firestoreService.exportUserData(user.uid);
      final jsonText = const JsonEncoder.withIndent('  ').convert(data);
      final fileName =
          'eco_data_${DateTime.now().toIso8601String().split('T').first}.json';

      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(jsonText)),
            mimeType: 'application/json',
            name: fileName,
          ),
        ],
        text: context.tr('data_exported'),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('operation_failed'))),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_account_confirm_title')),
        content: Text(context.tr('delete_account_confirm_msg')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await context.read<AuthProvider>().deleteAccount();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? context.tr('delete_account_success') : context.tr('operation_failed'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('profile'))),
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('profile'))),
      body: StreamBuilder<UserProfile?>(
        stream: _firestoreService.getProfileStream(user.uid),
        builder: (context, snapshot) {
          final profile = snapshot.data ??
              UserProfile(
                uid: user.uid,
                email: user.email ?? '',
              );
          
          // Устанавливаем значение только если контроллер ещё не был заполнен
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_nameController.text.isEmpty && profile.displayName.isNotEmpty) {
              _nameController.text = profile.displayName;
            }
          });
          
          return ListView(
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
                    backgroundImage: profile.avatarBase64.isNotEmpty
                        ? MemoryImage(base64Decode(profile.avatarBase64))
                        : null,
                    child: profile.avatarBase64.isEmpty
                        ? Text(
                            (profile.displayName.isNotEmpty
                                    ? profile.displayName
                                    : profile.email)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.displayName.isNotEmpty
                        ? profile.displayName
                        : profile.email,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    profile.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _showAvatarPicker,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(context.tr('choose_avatar')),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: context.tr('display_name'),
                      hintText: context.tr('display_name_hint'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () => _saveDisplayName(profile),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(context.tr('save_name')),
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

          const SizedBox(height: 16),
          _sectionHeader(context, context.tr('privacy')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text(context.tr('progress_visibility')),
              trailing: DropdownButton<String>(
                value: profile.progressVisibility,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                    value: 'public',
                    child: Text(context.tr('visibility_public')),
                  ),
                  DropdownMenuItem(
                    value: 'friends',
                    child: Text(context.tr('visibility_friends')),
                  ),
                  DropdownMenuItem(
                    value: 'private',
                    child: Text(context.tr('visibility_private')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _setVisibility(value);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),
          _sectionHeader(context, context.tr('data_management')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(context.tr('download_data_json')),
              onTap: _exportUserData,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: Text(
                context.tr('delete_account'),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: _deleteAccount,
            ),
          ),

          const SizedBox(height: 8),

          // Язык
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(context.tr('language')),
              subtitle: Text(
                themeProvider.languageCode == 'ru'
                    ? context.tr('app_language_ru')
                    : context.tr('app_language_en'),
              ),
              trailing: DropdownButton<String>(
                value: themeProvider.languageCode,
                underline: const SizedBox(),
                items: [
                  DropdownMenuItem(
                    value: 'ru',
                    child: Text(context.tr('app_language_ru')),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(context.tr('app_language_en')),
                  ),
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
      );
        },
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
