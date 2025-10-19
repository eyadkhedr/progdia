import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';

class HabitCard extends StatefulWidget {
  final Habit habit;

  const HabitCard({super.key, required this.habit});

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HabitProvider>(context, listen: false);
    final categoryColor = provider.colorForCategory(widget.habit.category);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onLongPress: () => _showDeleteDialog(context, widget.habit.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: widget.habit.completed 
                      ? categoryColor.withAlpha(20) 
                      : Theme.of(context).colorScheme.surface.withAlpha(240),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.habit.completed 
                        ? categoryColor.withAlpha(76) 
                        : Theme.of(context).colorScheme.outline.withAlpha(120),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        provider.toggleHabit(widget.habit.id);
                        // Add a subtle animation when toggling
                        _animationController.forward(from: 0.8);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          widget.habit.completed
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 24,
                          color: widget.habit.completed 
                              ? categoryColor 
                              : Colors.grey.withAlpha(153),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: widget.habit.completed 
                                    ? Theme.of(context).colorScheme.onSurface.withAlpha(179) 
                                    : Theme.of(context).colorScheme.onSurface,
                                decoration: widget.habit.completed 
                                    ? TextDecoration.lineThrough 
                                    : null,
                              ),
                              child: Text(
                                widget.habit.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${widget.habit.coins}',
                            style: TextStyle(
                              fontSize: 12,
                              color: widget.habit.completed 
                                  ? Theme.of(context).colorScheme.onSurface.withAlpha(153) 
                                  : categoryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task?'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<HabitProvider>(context, listen: false)
                  .deleteHabit(id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
