import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './chat_screen.dart';

class MajstorDetailsScreen extends StatefulWidget {
  final String majstorId;

  const MajstorDetailsScreen({super.key, required this.majstorId});

  @override
  State<MajstorDetailsScreen> createState() => _MajstorDetailsScreenState();
}

class _MajstorDetailsScreenState extends State<MajstorDetailsScreen> {
  Map<String, dynamic>? _majstorData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMajstorData();
  }

  Future<void> _loadMajstorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _majstorData = null;
    });

    try {
      final DocumentSnapshot majstorDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.majstorId)
              .get();

      if (majstorDoc.exists && majstorDoc.data() != null) {
        setState(() {
          _majstorData = majstorDoc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Profil majstora nije pronađen.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Došlo je do greške prilikom učitavanja profila majstora: $e';
        _isLoading = false;
      });
    }
  }

  void _startChat(BuildContext context) async {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null && widget.majstorId.isNotEmpty) {
      final ChatService chatService = ChatService();
      final String? conversationId = await chatService.startChat(
        widget.majstorId,
      );
      if (conversationId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  conversationId: conversationId,
                  receiverUserId: widget.majstorId,
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Došlo je do greške pri pokretanju razgovora.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Niste prijavljeni ili je ID majstora nevažeći.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_majstorData?['displayName'] ?? 'Profil majstora'),
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
                            _majstorData?['profileImageUrl'] != null
                                ? NetworkImage(
                                  _majstorData!['profileImageUrl'] as String,
                                )
                                : const AssetImage('assets/default_profile.png')
                                    as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      _majstorData?['displayName'] ?? 'Ime majstora',
                      style: const TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    if (_majstorData?['specializations'] != null)
                      Text(
                        'Specijalizacije: (${(_majstorData!['specializations'] as List).join(', ')})',
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey,
                        ),
                      ),
                    if (_majstorData?['hourlyRate'] != null)
                      Text(
                        'Cijena po satu: ${_majstorData!['hourlyRate']} KM',
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(height: 20.0),
                    const Text(
                      'Opis',
                      style: TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      _majstorData?['description'] ?? 'Nema opisa.',
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    const SizedBox(height: 30.0),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => _startChat(context),
                        child: const Text('Kontaktiraj majstora'),
                      ),
                    ),
                    // TODO: Implementacija prikaza galerije radova
                  ],
                ),
              ),
    );
  }
}
