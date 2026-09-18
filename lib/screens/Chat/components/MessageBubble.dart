import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MessageBubble extends StatelessWidget {
  final String texto;
  final String? imagemUrl;
  final bool isMinhaMensagem;
  final DateTime? dataHora;
  final String? pixCode; // ✅ novo: se for PIX, podemos copiar

  const MessageBubble({
    Key? key,
    required this.texto,
    required this.imagemUrl,
    required this.isMinhaMensagem,
    required this.dataHora,
    this.pixCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMinhaMensagem ? Colors.green[100] : Colors.blue[100],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: isMinhaMensagem ? const Radius.circular(12) : const Radius.circular(0),
          bottomRight: isMinhaMensagem ? const Radius.circular(0) : const Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        isMinhaMensagem ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          SelectableText(
            texto,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 16),
          ),

          // Exibe QR Code, se houver
          if (imagemUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Image.network(
                imagemUrl!,
                width: 220,
                height: 220,
              ),
            ),

          // Botão copiar PIX, se houver
          if (pixCode != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pixCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código PIX copiado!')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar código'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          if (dataHora != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${dataHora!.hour.toString().padLeft(2, '0')}:${dataHora!.minute.toString().padLeft(2, '0')} ${dataHora!.day}/${dataHora!.month}/${dataHora!.year}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
}
