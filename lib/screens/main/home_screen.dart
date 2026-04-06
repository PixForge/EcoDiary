import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/habit_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/habit_tile.dart';
import 'profile_screen.dart';
import 'eco_impact_screen.dart';
import 'achievements_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedDate = context.watch<StatsProvider>().selectedDate;
    final todayHabits = context.watch<HabitProvider>().getHabitsForDay(selectedDate);
    final completionPercent = context.watch<StatsProvider>().getDailyCompletionPercent(todayHabits);
    final isToday = _isSameDay(selectedDate, DateTime.now());

    print('[HomeScreen] selectedDate=$selectedDate, todayHabits=${todayHabits.length}, completionPercent=$completionPercent');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои привычки'),
        actions: [
          // Эко-эффект
          IconButton(
            icon: const Icon(Icons.eco_outlined, size: 28),
            onPressed: () {
              print('[HomeScreen] Нажата кнопка Эко-эффект');
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const EcoImpactScreen()),
              );
            },
            tooltip: 'Экологический эффект',
            splashRadius: 24,
          ),
          // Достижения
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, size: 28),
            onPressed: () {
              print('[HomeScreen] Нажата кнопка Достижения');
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              );
            },
            tooltip: 'Достижения',
            splashRadius: 24,
          ),
          // Профиль
          IconButton(
            icon: const Icon(Icons.person_outline, size: 28),
            onPressed: () {
              print('[HomeScreen] Нажата кнопка Профиль');
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            tooltip: 'Профиль',
            splashRadius: 24,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
        children: [
          // Выбор даты
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: context.read<StatsProvider>().goToPreviousDay,
                ),
                Column(
                  children: [
                    Text(
                      isToday ? 'Сегодня' : DateFormat('d MMMM yyyy', 'ru').format(selectedDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: completionPercent / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        completionPercent == 100
                            ? Colors.green
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${completionPercent.toStringAsFixed(0)}% выполнено',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: isToday ? null : context.read<StatsProvider>().goToNextDay,
                ),
              ],
            ),
          ),

          // Список привычек
          Expanded(
            child: todayHabits.isEmpty
                ? _buildEmptyState(context, isToday)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: todayHabits.length,
                    itemBuilder: (context, index) {
                      final habit = todayHabits[index];
                      return HabitTile(
                        habit: habit,
                        date: selectedDate,
                        onToggle: () {
                          context.read<HabitProvider>().toggleHabitCompletion(
                                habit,
                                selectedDate,
                              );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isToday) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isToday ? Icons.checklist_outlined : Icons.calendar_today_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isToday
                  ? 'У вас пока нет привычек на сегодня'
                  : 'Нет привычек на этот день',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isToday
                  ? 'Добавьте привычки из каталога'
                  : 'Выберите другой день',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            if (isToday)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Переключиться на вкладку каталога
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить привычки'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
