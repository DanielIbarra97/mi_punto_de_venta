import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mi_punto_de_venta/models/product_model.dart';

class ProductService {
  
  final String _baseUrl = 'https://technorth-products-api.onrender.com';

  // --- GET (Leer) ---
  Future<List<Product>> fetchProducts({String? searchQuery}) async {
    String url = '$_baseUrl/products/?limit=250';
    if (searchQuery != null && searchQuery.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(searchQuery)}'; 
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar productos: ${response.statusCode}');
      }
    } catch (e) {
      print("Error de red o API: $e");
      throw Exception('Error de conexión con la API de productos: $e');
    }
  }

  // --- PUT (Actualizar Stock) ---
  Future<bool> updateStock(String sku, int changeAmount) async {
    final url = Uri.parse('$_baseUrl/products/$sku/stock?change_amount=$changeAmount');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error al actualizar stock: $e");
      return false;
    }
  }

  // --- NUEVO: POST (Crear Producto - CU2) ---
  Future<Product> createProduct(Map<String, dynamic> productData) async {
    final url = Uri.parse('$_baseUrl/products/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(productData),
      );
      if (response.statusCode == 201) { // 201 = Creado
        return Product.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Error al crear el producto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de API al crear: $e');
    }
  }

  // --- NUEVO: PUT (Actualizar Producto - CU2) ---
  Future<Product> updateProduct(int productId, Map<String, dynamic> productData) async {
    final url = Uri.parse('$_baseUrl/products/$productId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(productData),
      );
      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Error al actualizar el producto: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error de API al actualizar: $e');
    }
  }

  // --- NUEVO: DELETE (Borrar Producto - CU2) ---
  Future<bool> deleteProduct(int productId) async {
    final url = Uri.parse('$_baseUrl/products/$productId');
    try {
      final response = await http.delete(url);
      return response.statusCode == 204; // 204 = Sin Contenido (Éxito)
    } catch (e) {
      throw Exception('Error de API al borrar: $e');
    }
  }
}