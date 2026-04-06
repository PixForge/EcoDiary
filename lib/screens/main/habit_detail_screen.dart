import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/habit.dart';
import '../../models/habit_category.dart';
import '../../providers/habit_provider.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  List<int> _selectedDays = [];
  bool _reminderEnabled = false;
  TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _selectedDays = List.from(widget.habit.scheduledDaysOfWeek);
    _reminderEnabled = widget.habit.reminderEnabled;
    if (widget.habit.reminderTime != null) {
      _reminderTime = TimeOfDay.fromDateTime(widget.habit.reminderTime!);
    }
  }

  Future<void> _saveHabit() async {
    try {
      final success = await context.read<HabitProvider>().addHabitFromCatalog(
            widget.habit,
            scheduledDaysOfWeek: _selectedDays,
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
          const SnackBar(
            content: Text('Привычка добавлена! ✓'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = context.read<HabitProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Не удалось добавить привычку'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить привычку'),
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
                              widget.habit.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.habit.category.displayName,
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
                    widget.habit.description,
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
                      'Экологический эффект за выполнение',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (widget.habit.waterSavedLiters > 0)
                      _impactRow('💧 Воды сохранено',
                          '${widget.habit.waterSavedLiters.toStringAsFixed(0)} л'),
                    if (widget.habit.energySavedKwh > 0)
                      _impactRow('⚡ Энергии сэкономлено',
                          '${widget.habit.energySavedKwh.toStringAsFixed(1)} кВт·ч'),
                    if (widget.habit.co2SavedKg > 0)
                      _impactRow('🌬️ CO₂ предотвращено',
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
                    'Периодичность',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _dayChip('Пн', 1),
                      _dayChip('Вт', 2),
                      _dayChip('Ср', 3),
                      _dayChip('Чт', 4),
                      _dayChip('Пт', 5),
                      _dayChip('Сб', 6),
                      _dayChip('Вс', 7),
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
                        'Напоминание',
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
                      title: const Text('Время напоминания'),
                      subtitle: Text(
                        _reminderTime != null
                            ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                            : 'Не выбрано',
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
            child: const Text(
              'Добавить привычку',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dayChip(String label, int day) {
    final isSelected = _selectedDays.isEmpty || _selectedDays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (_selectedDays.isEmpty) {
            // Если было "ежедневно", то снимаем все кроме выбранного
            _selectedDays = selected ? [day] : [];
          } else {
            if (selected) {
              _selectedDays.add(day);
            } else {
              _selectedDays.remove(day);
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
