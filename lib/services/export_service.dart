import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/habit.dart';
import '../models/habit_category.dart';
import 'impact_calc_service.dart';

/// Сервис экспорта данных в PDF
class ExportService {
  final ImpactCalcService _impactCalc = ImpactCalcService();
  pw.Font? _font;
  pw.Font? _fontBold;

  /// Загрузить шрифты с поддержкой кириллицы
  Future<void> _loadFonts() async {
    if (_font != null) return;
    try {
      final regular = await rootBundle.load('lib/assets/Roboto-Regular.ttf');
      _font = pw.Font.ttf(regular);
      _fontBold = _font; // Используем тот же шрифт для простоты
    } catch (e) {
      // Fallback: используем Helvetica (без кириллицы, но хотя бы не упадёт)
      _font = pw.Font.helvetica();
      _fontBold = pw.Font.helveticaBold();
    }
  }

  /// Создать и показать PDF-отчёт
  Future<void> exportReport({
    required List<Habit> habits,
    required DateTime startDate,
    required DateTime endDate,
    required int longestStreak,
  }) async {
    await _loadFonts();
    final pdf = pw.Document();
    final impact = _impactCalc.calculateTotalImpact(habits, startDate, endDate);
    final f = _font!;
    final fBold = _fontBold!;

    // Рассчитать статистику
    final totalCompletions = habits.fold<int>(
      0,
      (sum, h) => sum + h.completedDates.length,
    );

    final scheduledHabits = habits.length;
    final completionRate = scheduledHabits > 0
        ? (totalCompletions / (scheduledHabits * _daysInRange(startDate, endDate))) * 100
        : 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Заголовок
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Дневник экологических привычек',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    font: fBold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Отчёт: ${_formatDate(startDate)} — ${_formatDate(endDate)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    font: f,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),

          pw.Divider(),

          // Общая статистика
          pw.Header(level: 1, text: 'Общая статистика'),
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _statCard(f, fBold, 'Привычек', '$scheduledHabits'),
                _statCard(f, fBold, 'Выполнено', '$totalCompletions'),
                _statCard(f, fBold, 'Процент', '${completionRate.toStringAsFixed(1)}%'),
                _statCard(f, fBold, 'Серия', '$longestStreak дн.'),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Экологический эффект
          pw.Header(level: 1, text: 'Экологический эффект'),
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '💧 Воды сохранено: ${impact.waterSavedLiters.toStringAsFixed(1)} литров',
                  style: pw.TextStyle(fontSize: 14, font: f),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '⚡ Энергии сэкономлено: ${impact.energySavedKwh.toStringAsFixed(1)} кВт·ч',
                  style: pw.TextStyle(fontSize: 14, font: f),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '🌬️ CO₂ предотвращено: ${impact.co2SavedKg.toStringAsFixed(1)} кг',
                  style: pw.TextStyle(fontSize: 14, font: f),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Визуальные эквиваленты
          pw.Header(level: 1, text: 'Визуальные эквиваленты'),
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '🌳 Деревьев (поглощение CO₂): ${_impactCalc.co2ToTrees(impact.co2SavedKg).toStringAsFixed(1)}',
                  style: pw.TextStyle(fontSize: 14, font: f),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '🚗 Км на авто (эквивалент CO₂): ${_impactCalc.co2ToCarKm(impact.co2SavedKg).toStringAsFixed(0)} км',
                  style: pw.TextStyle(fontSize: 14, font: f),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '💡 Часов работы LED-лампы: ${_impactCalc.energyToLedHours(impact.energySavedKwh).toStringAsFixed(0)} ч',
                  style: pw.TextStyle(fontSize: 14, font: f),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  '🛒 Ванн (эквивалент воды): ${_impactCalc.waterToBaths(impact.waterSavedLiters).toStringAsFixed(1)}',
                  style: pw.TextStyle(fontSize: 14, font: f),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Детализация по привычкам
          pw.Header(level: 1, text: 'Детализация по привычкам'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green50),
                children: [
                  _headerCell('Привычка'),
                  _headerCell('Категория'),
                  _headerCell('Выполнений'),
                ],
              ),
              for (final habit in habits)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        habit.title,
                        style: pw.TextStyle(fontSize: 11, font: f),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        habit.category.icon,
                        style: pw.TextStyle(fontSize: 12, font: f),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        '${habit.completedDates.length}',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: f),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Создано в приложении «Дневник экологических привычек»',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 10,
              font: _font,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'eco_habit_report_${_formatDateFile(startDate)}_${_formatDateFile(endDate)}.pdf',
    );
  }

  pw.Widget _statCard(pw.Font f, pw.Font fBold, String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green300),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              font: fBold,
              color: PdfColors.green800,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              font: f,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _headerCell(String text) {
    final fBold = _fontBold!;
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
          font: fBold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateFile(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _daysInRange(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }
}
