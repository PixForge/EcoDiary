import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/habit_provider.dart';
import '../../data/habit_catalog.dart';
import '../../models/habit_category.dart';
import '../../models/habit.dart';
import 'habit_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: HabitCategory.values.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitProvider = context.watch<HabitProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Каталог привычек'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: HabitCategory.values.map((category) {
            return Tab(
              text: '${category.icon} ${_shortCategoryName(category)}',
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск привычек...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Список привычек
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: HabitCategory.values.map((category) {
                var habits = HabitCatalog.getByCategory(category);

                // Фильтрация по поиску
                if (_searchQuery.isNotEmpty) {
                  habits = habits
                      .where((h) =>
                          h.title.toLowerCase().contains(_searchQuery) ||
                          h.description.toLowerCase().contains(_searchQuery))
                      .toList();
                }

                final selectedHabits = habits
                    .where((h) => habitProvider.isHabitSelected(h.id))
                    .toList();
                final availableHabits =
                    habits.where((h) => !habitProvider.isHabitSelected(h.id)).toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Выбранные привычки
                    if (selectedHabits.isNotEmpty) ...[
                      _buildSectionHeader(context, '✓ Выбранные', selectedHabits.length),
                      ...selectedHabits.map((habit) => _buildHabitCard(habit, true)),
                      const SizedBox(height: 16),
                    ],

                    // Доступные привычки
                    if (availableHabits.isNotEmpty) ...[
                      _buildSectionHeader(context, 'Добавить', availableHabits.length),
                      ...availableHabits.map((habit) => _buildHabitCard(habit, false)),
                    ],

                    // Пустой state
                    if (habits.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Ничего не найдено',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCard(Habit habit, bool isSelected) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HabitDetailScreen(habit: habit),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    habit.category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          habit.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.add_circle_outline, color: Colors.grey),
                ],
              ),
              if (habit.waterSavedLiters > 0 || habit.co2SavedKg > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (habit.waterSavedLiters > 0)
                        _miniBadge('💧 ${habit.waterSavedLiters.toStringAsFixed(0)}л'),
                      if (habit.energySavedKwh > 0)
                        _miniBadge('⚡ ${habit.energySavedKwh.toStringAsFixed(1)}'),
                      if (habit.co2SavedKg > 0)
                        _miniBadge('🌬️ ${habit.co2SavedKg.toStringAsFixed(1)} кг'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.green,
        ),
      ),
    );
  }

  String _shortCategoryName(HabitCategory category) {
    switch (category) {
      case HabitCategory.waterSaving:
        return 'Вода';
      case HabitCategory.energySaving:
        return 'Энергия';
      case HabitCategory.wasteManagement:
        return 'Отходы';
      case HabitCategory.ecoTransport:
        return 'Транспорт';
      case HabitCategory.ecoConsumption:
        return 'Потребление';
      case HabitCategory.natureCare:
        return 'Природа';
    }
  }
}
