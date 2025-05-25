import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegistrationProvider extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> register(BuildContext context) async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (passwordController.text != confirmPasswordController.text) {
      errorMessage = 'Lozinke se ne podudaraju.';
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      // Uspješna registracija - ovdje možete navigirati na ekran za prijavu ili neki drugi ekran
      print('Registracija uspješna!');
      // Možda prikažete SnackBar i preusmjerite na login ekran
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registracija uspješna! Molimo prijavite se.'),
        ),
      );
      Navigator.of(context).pop(); // Vratite se na login ekran
    } on FirebaseAuthException catch (e) {
      errorMessage = _handleFirebaseAuthError(e.code);
      print('Firebase Auth Error (Registration): ${e.code} - ${e.message}');
      // Prikazati error poruku korisniku putem SnackBar-a ili na UI-u
    } catch (e) {
      errorMessage = 'Došlo je do neočekivane greške prilikom registracije.';
      print('Unexpected registration error: $e');
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

  String? confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Potvrdite lozinku';
    }
    if (value != passwordController.text) {
      return 'Lozinke se ne podudaraju';
    }
    return null;
  }

  String _handleFirebaseAuthError(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Korisnik sa ovim emailom već postoji.';
      case 'invalid-email':
        return 'Format email adrese nije validan.';
      case 'weak-password':
        return 'Lozinka je preslaba.';
      default:
        return 'Došlo je do greške prilikom registracije. Pokušajte ponovo.';
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
