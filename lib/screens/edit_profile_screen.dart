import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data() as Map<String, dynamic>;
          _displayNameController.text = userData['displayName'] ?? '';
          _phoneNumberController.text = userData['phoneNumber'] ?? '';
        }
      } catch (e) {
        setState(
          () => _errorMessage = 'Došlo je do greške pri učitavanju podataka.',
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
                'displayName': _displayNameController.text.trim(),
                'phoneNumber': _phoneNumberController.text.trim(),
                // Dodajte ostala polja za uređivanje po potrebi
              });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profil uspješno ažuriran.')),
          );
          Navigator.of(context).pop(); // Vratite se na ekran profila
        } catch (e) {
          setState(
            () =>
                _errorMessage = 'Došlo je do greške pri ažuriranju profila: $e',
          );
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uredi profil'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveProfile),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ime i prezime',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Unesite vaše ime i prezime';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _phoneNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Broj telefona',
                        ),
                        keyboardType: TextInputType.phone,
                        // Dodajte validaciju za broj telefona ako je potrebno
                      ),
                      const SizedBox(height: 20.0),
                      // Ovdje možete dodati i druga polja za uređivanje
                    ],
                  ),
                ),
              ),
    );
  }
}
