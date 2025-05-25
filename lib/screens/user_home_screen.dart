import 'package:flutter/material.dart';
import 'package:majstor_na_klik_app/main.dart';
import '../widgets/main_bottom_navigation_bar.dart'; // Putanja do BottomNavigationBar
import '../services/category_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;
  final CategoryService _categoryService = CategoryService();

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
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  hintText: 'Šta vam treba?',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (value) {
                  // TODO: Implementirajte logiku pretrage
                  print('Pretraga: $value');
                },
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Kategorije usluga',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10.0),
              Expanded(
                child: StreamBuilder<List<Category>>(
                  stream: _categoryService.getCategories(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Došlo je do greške pri učitavanju kategorija.',
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Nema dostupnih kategorija.'),
                      );
                    }

                    final categories = snapshot.data!;
                    return GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      children:
                          categories
                              .map((category) => _buildCategoryCard(category))
                              .toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
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

  Widget _buildCategoryCard(Category category) {
    IconData? iconData;
    switch (category.icon) {
      case 'water_drop':
        iconData = Icons.water_drop;
        break;
      case 'electrical_services':
        iconData = Icons.electrical_services;
        break;
      case 'cleaning_services':
        iconData = Icons.cleaning_services;
        break;
      case 'build':
        iconData = Icons.build;
        break;
      default:
        iconData = Icons.category_outlined; // Default ikona
    }

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        onTap: () {
          // TODO: Implementirajte navigaciju na listu majstora za odabranu kategoriju
          print('Odabrana kategorija: ${category.name}');
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(iconData, size: 40.0, color: primaryBlue),
            const SizedBox(height: 8.0),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
