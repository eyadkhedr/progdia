import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/habit_provider.dart';
import 'providers/friends_provider.dart';
import 'screens/auth_gate.dart';  // if you split AuthGate out
// or if AuthGate is in main.dart, import nothing extra

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Init Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2) Enter immersive sticky mode (full screen)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => FriendsProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Poppins', // ✅ Use Google Fonts or custom font
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 140, 23, 89), // Neutral blue-grey
            primary: const Color.fromARGB(255, 224, 160, 72),
            secondary: const Color(0xFFFF9800),
            surface: const Color(0xFFF9F9F9),
            error: const Color(0xFFF44336),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF9F9F9),
          textTheme: const TextTheme(
            titleLarge: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Color(0xFF333333),
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              color: Color(0xFF333333),
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              color: Color(0xFF333333),
            ),
          ),
          extensions: <ThemeExtension<dynamic>>[
            const AppColors(
              tasks: Color(0xFF03A9F4),
              calendar: Color(0xFFFF9800),
              friends: Color(0xFF9C27B0),
              tournament: Color(0xFFFF5722),
              profile: Color(0xFF00BCD4),
            ),
          ],
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AppColors extends ThemeExtension<AppColors> {
  final Color tasks;
  final Color calendar;
  final Color friends;
  final Color tournament;
  final Color profile;

  const AppColors({
    required this.tasks,
    required this.calendar,
    required this.friends,
    required this.tournament,
    required this.profile,
  });

  @override
  AppColors copyWith({
    Color? tasks,
    Color? calendar,
    Color? friends,
    Color? tournament,
    Color? profile,
  }) {
    return AppColors(
      tasks: tasks ?? this.tasks,
      calendar: calendar ?? this.calendar,
      friends: friends ?? this.friends,
      tournament: tournament ?? this.tournament,
      profile: profile ?? this.profile,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      tasks: Color.lerp(tasks, other.tasks, t)!,
      calendar: Color.lerp(calendar, other.calendar, t)!,
      friends: Color.lerp(friends, other.friends, t)!,
      tournament: Color.lerp(tournament, other.tournament, t)!,
      profile: Color.lerp(profile, other.profile, t)!,
    );
  }
}

