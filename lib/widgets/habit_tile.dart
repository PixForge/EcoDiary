import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';

class HabitTile extends StatelessWidget {
  final Habit habit;
  final DateTime date;
  final VoidCallback onToggle;

  const HabitTile({
    super.key,
    required this.habit,
    required this.date,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = habit.isCompletedOn(date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Чекбокс
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 16),

              // Категория и название
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          habit.category.icon,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            habit.title,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration:
                                  isCompleted ? TextDecoration.lineThrough : null,
                              color: isCompleted ? Colors.grey : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (habit.waterSavedLiters > 0 ||
                        habit.energySavedKwh > 0 ||
                        habit.co2SavedKg > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            if (habit.waterSavedLiters > 0)
                              _buildImpactBadge(
                                '💧 ${habit.waterSavedLiters.toStringAsFixed(0)}л',
                              ),
                            if (habit.energySavedKwh > 0)
                              _buildImpactBadge(
                                '⚡ ${habit.energySavedKwh.toStringAsFixed(1)} кВт·ч',
                              ),
                            if (habit.co2SavedKg > 0)
                              _buildImpactBadge(
                                '🌬️ ${habit.co2SavedKg.toStringAsFixed(1)} кг',
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactBadge(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.green,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
