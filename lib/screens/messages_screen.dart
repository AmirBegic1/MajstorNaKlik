import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poruke')),
      body: ListView.builder(
        itemCount: 5, // Primjer broja razgovora
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('Razgovor ${index + 1}'),
              subtitle: const Text('Posljednja poruka...'),
              onTap: () {
                // TODO: Implementirajte navigaciju na ekran za chat
                print('Otvori razgovor ${index + 1}');
              },
            ),
          );
        },
      ),
    );
  }
}
