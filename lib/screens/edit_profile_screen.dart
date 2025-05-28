import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class EditProfileScreen extends StatefulWidget {
  final bool isBecomingMaster;

  const EditProfileScreen({Key? key, this.isBecomingMaster = false})
    : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _specializationsController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _profileImage;
  String? _profileImageUrl; // Za pohranu trenutnog URL-a slike
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
          _addressController.text = userData['address'] ?? '';
          _specializationsController.text =
              (userData['specializations'] as List?)?.join(', ') ?? '';
          _hourlyRateController.text = userData['hourlyRate']?.toString() ?? '';
          _descriptionController.text = userData['description'] ?? '';
          _profileImageUrl = userData['profileImageUrl'];
          // Ako korisnik postaje majstor, postavite rolu
          if (widget.isBecomingMaster && userData['role'] != 'majstor') {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'role': 'majstor'});
          }
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
      String? uploadedImageUrl =
          _profileImageUrl; // Zadrži trenutni URL ako se ne učita nova slika

      if (_profileImage != null) {
        try {
          final firebase_storage.Reference storageRef = firebase_storage
              .FirebaseStorage
              .instance
              .ref()
              .child('users/${user!.uid}/profile.jpg');

          await storageRef.putFile(_profileImage!);
          uploadedImageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          setState(
            () => _errorMessage = 'Došlo je do greške pri učitavanju slike: $e',
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      try {
        Map<String, dynamic> updateData = {
          'displayName': _displayNameController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'address': _addressController.text.trim(),
          'specializations':
              _specializationsController.text
                  .trim()
                  .split(',')
                  .map((s) => s.trim())
                  .toList(),
          'hourlyRate':
              _hourlyRateController.text.isNotEmpty
                  ? double.tryParse(_hourlyRateController.text.trim())
                  : null,
          'description': _descriptionController.text.trim(),
          if (uploadedImageUrl != null) 'profileImageUrl': uploadedImageUrl,
        };
        // Postavi rolu na majstor ako je korisnik potvrdio
        if (widget.isBecomingMaster) {
          updateData['role'] = 'majstor';
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update(updateData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil uspješno ažuriran.')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        setState(
          () => _errorMessage = 'Došlo je do greške pri ažuriranju profila: $e',
        );
      }
      setState(() => _isLoading = false);
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
                                  : _profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                  : const AssetImage('assets/avatar.jpg')
                                      as ImageProvider,
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
                      if (widget.isBecomingMaster ||
                          _specializationsController.text.isNotEmpty)
                        TextFormField(
                          controller: _specializationsController,
                          decoration: const InputDecoration(
                            labelText: 'Specijalizacije (odvojene zarezom)',
                          ),
                        ),
                      const SizedBox(height: 20.0),
                      if (widget.isBecomingMaster ||
                          _hourlyRateController.text.isNotEmpty)
                        TextFormField(
                          controller: _hourlyRateController,
                          decoration: const InputDecoration(
                            labelText: 'Cijena po satu',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      const SizedBox(height: 20.0),
                      if (widget.isBecomingMaster ||
                          _descriptionController.text.isNotEmpty)
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Opis'),
                          maxLines: 3,
                        ),
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
    );
  }
}
