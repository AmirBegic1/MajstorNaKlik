import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:majstor_na_klik_app/providers/login_provider.dart';
import 'package:majstor_na_klik_app/providers/registration_provider.dart';
import 'package:majstor_na_klik_app/screens/login_screen.dart';
import 'package:majstor_na_klik_app/screens/majstor_dashboard.dart';
import 'package:majstor_na_klik_app/screens/registration_screen.dart';
import 'package:majstor_na_klik_app/screens/user_home_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

const Color primaryBlue = Color(0xFF007BFF);
const Color accentOrange = Color(0xFFFFA500);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoginProvider()),
        ChangeNotifierProvider(create: (context) => RegistrationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Majstor na Klik.ba',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 12.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFF5F5F5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: primaryBlue, width: 2.0),
            borderRadius: BorderRadius.circular(8),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
            borderRadius: BorderRadius.circular(8),
          ),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: accentOrange),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
        ),
      ),
      home: const AuthCheck(),
      routes: {
        '/register': (context) => const RegistrationScreen(),
        '/user_home': (context) => const UserHomeScreen(),
        '/majstor_dashboard': (context) => const MajstorDashboard(),
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Prikažite loading dok se provjerava stanje
        }

        if (snapshot.hasData && snapshot.data != null) {
          // Korisnik je prijavljen, provjerite njegovu ulogu i preusmjerite
          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(snapshot.data!.uid)
                    .get(),
            builder: (
              BuildContext context,
              AsyncSnapshot<DocumentSnapshot> userSnapshot,
            ) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(); // Prikažite loading dok se dohvaćaju podaci o korisniku
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final String role = userData['role'];

                if (role == 'korisnik') {
                  return const UserHomeScreen();
                } else if (role == 'majstor') {
                  return const MajstorDashboard();
                } else {
                  // Nepoznata uloga ili podaci, vratite na login
                  return const LoginScreen();
                }
              } else {
                // Podaci o korisniku nisu pronađeni, vratite na login
                return const LoginScreen();
              }
            },
          );
        }

        // Korisnik nije prijavljen, prikažite login ekran
        return const LoginScreen();
      },
    );
  }
}
