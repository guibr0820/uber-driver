import 'package:cloud_firestore/cloud_firestore.dart';
import '../Chat/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DriverMessagesScreen extends StatelessWidget {
  const DriverMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF2F80ED),
        title: const Text('Mensagens'),
      ),
      body: driverId == null
          ? const Center(child: Text('Motorista nao autenticado.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('rides')
                  .where('driverId', isEqualTo: driverId)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rides = snapshot.data?.docs ?? [];
                if (rides.isEmpty) {
                  return const _EmptyMessages();
                }

                return FutureBuilder<List<_RideThread>>(
                  future: _loadThreads(rides, driverId),
                  builder: (context, threadsSnapshot) {
                    if (threadsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final threads = threadsSnapshot.data ?? [];
                    if (threads.isEmpty) {
                      return const _EmptyMessages();
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        _MessagesHeader(count: threads.length),
                        const SizedBox(height: 14),
                        ...threads.map(
                          (thread) => _MessageRideCard(thread: thread),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  // Ajuste Move: monta a lista de conversas lendo a subcolecao rides/{id}/chat.
  static Future<List<_RideThread>> _loadThreads(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rides,
    String driverId,
  ) async {
    final threads = <_RideThread>[];

    for (final rideDoc in rides) {
      final lastMessageQuery = await rideDoc.reference
          .collection('chat')
          .orderBy('dataHora', descending: true)
          .limit(1)
          .get();

      if (lastMessageQuery.docs.isEmpty) continue;

      final messageDoc = lastMessageQuery.docs.first;
      final message = messageDoc.data();
      final senderId = message['user']?.toString();
      final status = message['status']?.toString().toLowerCase();
      final hasUnread =
          senderId != driverId &&
          status != 'lida' &&
          status != 'read' &&
          status != 'vista';

      threads.add(
        _RideThread(
          rideId: rideDoc.id,
          ride: rideDoc.data(),
          lastMessage: message,
          hasUnread: hasUnread,
        ),
      );
    }

    threads.sort((a, b) => b.date.compareTo(a.date));
    return threads;
  }
}

class _MessagesHeader extends StatelessWidget {
  final int count;

  const _MessagesHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              count == 1 ? '1 conversa encontrada' : '$count conversas',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageRideCard extends StatelessWidget {
  final _RideThread thread;

  const _MessageRideCard({required this.thread});

  @override
  Widget build(BuildContext context) {
    final passenger = _asText(
      thread.ride['passengerName'],
      fallback: 'Passageiro',
    );
    final messageText = _messagePreview(thread.lastMessage);
    final origin = _addressFrom(thread.ride['origin'], fallback: 'Origem');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: thread.hasUnread
              ? const Color(0xFF2F80ED)
              : const Color(0xFFE6EAF0),
          width: thread.hasUnread ? 1.4 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(rideId: thread.rideId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF2F80ED),
                      ),
                    ),
                    if (thread.hasUnread)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE11D48),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              passenger,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(thread.date),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        messageText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: thread.hasUnread
                              ? const Color(0xFF111827)
                              : Colors.grey.shade700,
                          fontWeight: thread.hasUnread
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 15,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              origin,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none,
              size: 54,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sem mensagens',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Quando uma corrida tiver conversa, ela aparece aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideThread {
  final String rideId;
  final Map<String, dynamic> ride;
  final Map<String, dynamic> lastMessage;
  final bool hasUnread;

  const _RideThread({
    required this.rideId,
    required this.ride,
    required this.lastMessage,
    required this.hasUnread,
  });

  DateTime get date {
    final value = lastMessage['dataHora'];
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

String _messagePreview(Map<String, dynamic> message) {
  final text = _asText(message['mensagem']);
  if (text.isNotEmpty) return text;

  final imageUrl = _asText(message['imagemUrl']);
  if (imageUrl.isNotEmpty) return 'Imagem enviada';

  return 'Mensagem';
}

String _addressFrom(dynamic value, {required String fallback}) {
  if (value is Map) return _asText(value['address'], fallback: fallback);
  return fallback;
}

String _asText(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

