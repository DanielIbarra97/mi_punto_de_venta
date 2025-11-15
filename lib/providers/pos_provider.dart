import 'package:flutter/material.dart';
import 'package:mi_punto_de_venta/models/cart_item_model.dart';
import 'package:mi_punto_de_venta/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mi_punto_de_venta/services/product_service.dart';

class PosProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final double _taxRate = 0.16;
  final ProductService _productService = ProductService();

  // --- NUEVO ESTADO PARA PRODUCTOS ---
  List<Product> _allProducts = []; // Caché de todos los productos
  List<Product> _filteredProducts = []; // Lista que ve la UI
  bool _isLoadingProducts = true;
  // ---------------------------------

  // --- Getters Públicos ---
  List<CartItem> get cartItems => _items;
  List<Product> get products => _filteredProducts; // El Grid escuchará a esto
  bool get isLoadingProducts => _isLoadingProducts;
  
  double get subtotal {
    double total = 0.0;
    for (var item in _items) {
      total += item.subtotal;
    }
    return total;
  }
  double get tax => subtotal * _taxRate;
  double get total => subtotal + tax;

  // --- LÓGICA DE PRODUCTOS ---
  
  // Carga inicial de productos
  Future<void> fetchProducts() async {
    _isLoadingProducts = true;
    notifyListeners();
    try {
      _allProducts = await _productService.fetchProducts();
      _filteredProducts = _allProducts; // Al inicio, la lista filtrada es la lista completa
    } catch (e) {
      print("Error al cargar productos en Provider: $e");
      _allProducts = [];
      _filteredProducts = [];
    }
    _isLoadingProducts = false;
    notifyListeners();
  }

  // Filtrado de productos
  void filterProducts(String query) {
    String lowerQuery = query.toLowerCase();
    if (lowerQuery.isEmpty) {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts.where((product) {
        return product.name.toLowerCase().contains(lowerQuery) ||
               product.brand.toLowerCase().contains(lowerQuery) ||
               product.category.toLowerCase().contains(lowerQuery);
      }).toList();
    }
    notifyListeners();
  }

  // --- LÓGICA DEL CARRITO ---
  void addToCart(Product product) {
    if (product.stock <= 0) return; 
    for (var item in _items) {
      if (item.product.id == product.id) { 
        if(item.quantity < item.product.stock) {
          item.quantity++;
        }
        notifyListeners(); 
        return;
      }
    }
    _items.add(CartItem(product: product));
    notifyListeners();
  }

  bool incrementItem(CartItem item) {
    if (item.quantity < item.product.stock) {
      item.quantity++;
      notifyListeners();
      return true; 
    } else {
      return false;
    }
  }

  void decrementItem(CartItem item) {
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }
    notifyListeners();
  }
  
  // ✅ MODIFICACIÓN: Función agregada para que cart_panel no de error
  void removeFromCart(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // --- LÓGICA DE VENTA ---
  Future<void> submitSale() async {
    if (_items.isEmpty) throw Exception('El carrito está vacío');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final db = FirebaseFirestore.instance;
    List<Map<String, dynamic>> stockUpdates = [];

    try {
      // 1. DESCONTAR STOCK (BD Relacional)
      for (var item in _items) {
        final success = await _productService.updateStock(item.product.sku, -item.quantity);
        if (!success) {
          throw Exception('Stock insuficiente para ${item.product.name}');
        }
        stockUpdates.add({'sku': item.product.sku, 'quantity': item.quantity});
      }

      // 2. GUARDAR VENTA (Firestore)
      final List<Map<String, dynamic>> itemsData = _items.map((item) {
        return {
          'product_id_sql': item.product.id,
          'product_sku': item.product.sku,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'price_at_sale': item.product.price,
        };
      }).toList();
      
      final saleData = {
        'employee_id': user.uid, 
        'employee_email': user.email, 
        'items': itemsData,
        'subtotal': subtotal, 
        'tax': tax, 
        'total': total,
        'timestamp': FieldValue.serverTimestamp(),
      };
      await db.collection('sales').add(saleData);

      // 3. ÉXITO: Limpiar carrito local
      clearCart();
      
      // 4. Recargar la lista de productos
      await fetchProducts();
      
    } catch (e) {
      // 5. ERROR Y REVERSIÓN
      print("--- ERROR EN LA VENTA. INICIANDO REVERSIÓN DE STOCK ---");
      for (var update in stockUpdates) {
        await _productService.updateStock(update['sku'], update['quantity']); 
        print("Stock revertido para ${update['sku']}");
      }
      
      await fetchProducts(); 
      
      throw Exception('Venta fallida. El inventario ha sido restaurado. Error: $e');
    }
  }
}