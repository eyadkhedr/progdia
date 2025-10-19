import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/habit_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsBar extends StatefulWidget {
  const StatsBar({super.key});

  @override
  State<StatsBar> createState() => _StatsBarState();
}

class _StatsBarState extends State<StatsBar>
    with TickerProviderStateMixin {
  late AnimationController _coinAnimationController;
  late Animation<double> _coinScaleAnimation;
  int _previousCoinBalance = 0;

  @override
  void initState() {
    super.initState();
    _coinAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _coinScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _coinAnimationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _coinAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HabitProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildBar(context, 0, provider.dayStreak);
    }
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        int coins = 0;
        if (snapshot.hasData) {
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          coins = (data['coins'] is int) ? data['coins'] : 0;
        }
        // Animate if coins changed
        if (coins != _previousCoinBalance) {
          _coinAnimationController.forward().then((_) {
            _coinAnimationController.reverse();
          });
        }
        _previousCoinBalance = coins;
        return _buildBar(context, coins, provider.dayStreak);
      },
    );
  }

  Widget _buildBar(BuildContext context, int coins, int dayStreak) {
    return AnimatedBuilder(
      animation: _coinAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(240),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withAlpha(120), width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Coins Section
              Row(
                children: [
                  Transform.scale(
                    scale: _coinScaleAnimation.value,
                    child: Icon(
                      Icons.monetization_on_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Transform.scale(
                    scale: _coinScaleAnimation.value,
                    child: Text(
                      '$coins',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              // Streak Section
              Row(
                children: [
                  Text(
                    '\t$dayStreak',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
