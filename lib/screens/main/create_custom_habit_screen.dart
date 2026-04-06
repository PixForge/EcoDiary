import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/habit.dart';
import '../../models/habit_category.dart';
import '../../providers/habit_provider.dart';

class CreateCustomHabitScreen extends StatefulWidget {
  const CreateCustomHabitScreen({super.key});

  @override
  State<CreateCustomHabitScreen> createState() =>
      _CreateCustomHabitScreenState();
}

class _CreateCustomHabitScreenState extends State<CreateCustomHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _waterController = TextEditingController();
  final _energyController = TextEditingController();
  final _co2Controller = TextEditingController();

  HabitCategory _selectedCategory = HabitCategory.waterSaving;
  List<int>? _selectedDays; // null = каждый день
  bool _reminderEnabled = false;
  TimeOfDay? _reminderTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _waterController.dispose();
    _energyController.dispose();
    _co2Controller.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final success = await context.read<HabitProvider>().addCustomHabit(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            scheduledDaysOfWeek: _selectedDays ?? [],
            waterSavedLiters: double.tryParse(_waterController.text) ?? 0,
            energySavedKwh: double.tryParse(_energyController.text) ?? 0,
            co2SavedKg: double.tryParse(_co2Controller.text) ?? 0,
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
            content: Text('Привычка создана! ✓'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = context.read<HabitProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Не удалось создать привычку'),
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
        title: const Text('Создать привычку'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Название
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Название привычки',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Например: Пить воду утром',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите название привычки';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Описание
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Описание',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Опишите вашу привычку',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Категория
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Категория',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: HabitCategory.values.map((category) {
                        final isSelected = category == _selectedCategory;
                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(category.icon),
                              const SizedBox(width: 4),
                              Text(category.displayName),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Эко-эффект (опционально)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Экологический эффект (опционально)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildImpactField(
                      '💧 Вода (литров)',
                      _waterController,
                      '0',
                    ),
                    const SizedBox(height: 8),
                    _buildImpactField(
                      '⚡ Энергия (кВт·ч)',
                      _energyController,
                      '0',
                    ),
                    const SizedBox(height: 8),
                    _buildImpactField(
                      '🌬️ CO₂ (кг)',
                      _co2Controller,
                      '0',
                    ),
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
                    const SizedBox(height: 12),
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
                            initialTime:
                                _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
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
                'Создать привычку',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactField(String label, TextEditingController controller, String hint) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayChip(String label, int day) {
    final isSelected = _selectedDays == null || _selectedDays!.contains(day);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (_selectedDays == null) {
            _selectedDays = [1, 2, 3, 4, 5, 6, 7]
                .where((d) => d != day)
                .toList();
          } else {
            if (selected) {
              _selectedDays!.add(day);
              if (_selectedDays!.length == 7) {
                _selectedDays = null;
              }
            } else {
              _selectedDays!.remove(day);
              if (_selectedDays!.isEmpty) {
                _selectedDays = null;
              }
            }
          }
        });
      },
    );
  }
}
