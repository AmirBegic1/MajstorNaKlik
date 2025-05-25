import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/registration_provider.dart'; // Putanja do vašeg RegistrationProvider fajla

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final registrationProvider = Provider.of<RegistrationProvider>(context);
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
              key: registrationProvider.formKey,
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
                          color: Colors.blue,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Kreirajte novi račun',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Unesite svoje podatke za registraciju',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24.0),
                  TextFormField(
                    controller: registrationProvider.emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: registrationProvider.emailValidator,
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: registrationProvider.passwordController,
                    obscureText: true,
                    validator: registrationProvider.passwordValidator,
                    decoration: const InputDecoration(
                      hintText: 'Šifra',
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  TextFormField(
                    controller: registrationProvider.confirmPasswordController,
                    obscureText: true,
                    validator: registrationProvider.confirmPasswordValidator,
                    decoration: const InputDecoration(
                      hintText: 'Potvrdi šifru',
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Consumer<RegistrationProvider>(
                    builder: (context, provider, _) {
                      return provider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                            onPressed: () {
                              provider.register(context);
                            },
                            child: const Text('Registrujte se'),
                          );
                    },
                  ),
                  if (registrationProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        registrationProvider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Već imate račun?',
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop(); // Vratite se na login ekran
                          print('Povratak na login ekran');
                        },
                        child: const Text('Prijavite se'),
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
