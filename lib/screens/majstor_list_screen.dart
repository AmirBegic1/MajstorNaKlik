import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './majstor_details_screen.dart'; // Import MajstorDetailsScreen

class MajstorListScreen extends StatelessWidget {
  const MajstorListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista majstora')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'majstor')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Došlo je do greške: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final majstori = snapshot.data?.docs ?? [];

          if (majstori.isEmpty) {
            return const Center(
              child: Text('Trenutno nema dostupnih majstora.'),
            );
          }

          return ListView.builder(
            itemCount: majstori.length,
            itemBuilder: (context, index) {
              final majstorData =
                  majstori[index].data() as Map<String, dynamic>?;
              final majstorId = majstori[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage:
                        majstorData?['profileImageUrl'] != null
                            ? NetworkImage(
                              majstorData!['profileImageUrl'] as String,
                            )
                            : const AssetImage('assets/default_profile.png')
                                as ImageProvider,
                    child:
                        majstorData?['profileImageUrl'] == null
                            ? const Icon(Icons.person)
                            : null,
                  ),
                  title: Text(majstorData?['displayName'] ?? 'Ime majstora'),
                  subtitle:
                      majstorData?['specializations'] != null
                          ? Text(
                            (majstorData!['specializations'] as List).join(
                              ', ',
                            ),
                          )
                          : const Text('Nema specijalizacija'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                MajstorDetailsScreen(majstorId: majstorId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
