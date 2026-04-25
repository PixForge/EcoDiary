import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/social_provider.dart';
import '../../helpers/localization.dart';

/// Экран создания челленджа
class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({super.key});

  @override
  State<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  int _durationDays = 7;
  bool _isLoading = false;

  // Предустановленные названия челленджей
  final List<Map<String, String>> _presetChallenges = [
    {'name': '7 дней без пластика', 'description': 'Неделя отказа от одноразового пластика'},
    {'name': 'Экономия воды', 'description': '7 дней сознательного потребления воды'},
    {'name': 'Зелёный транспорт', 'description': 'Неделя без личного автомобиля'},
    {'name': 'Без пищевых отходов', 'description': '7 дней без выбрасывания еды'},
    {'name': 'Сортировка отходов', 'description': 'Неделя правильной сортировки мусора'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createChallenge() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final socialProvider = context.read<SocialProvider>();
      await socialProvider.createChallenge(
        name: _nameController.text,
        description: _descriptionController.text,
        durationDays: _durationDays,
        startDate: _selectedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Челлендж создан! Пригласите друзей 🎉')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _selectPreset(Map<String, String> preset) {
    setState(() {
      _nameController.text = preset['name']!;
      _descriptionController.text = preset['description']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('create_challenge')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Предустановленные варианты
            Text(
              'Быстрый старт',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presetChallenges.length,
                itemBuilder: (context, index) {
                  final preset = _presetChallenges[index];
                  return Card(
                    margin: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () => _selectPreset(preset),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('🎯', style: TextStyle(fontSize: 24)),
                            const SizedBox(height: 8),
                            Text(
                              preset['name']!,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Название
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название челленджа',
                hintText: 'Например: 7 дней без пластика',
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите название';
                }
                if (value.length < 3) {
                  return 'Минимум 3 символа';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Описание
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                hintText: 'Опишите цель челленджа',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Введите описание';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Длительность
            Text(
              'Длительность',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 7, label: Text('7 дней')),
                      ButtonSegment(value: 14, label: Text('14 дней')),
                      ButtonSegment(value: 21, label: Text('21 день')),
                      ButtonSegment(value: 30, label: Text('30 дней')),
                    ],
                    selected: {_durationDays},
                    onSelectionChanged: (selected) {
                      setState(() {
                        _durationDays = selected.first;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Дата начала
            Text(
              'Дата начала',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 1)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                },
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Информация оparticipants
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Вы можете пригласить до 5 друзей после создания челленджа',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Кнопка создания
            ElevatedButton(
              onPressed: _isLoading ? null : _createChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Создать челлендж',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
