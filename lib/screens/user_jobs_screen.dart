import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/job_service.dart'; // Pretpostavljamo da ćete koristiti postojeći JobService

class UserJobsScreen extends StatelessWidget {
  const UserJobsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Moji poslovi')),
      body:
          userId == null
              ? const Center(child: Text('Niste prijavljeni.'))
              : StreamBuilder<List<Job>>(
                stream: JobService().getUserJobs(
                  userId,
                ), // Potrebno je implementirati ovu metodu
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Došlo je do greške: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Nema objavljenih poslova.'),
                    );
                  }

                  final userJobs = snapshot.data!;
                  return ListView.builder(
                    itemCount: userJobs.length,
                    itemBuilder: (context, index) {
                      final job = userJobs[index];
                      return _buildJobCard(job);
                    },
                  );
                },
              ),
    );
  }

  Widget _buildJobCard(Job job) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              job.title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text('Lokacija: ${job.location}'),
            const SizedBox(height: 8.0),
            Text('Status: ${job.status}'), // Prikaz statusa posla
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    // TODO: Implementirajte navigaciju na detalje posla
                    print('Pogledaj detalje posla: ${job.id}');
                  },
                  child: const Text('Pogledaj detalje'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
