import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quiz_app/theme/theme.dart';
import 'package:quiz_app/view/admin/admin_home_screen.dart';
import 'package:quiz_app/view/user/home_screen.dart';
import 'package:quiz_app/view/user/login_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Quiz App",
      theme: AppTheme.theme,
      home: const AuthWrapper(),
    );
  }
}
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2️ Đã đăng nhập
        if (snapshot.hasData) {
          // Đã đăng nhập
          return const HomeScreen();
        } else {
          // Chưa đăng nhập
          return const LoginScreen();
        }
      },
    );
  }
}
