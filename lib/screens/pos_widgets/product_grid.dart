import 'package:flutter/material.dart';
import 'package:mi_punto_de_venta/screens/pos_widgets/product_card.dart';
import 'package:provider/provider.dart';
import 'package:mi_punto_de_venta/providers/pos_provider.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Escuchamos al Provider
    final posProvider = Provider.of<PosProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            // 2. Llamamos al filtro del provider en cada cambio
            onChanged: (value) {
              posProvider.filterProducts(value);
            },
            decoration: InputDecoration(
              hintText: 'Buscar producto por nombre...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
        ),
        Expanded(
          // 3. Reaccionamos al estado de carga del provider
          child: posProvider.isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : posProvider.products.isEmpty
                  ? const Center(child: Text('No se encontraron productos.'))
                  : GridView.builder(
                      padding: const EdgeInsets.all(8.0),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200, 
                        childAspectRatio: 0.75, 
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      // 4. Usamos la lista de productos filtrados del provider
                      itemCount: posProvider.products.length,
                      itemBuilder: (context, index) {
                        return ProductCard(product: posProvider.products[index]);
                      },
                    ),
        ),
      ],
    );
  }
}