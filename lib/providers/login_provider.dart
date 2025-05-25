import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginProvider extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> login(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      // Uspješna prijava - ovdje možete navigirati na sljedeći ekran
      print('Prijava uspješna!');
    } on FirebaseAuthException catch (e) {
      errorMessage = _handleFirebaseAuthError(e.code);
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      // Prikazati error poruku korisniku putem SnackBar-a ili na UI-u
    } catch (e) {
      errorMessage = 'Došlo je do neočekivane greške.';
      print('Unexpected login error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email je obavezan';
    }
    final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Unesite validan email format';
    }
    return null;
  }

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lozinka je obavezna';
    }
    if (value.length < 6) {
      return 'Lozinka mora imati najmanje 6 karaktera';
    }
    return null;
  }

  String _handleFirebaseAuthError(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Korisnik sa ovim emailom nije pronađen.';
      case 'wrong-password':
        return 'Pogrešna email adresa ili lozinka.';
      case 'invalid-email':
        return 'Format email adrese nije validan.';
      case 'user-disabled':
        return 'Ovaj nalog je onemogućen.';
      default:
        return 'Došlo je do greške pri prijavi. Pokušajte ponovo.';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
