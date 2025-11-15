import 'package:flutter/material.dart';
import 'package:mi_punto_de_venta/models/product_model.dart';
import 'package:mi_punto_de_venta/services/product_service.dart';
import 'package:flutter/services.dart'; // Para filtrar números

class AdminProductEditPage extends StatefulWidget {
  final Product? product; // Si es null = Crear, si no = Editar

  const AdminProductEditPage({super.key, this.product});

  @override
  State<AdminProductEditPage> createState() => _AdminProductEditPageState();
}

class _AdminProductEditPageState extends State<AdminProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  bool _isLoading = false;

  // Controladores para el formulario
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _categoryController;
  late TextEditingController _imageUrlController;
  late TextEditingController _brandController; // Faltaba este en la lista

  @override
  void initState() {
    super.initState();
    // Llenar los campos si estamos editando un producto existente
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _skuController = TextEditingController(text: widget.product?.sku ?? '');
    _descController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _categoryController = TextEditingController(text: widget.product?.category ?? '');
    _imageUrlController = TextEditingController(text: widget.product?.imageUrl ?? '');
    _brandController = TextEditingController(text: widget.product?.brand ?? ''); // Asegurarse de inicializarlo
  }

  @override
  void dispose() {
    // Limpiar controladores
    _nameController.dispose();
    _skuController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  // Lógica de Guardar (CU2 - Altas y Modificaciones)
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return; // Si el formulario no es válido, no hacer nada
    }

    setState(() { _isLoading = true; });

    // Crear el mapa de datos (el JSON para el API)
    final productData = {
      'name': _nameController.text,
      'sku': _skuController.text,
      'description': _descController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'stock': int.tryParse(_stockController.text) ?? 0,
      'category': _categoryController.text,
      'image_url': _imageUrlController.text, // 'image_url' como lo espera el API de Python
      'brand': _brandController.text,
    };

    try {
      if (widget.product == null) {
        // --- MODO CREAR (ALTAS) ---
        await _productService.createProduct(productData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto creado con éxito'), backgroundColor: Colors.green),
        );
      } else {
        // --- MODO EDITAR (MODIFICACIONES) ---
        await _productService.updateProduct(widget.product!.id, productData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto actualizado con éxito'), backgroundColor: Colors.green),
        );
      }
      if (mounted) Navigator.pop(context); // Regresar a la lista
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Añadir Producto' : 'Editar Producto'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(labelText: 'SKU (Código)'),
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Precio (Ej: 1500.99)'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stock (Ej: 50)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Categoría (Ej: Monitores)'),
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                     TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(labelText: 'Marca (Ej: ASUS)'),
                      validator: (val) => val!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(labelText: 'URL de la Imagen'),
                      // --- ¡ERROR CORREGIDO AQUÍ! ---
                      // El comentario ahora está fuera del string
                      validator: (val) => val!.isEmpty ? 'Requerido' : null, // (si usas picsum, pégala aquí)
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      child: const Text('Guardar Producto'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}