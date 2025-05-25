import 'package:flutter/material.dart';
import '../widgets/main_bottom_navigation_bar.dart'; // Putanja do BottomNavigationBar

class MajstorDashboard extends StatefulWidget {
  const MajstorDashboard({Key? key}) : super(key: key);

  @override
  State<MajstorDashboard> createState() => _MajstorDashboardState();
}

class _MajstorDashboardState extends State<MajstorDashboard> {
  int _selectedIndex = 0;

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
        return const Center(child: Text('Pregled poslova za majstora'));
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
}
