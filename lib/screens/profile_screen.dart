import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:majstor_na_klik_app/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _user = FirebaseAuth.instance.currentUser;
    });

    if (_user != null) {
      try {
        final DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_user!.uid)
                .get();
        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            _userData = userDoc.data() as Map<String, dynamic>;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Podaci o korisniku nisu pronađeni.';
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Došlo je do greške prilikom učitavanja profila: $e';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Niste prijavljeni.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Nakon odjave, AuthCheck u main.dart će preusmjeriti na LoginScreen
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
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
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text(_userData?['email'] ?? _user?.email ?? 'N/A'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(
                        _userData?['displayName'] ?? 'N/A',
                      ), // Pretpostavljamo da imate displayName
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(
                        _userData?['phoneNumber'] ?? 'N/A',
                      ), // Pretpostavljamo da imate phoneNumber
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      'Ostale opcije',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
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
