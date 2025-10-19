import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../providers/habit_provider.dart';
import 'main_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final habitProvider = Provider.of<HabitProvider>(context, listen: false);
      await habitProvider.loadUserStatsFromFirestore();
      await habitProvider.loadTasksFromFirestore();
      await habitProvider.loadCategoriesFromFirestore();
    }

    setState(() {
      _isLoggedIn = user != null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return _isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}
