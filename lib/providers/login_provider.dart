import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:majstor_na_klik_app/screens/majstor_dashboard.dart';
import 'package:majstor_na_klik_app/screens/user_home_screen.dart';

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
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
      final User? user = userCredential.user;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final String role = userData['role'];

          if (role == 'korisnik') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserHomeScreen()),
            );
          } else if (role == 'majstor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MajstorDashboard()),
            );
          } else {
            // Ako uloga nije definisana ili je nepoznata, preusmjerite na neki default ekran ili prikažite grešku
            print('Nepoznata uloga korisnika.');
            // Možda navigirate na ekran za ažuriranje profila ili prikažete poruku
          }
        } else {
          print('Podaci o korisniku nisu pronađeni u Firestore.');
          // Možda navigirate na ekran za ažuriranje profila
        }
      }
      print('Prijava uspješna!');
    } on FirebaseAuthException catch (e) {
      errorMessage = _handleFirebaseAuthError(e.code);
      print('Firebase Auth Error: ${e.code} - ${e.message}');
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
