import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //Follow User Status
  Stream<User?> get userChanges => _auth.authStateChanges();

  //SignUp
  Future<User?> signUp(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'SignUp Failed. Please Try Again.';
    }
  }

  //SignIn
  Future<User?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login Failed. Please Check Your Information Again.';
    }
  }

  //Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}