import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  final bool isBecomingMaster;

  const EditProfileScreen({super.key, this.isBecomingMaster = false});

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
  String? _profileImageUrl;
  bool _isLoading = false;
  String? _errorMessage;
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    _specializationsController.dispose();
    _hourlyRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final DocumentSnapshot userDoc = await FirebaseFirestore.instance
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
          
          if (widget.isBecomingMaster && userData['role'] != 'majstor') {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .update({'role': 'majstor'});
          }
        }
      } catch (e) {
        setState(() => _errorMessage = 'Došlo je do greške pri učitavanju podataka.');
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

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
      String? uploadedImageUrl = _profileImageUrl;

      if (_profileImage != null) {
        try {
          uploadedImageUrl = await _storageService.uploadProfileImage(
            user!.uid,
            _profileImage!,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Greška pri upload-u slike: $e')),
          );
        }
      }

      try {
        List<String> specializations = [];
        if (_specializationsController.text.isNotEmpty) {
          specializations = _specializationsController.text
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }

        final double? hourlyRate = _hourlyRateController.text.isNotEmpty
            ? double.tryParse(_hourlyRateController.text)
            : null;

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'displayName': _displayNameController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'address': _addressController.text.trim(),
          'specializations': specializations,
          'hourlyRate': hourlyRate,
          'description': _descriptionController.text.trim(),
          'profileImageUrl': uploadedImageUrl,
          if (widget.isBecomingMaster) 'role': 'majstor',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil je uspješno ažuriran!')),
        );

        if (widget.isBecomingMaster) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/majstor_dashboard',
            (route) => false,
          );
        } else {
          Navigator.of(context).pop();
        }
      } catch (e) {
        setState(() => _errorMessage = 'Došlo je do greške pri ažuriranju profila: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isBecomingMaster ? 'Postani majstor' : 'Uredi profil',
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Pokušaj ponovo'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile Picture
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : _profileImageUrl != null
                                        ? NetworkImage(_profileImageUrl!)
                                        : const AssetImage('assets/avatar.jpg') as ImageProvider,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Display Name
                        TextFormField(
                          controller: _displayNameController,
                          decoration: const InputDecoration(
                            labelText: 'Ime i prezime',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Unesite vaše ime i prezime';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Phone Number
                        TextFormField(
                          controller: _phoneNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Broj telefona',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        // Address
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Adresa',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Master fields (if becoming master)
                        if (widget.isBecomingMaster) ...[
                          const Divider(height: 40),
                          const Text(
                            'Informacije o majstoru',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _specializationsController,
                            decoration: const InputDecoration(
                              labelText: 'Specijalizacije *',
                              hintText: 'npr. vodoinstalater, električar, keramičar',
                              prefixIcon: Icon(Icons.build),
                            ),
                            validator: (value) {
                              if (widget.isBecomingMaster && (value == null || value.trim().isEmpty)) {
                                return 'Specijalizacije su obavezne za majstore';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _hourlyRateController,
                            decoration: const InputDecoration(
                              labelText: 'Cijena po satu (KM)',
                              hintText: 'Vaša satnica',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final rate = double.tryParse(value);
                                if (rate == null || rate <= 0) {
                                  return 'Unesite valjan iznos';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Opis vašeg iskustva *',
                              hintText: 'Opišite svoje iskustvo, kvalifikacije...',
                              prefixIcon: Icon(Icons.description),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (widget.isBecomingMaster) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Opis je obavezan za majstore';
                                }
                                if (value.trim().length < 20) {
                                  return 'Opis mora imati najmanje 20 karaktera';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),
                          Card(
                            color: Colors.blue.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.blue,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Postajete majstor!',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Molimo popunite sve potrebne informacije kako biste mogli primati zahtjeve za poslove.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Save Button
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveProfile,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _isLoading 
                                ? 'Spremam...' 
                                : widget.isBecomingMaster 
                                    ? 'Postani majstor'
                                    : 'Spremi izmjene',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}