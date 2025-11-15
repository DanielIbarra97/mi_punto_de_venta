// lib/models/cart_item_model.dart

import 'package:mi_punto_de_venta/models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  // Helper para calcular el subtotal de este item
  double get subtotal => product.price * quantity;
}