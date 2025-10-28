import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../model/authsevice.dart';
import '../../theme/theme.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final Function(ThemeMode)? onThemeChanged;
  const SignupScreen({Key? key, this.onThemeChanged}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // 🔥 Đảm bảo user được đồng bộ ngay lập tức
      await user?.reload();
      user = _authService.currentUser; // lấy lại currentUser mới nhất

      if (user != null && mounted) {
        await _authService.signOut(); // đảm bảo không còn trạng thái cũ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Sign up successful! Please log in.")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LoginScreen(onThemeChanged: widget.onThemeChanged),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor =
    isDark ? AppTheme.darkBackgroundColor : AppTheme.backgroundColor;
    final cardColor = isDark ? AppTheme.darkCardColor : Colors.white;
    final textColor =
    isDark ? AppTheme.darkTextPrimaryColor : AppTheme.textPrimaryColor;
    final secondaryTextColor =
    isDark ? AppTheme.darkTextSecondaryColor : AppTheme.textSecondaryColor;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Color(0xFF0D0D0D),
              Color(0xFF121212),
              Color(0xFF1E1E1E),
            ],
          )
              : LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.primaryColor.withOpacity(0.5),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 60),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Sign Up",
                      style: TextStyle(color: Colors.white, fontSize: 40),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Create Your Account",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                height: 600,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: !isDark
                                ? const [
                              BoxShadow(
                                color: Color.fromRGBO(130, 177, 255, 1.0),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ]: [],
                          ),
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                controller: _emailController,
                                style: TextStyle(color: textColor),
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter your email'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                style: TextStyle(color: textColor),
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Please enter your password'
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                style: TextStyle(color: textColor),
                                decoration: const InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(Icons.lock_reset_outlined),
                                ),
                                validator: (value) => value!.isEmpty
                                    ? 'Please confirm your password'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Sign Up',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(
                                  onThemeChanged: widget.onThemeChanged,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Already have an account? Log in",
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
