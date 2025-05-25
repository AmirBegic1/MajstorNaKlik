import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  final CollectionReference _jobsCollection = FirebaseFirestore.instance
      .collection('jobs');

  Stream<List<Job>> getNewJobs() {
    // Za sada dohvaćamo sve poslove. Kasnije ćemo filtrirati po lokaciji i kategorijama majstora.
    return _jobsCollection.where('status', isEqualTo: 'open').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map(
            (doc) => Job.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();
    });
  }
}

class Job {
  final String id;
  final String title;
  final String location;
  final String description;
  final String category;
  final String userId;
  final String status;
  // Dodajte ostala polja po potrebi

  Job({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.category,
    required this.userId,
    required this.status,
  });

  factory Job.fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return Job(
      id: document.id,
      title: data['title'] as String? ?? '',
      location: data['location'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      status: data['status'] as String? ?? 'open', // Default status
      // Učitajte ostala polja ovdje
    );
  }
}
