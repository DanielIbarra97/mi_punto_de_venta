import 'package:flutter/material.dart';
import 'package:mi_punto_de_venta/models/product_model.dart';
import 'package:mi_punto_de_venta/providers/pos_provider.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  // Función para obtener un ícono local
  IconData _getCategoryIcon(String category) {
    if (category.contains('Procesador')) return Icons.memory;
    if (category.contains('Video')) return Icons.video_camera_back_outlined;
    if (category.contains('Monitor')) return Icons.monitor;
    if (category.contains('Periférico')) return Icons.keyboard_alt_outlined;
    if (category.contains('RAM')) return Icons.sd_card;
    if (category.contains('Gabinete')) return Icons.desktop_windows_outlined;
    if (category.contains('Enfriamiento')) return Icons.ac_unit;
    if (category.contains('Almacenamiento')) return Icons.save_alt;
    return Icons.computer;
  }

  // --- WIDGET DE IMAGEN MODIFICADO ---
  // Ahora siempre devuelve el ícono, tanto en móvil como en web,
  // para consistencia y velocidad.
  Widget _buildImageWidget(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.05), // Fondo de color sutil
      child: Icon(
        _getCategoryIcon(product.category), 
        size: 60,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.6), // Ícono con color de la marca
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final posProvider = Provider.of<PosProvider>(context, listen: false);
    final bool isOutOfStock = product.stock <= 0;

    return Card(
      elevation: 2,
      color: isOutOfStock ? Colors.grey[200] : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isOutOfStock 
          ? null 
          : () {
              posProvider.addToCart(product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} añadido'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageWidget(context),
                  if (isOutOfStock)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: Colors.red,
                          child: const Text('AGOTADO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(fontWeight: FontWeight.bold, decoration: isOutOfStock ? TextDecoration.lineThrough : null),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text('\$${product.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                  Text('Stock: ${product.stock}', style: TextStyle(fontSize: 12, color: isOutOfStock ? Colors.red : Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}