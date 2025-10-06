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

  Stream<List<Job>> getUserJobs(String userId) {
    return _jobsCollection.where('userId', isEqualTo: userId).snapshots().map((
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

  Stream<List<Job>> getMajstorJobs(String majstorId) {
    return _jobsCollection
        .where('assignedTo', isEqualTo: majstorId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => Job.fromFirestore(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList();
        });
  }

  // Kreiranje novog job-a
  Future<String?> createJob({
    required String title,
    required String location,
    required String description,
    required String category,
    required String userId,
    required String contactPhone,
    double? budget,
    String priority = 'medium',
    List<String> images = const [],
    DateTime? scheduledDate,
    Map<String, dynamic>? requirements,
  }) async {
    try {
      final job = Job(
        id: '', // ID će biti generiran automatski
        title: title,
        location: location,
        description: description,
        category: category,
        userId: userId,
        status: 'open',
        createdAt: DateTime.now(),
        contactPhone: contactPhone,
        budget: budget,
        priority: priority,
        images: images,
        scheduledDate: scheduledDate,
        requirements: requirements,
      );

      final docRef = await _jobsCollection.add(job.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Greška pri kreiranju job-a: $e');
      return null;
    }
  }

  // Ažuriranje job statusa
  Future<bool> updateJobStatus(String jobId, String newStatus) async {
    try {
      await _jobsCollection.doc(jobId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Greška pri ažuriranju statusa job-a: $e');
      return false;
    }
  }

  // Dodjela job-a majstoru
  Future<bool> assignJobToMajstor(String jobId, String majstorId) async {
    try {
      await _jobsCollection.doc(jobId).update({
        'assignedTo': majstorId,
        'status': 'assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Greška pri dodjeli job-a majstoru: $e');
      return false;
    }
  }

  // Ažuriranje slika job-a
  Future<bool> updateJobImages(String jobId, List<String> imageUrls) async {
    try {
      await _jobsCollection.doc(jobId).update({
        'images': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Greška pri ažuriranju slika job-a: $e');
      return false;
    }
  }

  // Obriši job (također briše i slike iz Storage-a)
  Future<bool> deleteJob(String jobId) async {
    try {
      await _jobsCollection.doc(jobId).delete();
      return true;
    } catch (e) {
      print('Greška pri brisanju job-a: $e');
      return false;
    }
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
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? assignedTo; // ID majstora koji je prihvatio posao
  final double? budget; // Predloženi budžet
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String contactPhone;
  final List<String> images; // URL-ovi slika
  final DateTime? scheduledDate; // Kada korisnik želi da se posao završi
  final Map<String, dynamic>? requirements; // Dodatni zahtjevi

  Job({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.category,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.assignedTo,
    this.budget,
    this.priority = 'medium',
    required this.contactPhone,
    this.images = const [],
    this.scheduledDate,
    this.requirements,
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
      status: data['status'] as String? ?? 'open',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      assignedTo: data['assignedTo'] as String?,
      budget: (data['budget'] as num?)?.toDouble(),
      priority: data['priority'] as String? ?? 'medium',
      contactPhone: data['contactPhone'] as String? ?? '',
      images: List<String>.from(data['images'] ?? []),
      scheduledDate: (data['scheduledDate'] as Timestamp?)?.toDate(),
      requirements: data['requirements'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'location': location,
      'description': description,
      'category': category,
      'userId': userId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'assignedTo': assignedTo,
      'budget': budget,
      'priority': priority,
      'contactPhone': contactPhone,
      'images': images,
      'scheduledDate':
          scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'requirements': requirements,
    };
  }
}
