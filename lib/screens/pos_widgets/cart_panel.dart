import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:mi_punto_de_venta/providers/pos_provider.dart';

class CartPanel extends StatefulWidget {
  const CartPanel({super.key});

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  // --- ESTADO PARA CONTROLAR LA VISTA (Lista vs Pago) ---
  bool _showPaymentForm = false;

  // --- ESTADO DEL FORMULARIO DE PAGO ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;

  // --- UTILIDADES ---
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _formatMoney(double amount) {
    return '\$${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  // --- LÓGICA DE PROCESAR PAGO ---
  void _processPayment(BuildContext context, PosProvider pos, double totalAmount) async {
    if (_formKey.currentState!.validate()) {
      // 1. Simulación visual de proceso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Simular espera de red (2 segundos)
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pop(context); // Cerrar loading

      // 2. Intentar registrar la venta en Firebase
      try {
        await pos.submitSale(); // Esto guarda en BD y descuenta stock

        // 3. Mostrar éxito
        if (mounted) {
           showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('¡Venta Exitosa!'),
              content: Text('Se ha cobrado ${_formatMoney(totalAmount)} correctamente.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Cerrar diálogo
                    Navigator.of(context).maybePop(); // Cerrar el panel del carrito
                  },
                  child: const Text('Finalizar'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        // Error en la venta
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al procesar venta: $e'), backgroundColor: Colors.red),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor revisa los datos de la tarjeta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = Provider.of<PosProvider>(context);
    final List<dynamic> items = pos.cartItems;

    // Calcular Total
    double total = 0.0;
    for (final item in items) {
      try {
        dynamic price;
        if (item == null) { price = 0.0; } 
        else if (item is Map) { price = item['price'] ?? item['unitPrice'] ?? 0.0; } 
        else { price = (item.product != null) ? (item.product.price ?? item.price) : (item.price ?? 0.0); }
        
        dynamic quantityRaw;
        if (item is Map) { quantityRaw = item['quantity']; } 
        else { quantityRaw = item.quantity; }
        
        total += _safeToDouble(price) * _safeToDouble(quantityRaw ?? 1);
      } catch (_) {}
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // --- ENCABEZADO ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón de atrás si estamos en modo pago
                if (_showPaymentForm)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _showPaymentForm = false),
                  )
                else
                  const Text('Carrito', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),

                // Título dinámico
                if (_showPaymentForm)
                  const Text('Pago con Tarjeta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const Divider(),

            // --- CONTENIDO PRINCIPAL (SWITCH) ---
            Expanded(
              child: _showPaymentForm
                  ? _buildPaymentForm(context) // VISTA 2: FORMULARIO
                  : _buildCartList(context, pos, items), // VISTA 1: LISTA
            ),

            // --- FOOTER (TOTAL Y BOTONES) ---
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(_formatMoney(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              ],
            ),
            const SizedBox(height: 12),
            
            // BOTONES DINÁMICOS
            Row(
              children: [
                if (!_showPaymentForm) ...[
                  // BOTONES MODO CARRITO
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => pos.clearCart(),
                      child: const Text('Vaciar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: items.isEmpty
                          ? null
                          : () {
                              // CAMBIAR A MODO PAGO
                              setState(() {
                                _showPaymentForm = true;
                              });
                            },
                      child: const Text('Pagar'),
                    ),
                  ),
                ] else ...[
                  // BOTÓN MODO PAGO
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _processPayment(context, pos, total),
                      child: Text('Confirmar Cobro ${_formatMoney(total)}', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: LISTA DE PRODUCTOS ---
  Widget _buildCartList(BuildContext context, PosProvider pos, List<dynamic> items) {
    if (items.isEmpty) {
      return const Center(child: Text('El carrito está vacío 🛒'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        String title = 'Producto';
        double price = 0.0;
        int qty = 1;

        // Lógica de extracción de datos
        try {
           if (item is Map) {
             title = item['name'] ?? 'Producto';
             price = _safeToDouble(item['price']);
             qty = item['quantity'] ?? 1;
           } else {
             final prod = item.product;
             title = prod?.name ?? 'Producto';
             price = prod?.price ?? 0.0;
             qty = item.quantity;
           }
        } catch (_) {}

        return ListTile(
          title: Text(title, style: const TextStyle(fontSize: 14)),
          subtitle: Text('Cant: $qty'),
          trailing: Text(_formatMoney(price * qty), style: const TextStyle(fontWeight: FontWeight.bold)),
          onLongPress: () => pos.removeFromCart(item),
        );
      },
    );
  }

  // --- WIDGET: FORMULARIO DE TARJETA (ADAPTADO AL SIDEBAR) ---
  Widget _buildPaymentForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          
          // ✅ CORRECCIÓN: AspectRatio y LayoutBuilder para evitar deformaciones
          LayoutBuilder(
            builder: (context, constraints) {
              // Si el espacio es muy angosto (móvil o panel pequeño), ajustamos escala
              final bool isNarrow = constraints.maxWidth < 350;
              
              return AspectRatio(
                aspectRatio: 1.586, // Proporción estándar de tarjeta de crédito (ISO/IEC 7810)
                child: Transform.scale(
                  // Si es angosto, reducimos un poco la escala para que quepa bien
                  scale: isNarrow ? 0.85 : 0.95, 
                  child: CreditCardWidget(
                    cardNumber: cardNumber,
                    expiryDate: expiryDate,
                    cardHolderName: cardHolderName,
                    cvvCode: cvvCode,
                    showBackView: isCvvFocused,
                    onCreditCardWidgetChange: (_) {},
                    cardBgColor: const Color(0xFF1E3A8A), // Azul oscuro profesional
                    isHolderNameVisible: true,
                    isChipVisible: true,
                    // Desactivamos sombra por defecto que a veces causa problemas visuales en transforms
                    enableFloatingCard: true, 
                    floatingConfig: const FloatingConfig(
                      isGlareEnabled: true,
                      isShadowEnabled: true,
                      shadowConfig: FloatingShadowConfig(
                        offset: Offset(0, 4), 
                        color: Colors.black26, 
                        blurRadius: 4
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
          
          // Formulario compacto
          CreditCardForm(
            formKey: _formKey,
            cardNumber: cardNumber,
            expiryDate: expiryDate,
            cardHolderName: cardHolderName,
            cvvCode: cvvCode,
            onCreditCardModelChange: (CreditCardModel data) {
              setState(() {
                cardNumber = data.cardNumber;
                expiryDate = data.expiryDate;
                cardHolderName = data.cardHolderName;
                cvvCode = data.cvvCode;
                isCvvFocused = data.isCvvFocused;
              });
            },
            inputConfiguration: const InputConfiguration(
              cardNumberDecoration: InputDecoration(
                labelText: 'Número',
                hintText: 'XXXX XXXX XXXX XXXX',
                isDense: true, // Hace el input más compacto
                border: OutlineInputBorder(),
              ),
              expiryDateDecoration: InputDecoration(
                labelText: 'Vencimiento',
                hintText: 'MM/AA',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              cvvCodeDecoration: InputDecoration(
                labelText: 'CVV',
                hintText: 'XXX',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              cardHolderDecoration: InputDecoration(
                labelText: 'Titular',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}