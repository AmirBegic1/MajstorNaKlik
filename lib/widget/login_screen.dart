import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/login_provider.dart'; // Putanja do vašeg LoginProvider fajla
import '../main.dart'; // Za konstantne boje (ako koristite)

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loginProvider = Provider.of<LoginProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.9;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: containerWidth,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8.0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: loginProvider.formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/logo.png', // Putanja do vašeg logotipa
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.build,
                          size: 80,
                          color: primaryBlue,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Dobrodošli!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Prijavite se na vaš nalog',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24.0),
                  TextFormField(
                    controller: loginProvider.emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: loginProvider.emailValidator,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: loginProvider.passwordController,
                    obscureText: true,
                    validator: loginProvider.passwordValidator,
                    decoration: const InputDecoration(
                      hintText: 'Šifra',
                      prefixIcon: Icon(Icons.lock_outline, color: primaryBlue),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Consumer<LoginProvider>(
                    builder: (context, provider, _) {
                      return provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                            onPressed: () {
                              provider.login(context);
                            },
                            child: const Text('Prijava'),
                          );
                    },
                  ),
                  if (loginProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        loginProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implementirajte navigaciju ka stranici za reset lozinke
                        print('Navigacija ka reset lozinke');
                      },
                      child: const Text('Zaboravljena šifra?'),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Nemate račun?',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implementirajte navigaciju ka stranici za registraciju
                          Navigator.of(context).pushNamed(
                            '/register',
                          ); // Ako ste podesili rutu u main.dart
                          print('Navigacija ka registraciji');
                        },
                        child: const Text('Registrujte se'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
