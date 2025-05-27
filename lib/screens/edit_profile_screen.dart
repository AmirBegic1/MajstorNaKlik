import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  File? _profileImage;
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
          // TODO: Učitajte trenutnu sliku profila ako postoji
        }
      } catch (e) {
        setState(
          () => _errorMessage = 'Došlo je do greške pri učitavanju podataka.',
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final User? user = FirebaseAuth.instance.currentUser;
      String? profileImageUrl;

      if (_profileImage != null) {
        try {
          final firebase_storage.Reference storageRef = firebase_storage
              .FirebaseStorage
              .instance
              .ref()
              .child(
                'users/${user!.uid}/profile.jpg',
              ); // Naziv slike može biti jedinstveniji

          await storageRef.putFile(_profileImage!);
          profileImageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          setState(
            () => _errorMessage = 'Došlo je do greške pri učitavanju slike: $e',
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
              'displayName': _displayNameController.text.trim(),
              if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
              // TODO: Dodajte ostala polja za uređivanje
            });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil uspješno ažuriran.')),
        );
        Navigator.of(context).pop(); // Vratite se na ekran profila
      } catch (e) {
        setState(
          () => _errorMessage = 'Došlo je do greške pri ažuriranju profila: $e',
        );
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
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : const AssetImage('assets/avatar.jpg')
                                      as ImageProvider, // Koristite defaultnu sliku
                        ),
                      ),
                      const SizedBox(height: 20.0),
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
                      ),
                      const SizedBox(height: 20.0),
                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Adresa'),
                      ),
                      const SizedBox(height: 20.0),
                      // TODO: Dodajte ostala polja za uređivanje (broj telefona, adresa, specijalizacije itd.)
                    ],
                  ),
                ),
              ),
    );
  }
}
