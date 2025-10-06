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

// Modern Color Palette
const Color primaryBlue = Color(0xFF1976D2);
const Color primaryBlueLight = Color(0xFF42A5F5);
const Color primaryBlueDark = Color(0xFF0D47A1);
const Color accentOrange = Color(0xFFFF9800);
const Color accentOrangeLight = Color(0xFFFFB74D);
const Color accentGreen = Color(0xFF4CAF50);
const Color accentRed = Color(0xFFE57373);
const Color surfaceGrey = Color(0xFFF5F5F5);
const Color cardGrey = Color(0xFFFAFAFA);

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          secondary: accentOrange,
          surface: surfaceGrey,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardGrey,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: accentOrange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 16),
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: surfaceGrey,
          selectedColor: primaryBlue,
          labelStyle: const TextStyle(color: Colors.black87),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.black54,
          ),
        ),
        scaffoldBackgroundColor: surfaceGrey,
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
  const AuthCheck({super.key});

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
