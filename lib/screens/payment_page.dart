import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';

class PaymentPage extends StatefulWidget {
  final double totalAmount;

  const PaymentPage({super.key, required this.totalAmount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;

  // ✅ NUEVO: Función para formatear dinero con comas
  String _formatMoney(double amount) {
    return '\$${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _onValidate() {
    // Si el formulario es válido, "simulamos" el pago exitoso
    if (_formKey.currentState!.validate()) {
      print('Formulario de tarjeta válido');
      // Mostramos un diálogo de éxito breve
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pago Exitoso'),
          // ✅ USAMOS EL FORMATO DE MONEDA
          content: Text('El pago de ${_formatMoney(widget.totalAmount)} fue simulado correctamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el diálogo de éxito
                Navigator.pop(context, true); // Regresa a la página del POS con 'true'
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } else {
      print('Formulario de tarjeta inválido');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulación de Pago'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      // ✅ MODIFICACIÓN RESPONSIVA
      // Envolvemos el cuerpo en un Center y ConstrainedBox
      // para que en pantallas grandes (PC) no se estire.
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600, // Ancho máximo del formulario
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Padding lateral
              child: Column(
                children: [
                  CreditCardWidget(
                    cardNumber: cardNumber,
                    expiryDate: expiryDate,
                    cardHolderName: cardHolderName,
                    cvvCode: cvvCode,
                    showBackView: isCvvFocused,
                    onCreditCardWidgetChange: (CreditCardBrand brand) {},
                    cardBgColor: Theme.of(context).colorScheme.primary,
                  ),
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
                    inputConfiguration: InputConfiguration(
                      cardNumberDecoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        labelText: 'Número de Tarjeta',
                        hintText: 'XXXX XXXX XXXX XXXX',
                      ),
                      cardHolderDecoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        labelText: 'Nombre del Titular',
                      ),
                      expiryDateDecoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        labelText: 'MM/AA',
                        hintText: 'MM/YY',
                      ),
                      cvvCodeDecoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        labelText: 'CVV',
                        hintText: 'XXX',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0), // Ajustamos padding
                    child: ElevatedButton(
                      onPressed: _onValidate,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      // ✅ USAMOS EL FORMATO DE MONEDA
                      child: Text('Pagar ${_formatMoney(widget.totalAmount)}', style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}