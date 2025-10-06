import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/job_service.dart'; // Pretpostavljamo da ćete koristiti postojeći JobService
import './job_details_screen.dart';

class UserJobsScreen extends StatelessWidget {
  const UserJobsScreen({super.key});

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
                      return _buildJobCard(context, job);
                    },
                  );
                },
              ),
    );
  }

  Widget _buildJobCard(BuildContext context, Job job) {
    Color statusColor = _getStatusColor(job.status);
    String statusText = _getStatusText(job.status);
    String priorityText = _getPriorityText(job.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8.0),

            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(job.location, style: const TextStyle(color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(Icons.category, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(job.category, style: const TextStyle(color: Colors.grey)),
                const Spacer(),
                if (job.budget != null) ...[
                  const Icon(Icons.attach_money, size: 16, color: Colors.green),
                  Text(
                    '${job.budget!.toStringAsFixed(0)} KM',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            Text(
              job.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                if (job.priority != 'medium') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(job.priority),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      priorityText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${job.createdAt.day}.${job.createdAt.month}.${job.createdAt.year}.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => JobDetailsScreen(
                              jobId: job.id,
                              isMajstor: false,
                            ),
                      ),
                    );
                  },
                  child: const Text('Detalji'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        return 'NIZAK';
      case 'medium':
        return 'SREDNJI';
      case 'high':
        return 'VISOK';
      case 'urgent':
        return 'HITNO';
      default:
        return priority.toUpperCase();
    }
  }
}
