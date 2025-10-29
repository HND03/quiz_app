import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_app/theme/theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:quiz_app/view/user/home_screen.dart';
import 'package:quiz_app/view/user/login_screen.dart';
import 'firebase_options.dart';
import 'model/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await dotenv.load(fileName: ".env");

  // 🔹 Đọc theme mode được lưu trong SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('themeMode') ?? 'light';
  final themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

  await NotificationService.initialize();
  await NotificationService.requestPermission();

  runApp(MyApp(initialThemeMode: themeMode));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const MyApp({super.key, required this.initialThemeMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  /// 🔹 Hàm đổi theme (Light <-> Dark)
  Future<void> _toggleTheme(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode == ThemeMode.dark ? 'dark' : 'light');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Quiz App",
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: AuthWrapper(onThemeChanged: _toggleTheme),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final Function(ThemeMode)? onThemeChanged;
  const AuthWrapper({super.key, this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return HomeScreen(onThemeChanged: onThemeChanged);
        } else {
          return LoginScreen(onThemeChanged: onThemeChanged);
        }
      },
    );
  }
}
