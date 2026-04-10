import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/stats_provider.dart';
import '../../widgets/habit_tile.dart';
import 'profile_screen.dart';
import 'eco_impact_screen.dart';
import 'achievements_screen.dart';
import 'main_navigation_screen.dart';

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
          // Прогресс выполнения за день
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Круговой прогресс-индикатор
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: completionPercent / 100),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value: value,
                              strokeWidth: 12,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                completionPercent == 100
                                    ? const Color(0xFF2E7D32)
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${completionPercent.toStringAsFixed(0)}%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: completionPercent == 100
                                  ? const Color(0xFF2E7D32)
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            completionPercent == 100 ? '✓ Всё!' : 'выполнено',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
                        key: ValueKey('${habit.id}_${selectedDate.toIso8601String()}'),
                        habit: habit,
                        date: selectedDate,
                        onToggle: () {
                          print('[HomeScreen] onToggle: habit="${habit.title}", date=$selectedDate');
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
                    // Переключиться на вкладку каталога (индекс 1)
                    navigationKey.currentState?.switchToTab(1);
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
