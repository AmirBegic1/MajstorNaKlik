import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/job_service.dart';
import '../services/chat_service.dart';
import './chat_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;
  final bool isMajstor;

  const JobDetailsScreen({
    super.key,
    required this.jobId,
    this.isMajstor = false,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final JobService _jobService = JobService();
  final ChatService _chatService = ChatService();

  Job? _job;
  Map<String, dynamic>? _clientData;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Učitaj job detalje
      final jobDoc =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(widget.jobId)
              .get();

      if (jobDoc.exists && jobDoc.data() != null) {
        _job = Job.fromFirestore(jobDoc);

        // Učitaj podatke o klijentu
        final clientDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(_job!.userId)
                .get();

        if (clientDoc.exists && clientDoc.data() != null) {
          _clientData = clientDoc.data() as Map<String, dynamic>;
        }
      } else {
        _errorMessage = 'Posao nije pronađen.';
      }
    } catch (e) {
      _errorMessage = 'Greška pri učitavanju posla: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptJob() async {
    if (_job == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Morate biti prijavljeni')));
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _jobService.assignJobToMajstor(
        _job!.id,
        currentUser.uid,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Posao je uspješno prihvaćen!')),
        );

        // Osvježi podatke o poslu
        await _loadJobDetails();
      } else {
        throw Exception('Nije moguće prihvatiti posao');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Greška: $e')));
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _startChat() async {
    if (_job == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final String chatId = _chatService.getChatId(
        currentUser.uid,
        _job!.userId,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatScreen(
                conversationId: chatId,
                receiverUserId: _job!.userId,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Greška pri pokretanju razgovora: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'in-progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Otvoren';
      case 'assigned':
        return 'Dodijeljen';
      case 'in-progress':
        return 'U toku';
      case 'completed':
        return 'Završen';
      case 'cancelled':
        return 'Otkazan';
      default:
        return status;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Nizak';
      case 'medium':
        return 'Srednji';
      case 'high':
        return 'Visok';
      case 'urgent':
        return 'Hitno';
      default:
        return priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalji posla'),
        actions: [
          if (_job != null && !widget.isMajstor)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: _startChat,
              tooltip: 'Kontaktiraj majstora',
            ),
        ],
      ),
      body:
          _isLoading
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
                      onPressed: _loadJobDetails,
                      child: const Text('Pokušaj ponovo'),
                    ),
                  ],
                ),
              )
              : _job == null
              ? const Center(child: Text('Posao nije pronađen'))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status i prioritet
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_job!.status),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getStatusText(_job!.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(_job!.priority),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _getPriorityText(_job!.priority),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Naslov
                    Text(
                      _job!.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Osnovne informacije
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              Icons.location_on,
                              'Lokacija',
                              _job!.location,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.category,
                              'Kategorija',
                              _job!.category,
                            ),
                            if (_job!.budget != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.attach_money,
                                'Budžet',
                                '${_job!.budget!.toStringAsFixed(0)} KM',
                              ),
                            ],
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.phone,
                              'Kontakt',
                              _job!.contactPhone,
                            ),
                            if (_job!.scheduledDate != null) ...[
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.calendar_today,
                                'Željeni datum',
                                '${_job!.scheduledDate!.day}.${_job!.scheduledDate!.month}.${_job!.scheduledDate!.year}.',
                              ),
                            ],
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              Icons.access_time,
                              'Objavljeno',
                              '${_job!.createdAt.day}.${_job!.createdAt.month}.${_job!.createdAt.year}.',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Opis
                    const Text(
                      'Opis posla',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _job!.description,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    // Slike (ako postoje)
                    if (_job!.images.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Slike',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _job!.images.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _job!.images[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    // Informacije o klijentu
                    if (_clientData != null) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Informacije o klijentu',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                _clientData!['profileImageUrl'] != null
                                    ? NetworkImage(
                                      _clientData!['profileImageUrl'],
                                    )
                                    : const AssetImage('assets/avatar.jpg')
                                        as ImageProvider,
                          ),
                          title: Text(
                            _clientData!['displayName'] ?? 'Nepoznato ime',
                          ),
                          subtitle: Text(
                            _clientData!['phoneNumber'] ??
                                'Nema broja telefona',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.chat),
                            onPressed: _startChat,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
      bottomNavigationBar:
          widget.isMajstor &&
                  _job != null &&
                  _job!.status == 'open' &&
                  _job!.assignedTo == null
              ? Container(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _acceptJob,
                  icon:
                      _isProcessing
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.check_circle),
                  label: Text(
                    _isProcessing ? 'Obrađujem...' : 'Prihvati posao',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
