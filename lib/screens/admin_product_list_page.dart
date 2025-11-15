import 'package:flutter/material.dart';
import 'package:mi_punto_de_venta/models/product_model.dart';
import 'package:mi_punto_de_venta/services/product_service.dart';
import 'package:mi_punto_de_venta/screens/admin_product_edit_page.dart';
import 'package:provider/provider.dart'; // Para refrescar el catálogo
import 'package:mi_punto_de_venta/providers/pos_provider.dart';

class AdminProductListPage extends StatefulWidget {
  const AdminProductListPage({super.key});

  @override
  State<AdminProductListPage> createState() => _AdminProductListPageState();
}

class _AdminProductListPageState extends State<AdminProductListPage> {
  final ProductService _productService = ProductService();
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  // Cargar productos desde el API
  void _loadProducts() {
    setState(() {
      _productsFuture = _productService.fetchProducts();
    });
  }

  // Navegar a la página de edición (para Crear o Actualizar)
  void _navigateToEditPage([Product? product]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminProductEditPage(product: product),
      ),
    ).then((_) {
      // Cuando regresemos de la página de edición, recargar la lista
      _loadProducts();
      // También refrescamos el catálogo principal
      Provider.of<PosProvider>(context, listen: false).fetchProducts();
    });
  }

  // Lógica para borrar un producto (CU2 - Bajas)
  Future<void> _deleteProduct(Product product) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Borrado'),
        content: Text('¿Estás seguro de que quieres borrar "${product.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _productService.deleteProduct(product.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto borrado con éxito'), backgroundColor: Colors.green),
      );
      _loadProducts(); // Recargar la lista
      // Refrescar el catálogo principal
      Provider.of<PosProvider>(context, listen: false).fetchProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al borrar el producto: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Productos (CU2)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar productos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay productos para gestionar.'));
          }

          final products = snapshot.data!;
          
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('Stock: ${product.stock} | \$${product.price.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón de Editar (Modificaciones)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _navigateToEditPage(product),
                    ),
                    // Botón de Borrar (Bajas)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteProduct(product),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      // Botón para Crear (Altas)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEditPage(), // Llamar sin producto
        tooltip: 'Añadir Nuevo Producto',
        child: const Icon(Icons.add),
      ),
    );
  }
}