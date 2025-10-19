@echo off
mkdir screens
mkdir widgets
mkdir providers

REM Create minimal files with basic structure
echo import 'package:flutter/material.dart'; > screens\home_screen.dart
echo class HomeScreen extends StatelessWidget { >> screens\home_screen.dart
echo   @override Widget build(BuildContext context) => Scaffold(); >> screens\home_screen.dart
echo } >> screens\home_screen.dart

echo import 'package:flutter/material.dart'; > screens\add_habit_screen.dart
echo class AddHabitScreen extends StatelessWidget { >> screens\add_habit_screen.dart
echo   @override Widget build(BuildContext context) => Scaffold(); >> screens\add_habit_screen.dart
echo } >> screens\add_habit_screen.dart

echo import 'package:flutter/material.dart'; > widgets\habit_card.dart
echo class HabitCard extends StatelessWidget { >> widgets\habit_card.dart
echo   @override Widget build(BuildContext context) => Card(); >> widgets\habit_card.dart
echo } >> widgets\habit_card.dart

echo import 'package:flutter/material.dart'; > widgets\character_widget.dart
echo class CharacterWidget extends StatelessWidget { >> widgets\character_widget.dart
echo   @override Widget build(BuildContext context) => Container(); >> widgets\character_widget.dart
echo } >> widgets\character_widget.dart

echo import 'package:flutter/material.dart'; > providers\habit_provider.dart
echo class HabitProvider with ChangeNotifier { >> providers\habit_provider.dart
echo   // Will hold habit data >> providers\habit_provider.dart
echo } >> providers\habit_provider.dart

echo import 'package:flutter/material.dart'; > main.dart
echo void main() => runApp(MyApp()); >> main.dart
echo class MyApp extends StatelessWidget { >> main.dart
echo   @override Widget build(BuildContext context) => MaterialApp(home: Scaffold()); >> main.dart
echo } >> main.dart

echo MVP foundation created! Start building with HabitProvider first.