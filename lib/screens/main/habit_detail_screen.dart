import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/habit.dart';
import '../../models/habit_category.dart';
import '../../providers/habit_provider.dart';
import '../../helpers/localization.dart';
import '../../data/habit_catalog.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  // null = ежедневно (пустой список), иначе конкретные дни
  List<int>? _selectedDays; // null означает "каждый день"
  bool _reminderEnabled = false;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    final days = widget.habit.scheduledDaysOfWeek;
    // Если список пустой — значит "каждый день" (null)
    _selectedDays = days.isEmpty ? null : List.from(days);
    _reminderEnabled = widget.habit.reminderEnabled;
    if (widget.habit.reminderTime != null) {
      _reminderTime = TimeOfDay.fromDateTime(widget.habit.reminderTime!);
    }
  }

  Future<void> _saveHabit() async {
    try {
      final success = await context.read<HabitProvider>().addHabitFromCatalog(
            widget.habit,
            // null = каждый день → передаём пустой список
            scheduledDaysOfWeek: _selectedDays ?? [],
            reminderTime: _reminderTime != null
                ? DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                    _reminderTime!.hour,
                    _reminderTime!.minute,
                  )
                : null,
            reminderEnabled: _reminderEnabled,
          );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('habit_added')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = context.read<HabitProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? context.tr('add_habit_failed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('error_prefix')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('add_habit')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Заголовок
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.habit.category.icon,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              HabitCatalog.localizedTitle(widget.habit, lang),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.habit.category.localizedDisplayName(lang),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text(
                    HabitCatalog.localizedDescription(widget.habit, lang),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Эко-эффект
          if (widget.habit.waterSavedLiters > 0 ||
              widget.habit.energySavedKwh > 0 ||
              widget.habit.co2SavedKg > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('habit_effect_per_completion'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.habit.waterSavedLiters > 0)
                      _impactRow('${context.tr('water_saved_full')}',
                          '${widget.habit.waterSavedLiters.toStringAsFixed(0)} л'),
                    if (widget.habit.energySavedKwh > 0)
                      _impactRow('${context.tr('energy_saved_full')}',
                          '${widget.habit.energySavedKwh.toStringAsFixed(1)} кВт·ч'),
                    if (widget.habit.co2SavedKg > 0)
                      _impactRow('${context.tr('co2_prevented_full')}',
                          '${widget.habit.co2SavedKg.toStringAsFixed(1)} кг'),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Периодичность
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('frequency'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _dayChip(context.tr('day_mon'), 1),
                      _dayChip(context.tr('day_tue'), 2),
                      _dayChip(context.tr('day_wed'), 3),
                      _dayChip(context.tr('day_thu'), 4),
                      _dayChip(context.tr('day_fri'), 5),
                      _dayChip(context.tr('day_sat'), 6),
                      _dayChip(context.tr('day_sun'), 7),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Напоминание
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('reminder'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: _reminderEnabled,
                        onChanged: (value) {
                          setState(() {
                            _reminderEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_reminderEnabled)
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(context.tr('reminder_time')),
                      subtitle: Text(
                        _reminderTime != null
                            ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                            : context.tr('not_selected'),
                      ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (time != null) {
                          setState(() {
                            _reminderTime = time;
                          });
                        }
                      },
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Кнопка сохранения
          ElevatedButton(
            onPressed: _saveHabit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              context.tr('add_habit'),
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayChip(String label, int day) {
    // null = каждый день → все чипы выбраны
    final isSelected = _selectedDays == null || _selectedDays!.contains(day);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (_selectedDays == null) {
            // Переходим из режима "каждый день" в конкретные дни:
            // выбираем все дни кроме снятого
            _selectedDays = [1, 2, 3, 4, 5, 6, 7]
                .where((d) => d != day)
                .toList();
          } else {
            if (selected) {
              _selectedDays!.add(day);
              // Если выбраны все 7 дней — возвращаемся в режим "каждый день"
              if (_selectedDays!.length == 7) {
                _selectedDays = null;
              }
            } else {
              _selectedDays!.remove(day);
              // Если не осталось ни одного дня — сбрасываем в "каждый день"
              if (_selectedDays!.isEmpty) {
                _selectedDays = null;
              }
            }
          }
        });
      },
    );
  }

  Widget _impactRow(String icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
