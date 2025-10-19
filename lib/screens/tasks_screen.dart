 import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import '../screens/add_habit_screen.dart';
import '../widgets/stats_bar.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = Provider.of<HabitProvider>(context);
    final grouped = habitProvider.groupedHabits;

    if (!habitProvider.categoriesLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (context) => const _BottomSheetContent(),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StatsBar(),
              const SizedBox(height: 20),
              if (grouped.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text(
                      'No tasks for today,\nEnjoy your time!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              else
                AnimatedList(
                  key: GlobalKey<AnimatedListState>(),
                  initialItemCount: grouped.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index, animation) {
                    final category = grouped.keys.elementAt(index);
                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: _CategorySection(
                        key: ValueKey(category),
                        category: category,
                        habits: grouped[category]!,
                        index: index,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final String category;
  final List<Habit> habits;
  final int index;

  const _CategorySection({
    super.key,
    required this.category,
    required this.habits,
    required this.index,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HabitProvider>(context);
    final categoryColor = provider.colorForCategory(widget.category);
    final icon = provider.iconForCategory(widget.category);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(240),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withAlpha(120),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          // Category header (unchanged)
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(20),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(_isExpanded ? 0 : 16),
                  bottomRight: Radius.circular(_isExpanded ? 0 : 16),
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, color: categoryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.category,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Text(
                    '${widget.habits.where((h) => !h.completed).length}/${widget.habits.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Habits list with sliding animations
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: widget.habits.map((habit) {
                          return HabitCard(
                            key: ValueKey(habit.id),
                            habit: habit,
                          );
                        }).toList(),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// Extracted for cleaner layout
class _BottomSheetContent extends StatelessWidget {
  const _BottomSheetContent();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: true,
      initialChildSize: 0.96,
      maxChildSize: 0.96,
      minChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: AddHabitScreen(), // no scroll view needed here
        );
      },
    );
  }
}
