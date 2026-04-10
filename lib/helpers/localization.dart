import 'package:flutter/material.dart';

/// Класс для локализации
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  // Переводы
  static const Map<String, Map<String, String>> _localizedValues = {
    'ru': {
      'app_title': 'ЭКО: дневник экологических привычек',
      'home': 'Мои привычки',
      'catalog': 'Каталог привычек',
      'stats': 'Статистика',
      'profile': 'Профиль и настройки',
      'achievements': 'Достижения',
      'eco_impact': 'Экологический эффект',
      'settings': 'Настройки',
      'login': 'Войти',
      'signup': 'Регистрация',
      'email': 'Email',
      'password': 'Пароль',
      'forgot_password': 'Забыли пароль?',
      'no_habits_today': 'Нет привычек на сегодня',
      'add_habit': 'Добавить привычку',
      'today': 'Сегодня',
      'completed': 'Выполнено',
      'total': 'Всего',
      'streak': 'Серия',
      'week': 'Неделя',
      'month': 'Месяц',
      'all_time': 'За всё время',
      'export': 'Экспорт',
      'export_pdf': 'Экспорт в PDF',
      'export_subtitle': 'Отчёт по привычкам и эко-эффекту',
      'dark_mode': 'Тёмная тема',
      'notifications': 'Уведомления',
      'test_notification': 'Тестовое уведомление',
      'test_notification_subtitle': 'Проверить работу уведомлений',
      'notification_sent': 'Уведомление отправлено',
      'sign_out': 'Выйти из аккаунта',
      'change_password': 'Сменить пароль',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'edit': 'Редактировать',
      'search': 'Поиск',
      'search_habits': 'Поиск привычек...',
      'water_saved': 'Воды сохранено',
      'energy_saved': 'Энергии сэкономлено',
      'co2_prevented': 'CO₂ предотвращено',
      'language': 'Язык приложения',
      'account': 'Аккаунт',
      'version': 'Версия 1.0.0',
      'confirm_exit': 'Выход',
      'confirm_exit_msg': 'Вы уверены, что хотите выйти?',
      'exit': 'Выйти',
      'progress_today': 'Прогресс на сегодня',
      'all_done': '✓ Всё выполнено!',
      'completed_percent': 'выполнено',
      'selected': '✓ Выбранные',
      'add': 'Добавить',
      'nothing_found': 'Ничего не найдено',
      'create_habit': 'Создать привычку',
      'select_period': 'Выберите период',
      'report_content': 'Содержимое отчёта',
      'export_to_pdf': 'Экспортировать в PDF',
      'exporting': 'Экспорт...',
      'select_date_range': 'Выбрать даты',
    },
    'en': {
      'app_title': 'ECO: Eco Habit Diary',
      'home': 'My Habits',
      'catalog': 'Habit Catalog',
      'stats': 'Statistics',
      'profile': 'Profile & Settings',
      'achievements': 'Achievements',
      'eco_impact': 'Eco Impact',
      'settings': 'Settings',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'forgot_password': 'Forgot password?',
      'no_habits_today': 'No habits for today',
      'add_habit': 'Add habit',
      'today': 'Today',
      'completed': 'Completed',
      'total': 'Total',
      'streak': 'Streak',
      'week': 'Week',
      'month': 'Month',
      'all_time': 'All time',
      'export': 'Export',
      'export_pdf': 'Export to PDF',
      'export_subtitle': 'Habit and eco-impact report',
      'dark_mode': 'Dark mode',
      'notifications': 'Notifications',
      'test_notification': 'Test notification',
      'test_notification_subtitle': 'Check notifications work',
      'notification_sent': 'Notification sent',
      'sign_out': 'Sign out',
      'change_password': 'Change password',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'search_habits': 'Search habits...',
      'water_saved': 'Water saved',
      'energy_saved': 'Energy saved',
      'co2_prevented': 'CO₂ prevented',
      'language': 'App language',
      'account': 'Account',
      'version': 'Version 1.0.0',
      'confirm_exit': 'Sign out',
      'confirm_exit_msg': 'Are you sure you want to sign out?',
      'exit': 'Sign out',
      'progress_today': 'Today\'s progress',
      'all_done': '✓ All done!',
      'completed_percent': 'completed',
      'selected': '✓ Selected',
      'add': 'Add',
      'nothing_found': 'Nothing found',
      'create_habit': 'Create habit',
      'select_period': 'Select period',
      'report_content': 'Report contents',
      'export_to_pdf': 'Export to PDF',
      'exporting': 'Exporting...',
      'select_date_range': 'Select dates',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

/// Extension для удобного перевода
extension LocalizedBuildContext on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this).translate(key);
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ru'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
