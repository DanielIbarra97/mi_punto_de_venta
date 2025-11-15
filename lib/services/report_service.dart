import 'package:url_launcher/url_launcher.dart';

class ReportService {
  
  // --- ¡ESTA ES LA CONEXIÓN AL 2DO BACKEND! ---
  // Es la URL que te dio Render para el API de Node.js
  final String _baseUrl = 'https://technorth-api-reportes.onrender.com';

  Future<void> downloadSalesReport() async {
    final url = Uri.parse('$_baseUrl/report/sales');

    // Comprobamos si podemos lanzar la URL
    if (await canLaunchUrl(url)) {
      // Abre la URL en el navegador. 
      // Como tu API de Node.js tiene el 'Content-Disposition'
      // esto forzará la descarga del PDF.
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // Importante para descargas
      );
    } else {
      throw 'No se pudo abrir la URL: $url';
    }
  }
}