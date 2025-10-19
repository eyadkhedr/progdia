import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gemini_service.dart';
import 'dart:math';

class Habit {
  final String id;
  final String name;
  final String category;
  final int coins;
  final String frequency;
  final List<int>? customDays; // e.g., [1, 3, 5] for Mon, Wed, Fri
  bool completed;
  DateTime? lastCompleted;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.coins,
    required this.frequency,
    this.customDays,
    this.completed = false,
    this.lastCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'coins': coins,
      'frequency': frequency,
      'customDays': customDays,
      'completed': completed,
      'lastCompleted': lastCompleted?.toIso8601String(),
    };
  }

  static Habit fromMap(Map<String, dynamic> data) {
    DateTime? parseLastCompleted(dynamic lastCompleted) {
      if (lastCompleted == null) return null;
      
      // Handle Timestamp from Firestore
      if (lastCompleted is Timestamp) {
        return lastCompleted.toDate();
      }
      
      // Handle string (ISO8601 format)
      if (lastCompleted is String) {
        return DateTime.tryParse(lastCompleted);
      }
      
      return null;
    }

    return Habit(
      id: data['id'],
      name: data['name'],
      category: data['category'],
      coins: data['coins'],
      frequency: data['frequency'] ?? 'Daily',
      customDays: data['customDays'] != null ? List<int>.from(data['customDays']) : null,
      completed: data['completed'] ?? false,
      lastCompleted: parseLastCompleted(data['lastCompleted']),
    );
  }
}

class HabitProvider with ChangeNotifier {
  final List<Habit> _habits = [];
  int _dayStreak = 0;
  DateTime? _lastLoginDate;
  bool categoriesLoaded = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<Habit>> _groupedHabits = {};
  final Map<String, String> _categoryColorCache = {}; // {categoryKey: hexColor}

  // Predefined vibrant colors (red, blue, purple, pink, cyan, orange)
  final List<String> _vibrantColors = [
    '#D32F2F', // red
    '#1976D2', // blue
    '#512DA8', // deep purple
    '#AD1457', // pink
    '#00838F', // cyan
    '#F57C00', // orange
  ];

  List<Habit> get habits => [..._habits];
  int get dayStreak => _dayStreak;
  Map<String, List<Habit>> get groupedHabits => _groupedHabits;
  Map<String, Map<String, String>> get categoryStyleCache => {}; // This getter is no longer needed

  // Category Style Helpers
  // iconForCategory is no longer needed, but kept to avoid refactor elsewhere.
  IconData iconForCategory(String category) => Icons.circle;

  Color colorForCategory(String category) {
    final key = category.toLowerCase().trim();
    final hex = _categoryColorCache[key] ?? '#607D8B';
    return _colorFromHex(hex);
  }

  String sanitizeCategory(String raw) {
    if (raw.contains(',')) {
      return raw.split(',').first.trim();
    }
    return raw.trim();
  }

  // Convert Material icon name string to IconData

  // Convert hex string to Color
  Color _colorFromHex(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
    return const Color(0xFF607D8B);
  }

  void _updateGroupedHabits() {
    _checkDailyReset();
    
    final Map<String, List<Habit>> map = {};
    // Remove unused variable currentWeekday
    // final currentWeekday = DateTime.now().weekday;

    for (final habit in _habits) {
      bool shouldShow = false;
      switch (habit.frequency) {
        case 'Daily':
          shouldShow = true;
          break;
        case 'Weekly':
          // Show if it's been a week or since the last completion
          if (habit.lastCompleted == null || DateTime.now().difference(habit.lastCompleted!).inDays >= 7) {
            shouldShow = true;
          }
          break;
        case 'Monthly':
          if (habit.lastCompleted == null || (DateTime.now().month != habit.lastCompleted!.month || DateTime.now().year != habit.lastCompleted!.year)) {
            shouldShow = true;
          }
          break;
        case 'Custom':
          if (habit.customDays?.contains(DateTime.now().weekday) ?? false) {
            shouldShow = true;
          }
          break;
      }

      if (shouldShow) {
        map.putIfAbsent(habit.category, () => []);
        map[habit.category]!.add(habit);
      }
    }

    // Sort inside each category - uncompleted first
    map.forEach((key, list) {
      list.sort((a, b) {
        if (a.completed == b.completed) return 0;
        return a.completed ? 1 : -1;
      });
    });

    // Sort categories - ones with uncompleted tasks first
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        final aHasUncompleted = map[a]!.any((h) => !h.completed);
        final bHasUncompleted = map[b]!.any((h) => !h.completed);
        if (aHasUncompleted == bHasUncompleted) return 0;
        return aHasUncompleted ? -1 : 1;
      });

    _groupedHabits = {for (final key in sortedKeys) key: map[key]!};
    notifyListeners();
  }

  Future<void> loadStreakFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('User not signed in — skipping streak load.');
      return;
    }

    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      final now = DateTime.now();

      if (!doc.exists) {
        _dayStreak = 1;
        _lastLoginDate = now;
        await docRef.set({
          'dayStreak': _dayStreak,
          'lastLoginDate': now.toIso8601String(),
        });
      } else {
        _dayStreak = doc['dayStreak'] ?? 0;
        final lastDateRaw = doc['lastLoginDate'] ?? now.toIso8601String();
        _lastLoginDate = DateTime.tryParse(lastDateRaw);

        if (_lastLoginDate != null) {
          final diff = now.difference(_lastLoginDate!).inDays;
          if (diff == 1) {
            _dayStreak++;
          } else if (diff > 1) {
            _dayStreak = 1;
          }
          await docRef.set({
            'dayStreak': _dayStreak,
            'lastLoginDate': now.toIso8601String(),
          });
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Firestore exception: $e');
    }
  }

  Future<void> loadUserStatsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        _dayStreak = 0;
        _lastLoginDate = null;
        await docRef.set({
          'dayStreak': _dayStreak,
          'lastLoginDate': null,
        });
      } else {
        _dayStreak = doc['dayStreak'] ?? 0;
        final lastDateRaw = doc['lastLoginDate'];
        _lastLoginDate = lastDateRaw != null ? DateTime.tryParse(lastDateRaw) : null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Firestore exception (user stats): $e');
    }
  }

  Future<void> updateStreakInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'dayStreak': _dayStreak,
        'lastLoginDate': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Error updating streak in Firestore: $e');
    }
  }

  // --- Firestore Task Sync ---
  Future<void> loadTasksFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).collection('tasks').get();
      _habits.clear();
      for (final doc in snapshot.docs) {
        _habits.add(Habit.fromMap(doc.data()));
      }
      _updateGroupedHabits();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading tasks from Firestore: $e');
    }
  }

  Future<void> saveTaskToFirestore(Habit habit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).collection('tasks').doc(habit.id).set(habit.toMap());
    } catch (e) {
      debugPrint('❌ Error saving task to Firestore: $e');
    }
  }

  Future<void> deleteTaskFromFirestore(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).collection('tasks').doc(id).delete();
    } catch (e) {
      debugPrint('❌ Error deleting task from Firestore: $e');
    }
  }

  // Save a category to Firestore
  Future<void> saveCategoryToFirestore(String category, String color, String icon) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).collection('categories').doc(category).set({
        'color': color,
        'icon': icon,
      });
    } catch (e) {
      debugPrint('❌ Error saving category to Firestore: $e');
    }
  }

  // Load all categories from Firestore
  Future<void> loadCategoriesFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final snapshot = await _firestore.collection('users').doc(user.uid).collection('categories').get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final key = doc.id.toLowerCase().trim();
        _categoryColorCache[key] = data['color'] ?? '#607D8B';
      }
      categoriesLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading categories from Firestore: $e');
    }
  }

  Future<void> addCategory(String category, {String? color, String? icon}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final key = category.toLowerCase().trim();
    if (_categoryColorCache.containsKey(key)) return;

    // Assign random vibrant color if not provided
    final random = Random();
    final assignedColor = color ?? _vibrantColors[random.nextInt(_vibrantColors.length)];
    final assignedIcon = icon ?? '';

    _categoryColorCache[key] = assignedColor;
    notifyListeners();

    try {
      await saveCategoryToFirestore(category, assignedColor, assignedIcon);
    } catch (e) {
      debugPrint('❌ Error saving category: $e');
    }
  }

  Future<void> addHabitAI(String name, String frequency, {String? userCategory, List<int>? customDays}) async {
    try {
      String category;
      int coins = 5;
      
      if (userCategory != null && userCategory.trim().isNotEmpty) {
        category = sanitizeCategory(userCategory);
        await addCategory(category);
      } else {
        final gemini = GeminiService();
        final result = await gemini.getTaskAndCategoryStyle(name, _categoryColorCache.keys.toList());
        category = sanitizeCategory(result['category'] ?? 'General');
        coins = result['coins'] ?? 5;
        await addCategory(category);
      }

      final newHabit = Habit(
        id: DateTime.now().toIso8601String(),
        name: name,
        category: category,
        coins: coins,
        frequency: frequency,
        customDays: customDays,
      );

      _habits.add(newHabit);
      await saveTaskToFirestore(newHabit);
      _updateGroupedHabits();

    } catch (e, st) {
      debugPrint('❌ Error in addHabitAI: $e\n$st');
    }
  }

  void toggleHabit(String id) {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index == -1) return;
    final habit = _habits[index];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool shouldUpdateStreak = false;
    if (!habit.completed) { // Only when completing a task
      if (_lastLoginDate == null) {
        // First ever completion
        _dayStreak = 1;
        _lastLoginDate = now;
        shouldUpdateStreak = true;
      } else {
        final lastLoginDay = DateTime(_lastLoginDate!.year, _lastLoginDate!.month, _lastLoginDate!.day);
        final diff = today.difference(lastLoginDay).inDays;
        if (diff == 1) {
          // Consecutive day, increment streak
          _dayStreak++;
          _lastLoginDate = now;
          shouldUpdateStreak = true;
        } else if (diff > 1) {
          // Missed one or more days, reset streak
          _dayStreak = 1;
          _lastLoginDate = now;
          shouldUpdateStreak = true;
        } else if (diff == 0) {
          // Already completed today, do not update streak
        }
      }
    }
    habit.completed = !habit.completed;
    final user = FirebaseAuth.instance.currentUser;
    if (habit.completed) {
      habit.lastCompleted = now;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'coins': FieldValue.increment(habit.coins),
        });
      }
    } else {
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'coins': FieldValue.increment(-habit.coins),
        });
      }
    }
    if (shouldUpdateStreak) {
      updateStreakInFirestore();
    }
    saveTaskToFirestore(habit);
    _updateGroupedHabits();
    notifyListeners();
  }

  void _checkDailyReset() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final habit in _habits) {
      bool shouldReset = false;
      if (habit.lastCompleted != null) {
        final lastCompletedDate = DateTime(
          habit.lastCompleted!.year,
          habit.lastCompleted!.month,
          habit.lastCompleted!.day,
        );

        if (lastCompletedDate.isBefore(today)) {
          switch (habit.frequency) {
            case 'Daily':
              shouldReset = true;
              break;
            case 'Weekly':
              // Resets if a week has passed
              if (now.difference(lastCompletedDate).inDays >= 7) {
                shouldReset = true;
              }
              break;
            case 'Monthly':
              // Resets if a month has passed
              if (now.month != lastCompletedDate.month || now.year != lastCompletedDate.year) {
                shouldReset = true;
              }
              break;
            case 'Custom':
              // Always reset for custom habits if the day has passed,
              // visibility is handled in _updateGroupedHabits
              shouldReset = true;
              break;
          }
        }
      }

      if (shouldReset) {
        habit.completed = false;
        habit.lastCompleted = null;
        saveTaskToFirestore(habit);
      }
    }
    loadUserStatsFromFirestore(); // This will update streak if needed
  }

  void deleteHabit(String id) {
    _habits.removeWhere((habit) => habit.id == id);
    deleteTaskFromFirestore(id);
    _updateGroupedHabits();
    notifyListeners();
  }

  void clearAll() {
    _habits.clear();
    _dayStreak = 0;
    _lastLoginDate = null;
    _groupedHabits = {};
    _categoryColorCache.clear(); // Clear cached colors
    notifyListeners();
  }

  Future<void> deleteCategoryFromFirestore(String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final key = category.toLowerCase().trim();
    try {
      await _firestore.collection('users').doc(user.uid).collection('categories').doc(category).delete();
      _categoryColorCache.remove(key);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error deleting category from Firestore: $e');
    }
  }
}

