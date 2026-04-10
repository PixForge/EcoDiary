import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/habit_provider.dart';
import '../../services/export_service.dart';
import '../../helpers/localization.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTimeRange? _selectedRange;
  bool _isExporting = false;

  final List<DateTimeRange> _presetRanges = [
    DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    ),
    DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    ),
    DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 90)),
      end: DateTime.now(),
    ),
  ];

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );

    if (range != null) {
      setState(() {
        _selectedRange = range;
      });
    }
  }

  Future<void> _export() async {
    if (_selectedRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_period'))),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      final habitProvider = context.read<HabitProvider>();
      final exportService = ExportService();

      await exportService.exportReport(
        habits: habitProvider.habits,
        startDate: _selectedRange!.start,
        endDate: _selectedRange!.end,
        longestStreak: habitProvider.getLongestStreak(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка экспорта: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('export'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Выбор периода
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('select_period'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Быстрый выбор
                  Wrap(
                    spacing: 8,
                    children: [
                      _presetChip(context.tr('week'), _presetRanges[0]),
                      _presetChip(context.tr('month'), _presetRanges[1]),
                      _presetChip('3 ${context.tr('month').toLowerCase()}', _presetRanges[2]),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Кастомный выбор
                  OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _selectedRange != null
                          ? '${DateFormat('dd.MM.yyyy').format(_selectedRange!.start)} — ${DateFormat('dd.MM.yyyy').format(_selectedRange!.end)}'
                          : context.tr('select_date_range'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Что будет в отчёте
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('report_content'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _infoItem('✅', 'Количество выполненных привычек'),
                  _infoItem('📊', 'Процент выполнения'),
                  _infoItem('🔥', 'Достигнутые серии'),
                  _infoItem('🌍', 'Рассчитанный экологический эффект'),
                  _infoItem('📋', 'Детализация по каждой привычке'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Кнопка экспорта
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting || _selectedRange == null ? null : _export,
              icon: _isExporting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(
                _isExporting ? context.tr('exporting') : context.tr('export_to_pdf'),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetChip(String label, DateTimeRange range) {
    final isSelected = _selectedRange != null &&
        _selectedRange!.start.isAtSameMomentAs(range.start) &&
        _selectedRange!.end.isAtSameMomentAs(range.end);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRange = range;
        });
      },
    );
  }

  Widget _infoItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
