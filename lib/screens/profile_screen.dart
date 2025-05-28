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
                    Center(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            _userData?['profileImageUrl'] != null
                                ? NetworkImage(
                                  _userData!['profileImageUrl'] as String,
                                )
                                : const AssetImage('assets/avatar.jpg')
                                    as ImageProvider, // Dodajte defaultnu sliku u assets
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
                    // Dodatne informacije specifične za majstora
                    if (_userData?['role'] == 'majstor') ...[
                      if (_userData?['specializations'] != null)
                        ListTile(
                          leading: const Icon(Icons.build),
                          title: Text(
                            (_userData!['specializations'] as List).join(', '),
                          ),
                        ),
                      if (_userData?['hourlyRate'] != null)
                        ListTile(
                          leading: const Icon(Icons.attach_money),
                          title: Text(
                            'Cijena po satu: ${_userData!['hourlyRate']}',
                          ),
                        ),
                      if (_userData?['description'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Text(
                            'Opis: ${_userData!['description']}',
                            style: const TextStyle(fontSize: 16.0),
                          ),
                        ),
                      // TODO: Prikaz galerije radova
                    ],
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
                    const SizedBox(height: 20.0),
                    const Text(
                      'Napredne opcije',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    ListTile(
                      leading: const Icon(Icons.construction),
                      title: const Text('Želim postati majstor'),
                      onTap: () {
                        // TODO: Implementirajte logiku za prelazak na majstora
                        _showBecomeMasterDialog(context);
                      },
                    ),
                    // Dodatne opcije specifične za majstora (kasnije)
                  ],
                ),
              ),
    );
  }
}

void _showBecomeMasterDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Postani majstor?'),
        content: const Text(
          'Želite li se registrirati kao majstor? Nakon potvrde, moći ćete unijeti dodatne informacije o vašim vještinama i uslugama.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Odustani'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Potvrdi'),
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToEditProfileForMaster(context);
            },
          ),
        ],
      );
    },
  );
}

void _navigateToEditProfileForMaster(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const EditProfileScreen(isBecomingMaster: true),
    ),
  );
}
