import 'package:flutter/material.dart';

class MainBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;

  const MainBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabChanged,
      type: BottomNavigationBarType.fixed, // Da se sve ikonice i tekst vide
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Početna'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Poslovi'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Poruke'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}
// ```

// **Objašnjenje `MainBottomNavigationBar`:**
// * `currentIndex`: Označava koji je tab trenutno aktivan.
// * `onTabChanged`: Callback funkcija koja se poziva kada korisnik dodirne neki tab. Proslijeđuje indeks dodirnutog taba.
// * `items`: Lista `BottomNavigationBarItem`-a, svaki sa ikonicom i tekstom. Za sada koristimo generičke ikonice; kasnije ih možete prilagoditi.
