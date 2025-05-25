import 'package:flutter/material.dart';
import '../widgets/main_bottom_navigation_bar.dart'; // Putanja do BottomNavigationBar
import '../services/job_service.dart';

class MajstorDashboard extends StatefulWidget {
  const MajstorDashboard({Key? key}) : super(key: key);

  @override
  State<MajstorDashboard> createState() => _MajstorDashboardState();
}

class _MajstorDashboardState extends State<MajstorDashboard> {
  int _selectedIndex = 0;
  final JobService _jobService = JobService();

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
      // Ovdje ćete implementirati logiku za prikazivanje različitih sadržaja
      // ovisno o odabranom indeksu.
      print('Odabran tab (Majstor): $index');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _getPage(
        _selectedIndex,
      ), // Prikazujemo različite stranice ovisno o indeksu
      bottomNavigationBar: MainBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }

  // Privremena funkcija za prikazivanje različitog sadržaja za majstora
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Novi zahtjevi za posao',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10.0),
              Expanded(
                child: StreamBuilder<List<Job>>(
                  stream: _jobService.getNewJobs(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Došlo je do greške pri učitavanju poslova.',
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Nema novih zahtjeva za posao.'),
                      );
                    }

                    final jobs = snapshot.data!;
                    return ListView.builder(
                      itemCount: jobs.length,
                      itemBuilder: (context, i) {
                        return _buildJobRequestCard(jobs[i]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      case 1:
        return const Center(child: Text('Moji poslovi (aktivni) za majstora'));
      case 2:
        return const Center(child: Text('Poruke za majstora'));
      case 3:
        return const Center(child: Text('Profil majstora'));
      default:
        return const Center(child: Text('Greška'));
    }
  }

  Widget _buildJobRequestCard(Job job) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              job.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: 5.0),
            Row(
              children: <Widget>[
                const Icon(Icons.location_on, color: Colors.grey, size: 16.0),
                const SizedBox(width: 5.0),
                Text(job.location, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8.0),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Implementirajte navigaciju na detalje posla
                  print('Pogledaj detalje posla: ${job.id}');
                },
                child: const Text('Pogledaj detalje'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
