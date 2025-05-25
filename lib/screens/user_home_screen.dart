import 'package:flutter/material.dart';
import '../widgets/main_bottom_navigation_bar.dart'; // Putanja do BottomNavigationBar

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
      // Ovdje ćete implementirati logiku za prikazivanje različitih sadržaja
      // ovisno o odabranom indeksu. Za sada samo ispisujemo indeks.
      print('Odabran tab: $index');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Početna')),
      body: _getPage(
        _selectedIndex,
      ), // Prikazujemo različite stranice ovisno o indeksu
      bottomNavigationBar: MainBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTabChanged: _onTabChanged,
      ),
    );
  }

  // Privremena funkcija za prikazivanje različitog sadržaja
  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const Center(child: Text('Početna stranica za korisnika'));
      case 1:
        return const Center(child: Text('Moji poslovi za korisnika'));
      case 2:
        return const Center(child: Text('Poruke za korisnika'));
      case 3:
        return const Center(child: Text('Profil korisnika'));
      default:
        return const Center(child: Text('Greška'));
    }
  }
}
