import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quiz_app/theme/theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:quiz_app/view/user/home_screen.dart';
import 'package:quiz_app/view/user/login_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, //Đảm bảo dùng đúng file cấu hình Firebase
  );
  // Load file .env
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded successfully!");
  } catch (e) {
    print("❌ Failed to load .env: $e");
  }
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
        //Khi đang chờ kết nối Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        //Nếu người dùng đã đăng nhập
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        //Nếu người dùng đã logout hoặc chưa đăng nhập
        return const LoginScreen();
      },
    );
  }
}
