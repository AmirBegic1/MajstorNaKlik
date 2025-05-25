import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final CollectionReference _categoriesCollection = FirebaseFirestore.instance
      .collection('categories');

  Stream<List<Category>> getCategories() {
    return _categoriesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => Category.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>,
            ),
          )
          .toList();
    });
  }
}

class Category {
  final String id;
  final String name;
  final String icon;

  Category({required this.id, required this.name, required this.icon});

  factory Category.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data()!;
    return Category(
      id: document.id,
      name: data['name'] as String,
      icon: data['icon'] as String,
    );
  }
}
// ```

// **Objašnjenje `CategoryService`:**
// * `_categoriesCollection`: Referenca na Firestore kolekciju 'categories'.
// * `getCategories()`: Vraća `Stream` liste `Category` objekata. Koristimo `snapshots()` da bismo dobili real-time ažuriranja. `map()` se koristi za transformaciju `QuerySnapshot` u listu `Category` objekata.
// * `Category` klasa: Jednostavan model za predstavljanje kategorije.
// * `Category.fromFirestore()`: Factory konstruktor za kreiranje `Category` objekta iz `DocumentSnapshot`.
