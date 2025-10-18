import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SignUp
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception("This Email has been registered.");
        case 'invalid-email':
          throw Exception("Invalid Email Address.");
        case 'weak-password':
          throw Exception("Password is too weak, Choose a stronger password.");
        default:
          throw Exception("Sign Up Failed. Please Try Again.");
      }
    }
  }

  // SignIn
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
          throw Exception("Password or Email is Incorrect.");
        case 'invalid-email':
          throw Exception("Invalid Email Address.");
        case 'user-disabled':
          throw Exception("This account has been disabled.");
        default:
          throw Exception("Login Failed. Please Try Again.");
      }
    }
  }

  // LogOut
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;
}