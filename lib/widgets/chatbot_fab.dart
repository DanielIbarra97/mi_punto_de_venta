import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:mi_punto_de_venta/api_key.dart';

// Clase para definir un mensaje
class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage(this.text, {this.isUser = false});
}

class ChatbotFab extends StatelessWidget {
  const ChatbotFab({super.key});

  void _showChatbotDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    final List<ChatMessage> messages = [
      ChatMessage("¡Hola! Soy el asistente virtual de TechNorth. ¿En qué puedo ayudarte hoy?")
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            Future<void> _sendMessage() async {
              if (controller.text.isEmpty) return;
              final userMessage = controller.text;
              setModalState(() {
                messages.add(ChatMessage(userMessage, isUser: true));
                messages.add(ChatMessage("..."));
              });
              controller.clear();

              // Pega la Clave de API que copiaste de Google Cloud
              const apiKey = googleApiKey;
              
              final url = Uri.parse(
                  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=$apiKey');
              
              final systemPrompt = """
                Eres 'TechNorth Bot', un asistente virtual experto en componentes de PC, hardware y gaming.
                Trabajas para TechNorth, una tienda de componentes de alta gama en Monterrey, México.
                Tu eslogan es "Vanguardia y Poder para tu PC".
                Tu tono es amigable, profesional y apasionado por la tecnología.
                Nunca reveles que eres un modelo de IA.
                Si te preguntan por productos, recomienda categorías generales (ej. 'Tarjetas de Video', 'Procesadores AMD Ryzen', 'SSD NVMe') 
                pero NUNCA inventes precios o stock.
                Tu misión es ayudar a los clientes a elegir los mejores componentes.
              """;

              final history = messages.where((m) => m.text != "...").map((m) {
                return {"role": m.isUser ? "user" : "model", "parts": [{"text": m.text}]};
              }).toList();
              
              history.removeLast();

              final body = json.encode({
                "contents": [
                  ...history,
                  {"role": "user", "parts": [{"text": userMessage}]}
                ],
                "systemInstruction": {"parts": [{"text": systemPrompt}]},
              });

              try {
                final response = await http.post(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: body,
                );

                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  final botResponse = data['candidates'][0]['content']['parts'][0]['text'];
                  setModalState(() {
                    messages.removeLast(); 
                    messages.add(ChatMessage(botResponse));
                  });
                } else {
                  final data = json.decode(response.body);
                  print(data); // Imprime el error en la consola
                  setModalState(() {
                    messages.removeLast();
                    messages.add(ChatMessage("Lo siento, tuve un error (${response.statusCode}). Revisa la consola para más detalles."));
                  });
                }
              } catch (e) {
                setModalState(() {
                  messages.removeLast();
                  messages.add(ChatMessage("Error de conexión. Revisa tu internet."));
                });
              }
            }
            
            // --- UI DEL DIÁLOGO ---
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.3,
                maxChildSize: 0.95,
                builder: (_, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    // <--- AQUÍ EMPIEZA EL CAMBIO: Usamos un Stack ---
                    child: Stack(
                      children: [
                        // 1. EL CONTENIDO ORIGINAL (Columna con chat e input)
                        Column(
                          children: [
                            Container(
                              width: 40, height: 4,
                              margin: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                controller: scrollController,
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final msg = messages[index];
                                  return ListTile(
                                    title: Align(
                                      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: msg.isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: msg.text == "..."
                                          ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : MarkdownBody(
                                              data: msg.text,
                                              styleSheet: MarkdownStyleSheet(
                                                p: TextStyle(
                                                  color: msg.isUser ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black12, offset: Offset(0, -2))]
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: controller,
                                      decoration: InputDecoration(
                                        hintText: "Escribe tu pregunta...",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(25),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                                      ),
                                      onSubmitted: (_) => _sendMessage(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.send),
                                    onPressed: _sendMessage,
                                    style: IconButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),

                        // 2. EL BOTÓN DE CERRAR FLOTANTE (NUEVO)
                        Positioned(
                          top: 5,
                          right: 10,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            tooltip: 'Cerrar chat',
                            onPressed: () {
                              Navigator.pop(context); // Cierra el modal
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showChatbotDialog(context),
      tooltip: 'Asistente TechNorth',
      child: const Icon(Icons.support_agent),
    );
  }
}