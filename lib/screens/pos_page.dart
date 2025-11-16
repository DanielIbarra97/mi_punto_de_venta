import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// --- ¡ESTA ES LA LÍNEA QUE FALTABA! ---
import 'package:mi_punto_de_venta/screens/pos_widgets/cart_panel.dart'; 
// ------------------------------------
import 'package:mi_punto_de_venta/screens/pos_widgets/product_grid.dart';
import 'package:provider/provider.dart';
import 'package:mi_punto_de_venta/providers/pos_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:mi_punto_de_venta/models/user_model.dart'; 
import 'package:mi_punto_de_venta/services/report_service.dart';
import 'package:mi_punto_de_venta/screens/admin_product_list_page.dart';
import 'package:mi_punto_de_venta/widgets/chatbot_fab.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  String? _userRole;
  final ReportService _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PosProvider>(context, listen: false).fetchProducts();
    });
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final userData = UserData.fromFirestore(doc); 
        setState(() { _userRole = userData.role; });
      }
    } catch (e) {
      print("Error al obtener rol de usuario: $e");
    }
  }

  void logout() {
    FirebaseAuth.instance.signOut();
  }

  void _handleDownloadReport() async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      await _reportService.downloadSalesReport();
      if (mounted) Navigator.pop(context); 
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar el reporte: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToAdminProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminProductListPage()),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('TechNorth'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        
        // --- Botón de Carrito (Solo para vista ancha) ---
        if (MediaQuery.of(context).size.width > 700) // Solo se muestra en layout ancho
          Builder(
            builder: (context) { 
              return Consumer<PosProvider>(
                builder: (context, pos, child) {
                  return Badge(
                    label: Text('${pos.cartItems.length}'),
                    isLabelVisible: pos.cartItems.isNotEmpty,
                    child: IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      tooltip: 'Ver Carrito',
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer(); 
                      },
                    ),
                  );
                },
              );
            }
          ),
        
        // Botón de Reportes
        if (_userRole == 'consultor' || _userRole == 'administrador')
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Descargar Reporte de Ventas',
            onPressed: _handleDownloadReport,
          ),
        
        // Botón de Admin
        if (_userRole == 'administrador')
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Gestionar Productos',
            onPressed: _navigateToAdminProducts,
          ),
        
        IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
      ],
      // El 'bottom' (pestañas) solo se usa en la vista móvil
      bottom: (MediaQuery.of(context).size.width <= 700) ? _buildTabBar() : null,
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
      tabs: [
        const Tab(icon: Icon(Icons.grid_view), text: 'Catálogo'),
        Tab(
          icon: Consumer<PosProvider>(
            builder: (context, pos, child) {
              return Badge(
                label: Text('${pos.cartItems.length}'),
                isLabelVisible: pos.cartItems.isNotEmpty,
                child: const Icon(Icons.shopping_cart),
              );
            },
          ),
          text: 'Carrito',
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 700) {
          return _buildWideLayout(context);
        } else {
          return _buildNarrowLayout(context);
        }
      },
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: const Row(
        children: [
          Expanded(flex: 1, child: ProductGrid()),
          // La columna del carrito ya no está fija
        ],
      ),
      // El carrito ahora está en el 'endDrawer'
      endDrawer: const Drawer(
        width: 450, 
        child: CartPanel(), // <--- ESTE ES UNO DE LOS ERRORES
      ),
      floatingActionButton: const ChatbotFab(),
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: const TabBarView(
          children: [
            ProductGrid(),
            CartPanel(), // <--- ESTE ES EL OTRO ERROR
          ],
        ),
        floatingActionButton: const ChatbotFab(),
      ),
    );
  }
}