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
      'app_title': 'Дневник эко-привычек',
      'home': 'Главная',
      'catalog': 'Каталог',
      'stats': 'Статистика',
      'profile': 'Профиль',
      'achievements': 'Достижения',
      'eco_impact': 'Эко-эффект',
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
      'dark_mode': 'Тёмная тема',
      'notifications': 'Уведомления',
      'sign_out': 'Выйти',
      'change_password': 'Сменить пароль',
      'save': 'Сохранить',
      'cancel': 'Отмена',
      'delete': 'Удалить',
      'edit': 'Редактировать',
      'search': 'Поиск',
      'water_saved': 'Воды сохранено',
      'energy_saved': 'Энергии сэкономлено',
      'co2_prevented': 'CO₂ предотвращено',
    },
    'en': {
      'app_title': 'Eco Habit Diary',
      'home': 'Home',
      'catalog': 'Catalog',
      'stats': 'Statistics',
      'profile': 'Profile',
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
      'dark_mode': 'Dark mode',
      'notifications': 'Notifications',
      'sign_out': 'Sign out',
      'change_password': 'Change password',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'water_saved': 'Water saved',
      'energy_saved': 'Energy saved',
      'co2_prevented': 'CO₂ prevented',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
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
