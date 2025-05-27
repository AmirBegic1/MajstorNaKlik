import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Nakon odjave, AuthCheck u main.dart će preusmjeriti na LoginScreen
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Center(
              child: CircleAvatar(
                radius: 60,
                child: Icon(Icons.person, size: 80),
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Osnovne informacije',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(user?.email ?? 'N/A'),
            ),
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Ime Prezime (korisničko ime)'), // Placeholder
            ),
            const ListTile(
              leading: Icon(Icons.phone),
              title: Text('+387 XX XXX XXX'), // Placeholder
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Ostale opcije',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10.0),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Postavke'),
              onTap: () {
                // TODO: Implementirajte navigaciju na postavke
                print('Otvori postavke');
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Pomoć i podrška'),
              onTap: () {
                // TODO: Implementirajte navigaciju na pomoć
                print('Otvori pomoć');
              },
            ),
            // Dodatne opcije specifične za majstora (kasnije)
          ],
        ),
      ),
    );
  }
}
