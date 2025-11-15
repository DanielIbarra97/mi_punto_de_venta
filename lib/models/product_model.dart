import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  // Nota: 'id' (int) viene de PostgreSQL, 'sku' (string) es el ID de negocio.
  final int id; 
  final String name;
  final String sku;
  final double price;
  final int stock;
  final String category;
  final String imageUrl;
  final String description;
  final String brand;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.stock,
    required this.category,
    required this.imageUrl,
    required this.description,
    required this.brand,
  });

  // --- NUEVA FUNCIÓN ---
  // Constructor para crear un Producto desde el JSON del API (PostgreSQL)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Sin Nombre',
      sku: json['sku'] ?? 'SKU-DESCONOCIDO',
      // El precio de PostgreSQL viene como String, hay que convertirlo
      price: double.tryParse(json['price'].toString()) ?? 0.0, 
      stock: json['stock'] ?? 0,
      category: json['category'] ?? 'Sin Categoría',
      imageUrl: json['image_url'] ?? '', // API usa image_url (snake_case)
      description: json['description'] ?? '',
      brand: json['brand'] ?? 'Sin Marca',
    );
  }

  // Constructor de Firestore (lo dejamos por si lo usamos en el futuro)
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: 0, // Firestore no tiene el ID numérico de SQL
      name: data['name'] ?? 'Sin Nombre',
      sku: data['sku'] ?? 'SKU-DESCONOCIDO',
      price: (data['price'] ?? 0.0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
      category: data['category'] ?? 'Sin Categoría',
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      brand: data['brand'] ?? 'Sin Marca',
    );
  }
}