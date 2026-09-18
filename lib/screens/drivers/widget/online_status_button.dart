import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OnlineStatusButton extends StatefulWidget {
  final String driverId;
  final double size;

  const OnlineStatusButton({
    super.key,
    required this.driverId,
    this.size = 70,
  });

  @override
  State<OnlineStatusButton> createState() => _OnlineStatusButtonState();
}

class _OnlineStatusButtonState extends State<OnlineStatusButton> {
  bool _saving = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get _resolvedDriverId {
    final idFromWidget = widget.driverId.trim();
    if (idFromWidget.isNotEmpty) return idFromWidget;

    // Ajuste Move: se o UserManager ainda nao carregou, usa o uid do FirebaseAuth.
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<void> _toggleStatus(bool currentOnline) async {
    final driverId = _resolvedDriverId;
    if (driverId.isEmpty || _saving) return;

    setState(() => _saving = true);

    try {
      final newStatus = !currentOnline;
      final update = <String, dynamic>{
        'online': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!newStatus) {
        update['available'] = false;
      }

      // Ajuste Move: merge evita erro se o documento/campo ainda nao existir.
      await _firestore
          .collection('drivers')
          .doc(driverId)
          .set(update, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao atualizar status online: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nao foi possivel atualizar o status online.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverId = _resolvedDriverId;

    if (driverId.isEmpty) {
      return _OnlineButtonShell(
        isOnline: false,
        loading: true,
        size: widget.size,
        onTap: null,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      // Ajuste Move: escuta drivers/{uid}/online em tempo real para o botao refletir o Firestore.
      stream: _firestore.collection('drivers').doc(driverId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final isOnline = data['online'] == true;
        final loading = _saving || snapshot.connectionState == ConnectionState.waiting;

        return _OnlineButtonShell(
          isOnline: isOnline,
          loading: loading,
          size: widget.size,
          onTap: loading ? null : () => _toggleStatus(isOnline),
        );
      },
    );
  }
}

class _OnlineButtonShell extends StatelessWidget {
  final bool isOnline;
  final bool loading;
  final double size;
  final VoidCallback? onTap;

  const _OnlineButtonShell({
    required this.isOnline,
    required this.loading,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? Colors.green : Colors.red;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isOnline ? 'ONLINE' : 'OFFLINE',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: loading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : Icon(
                    isOnline ? Icons.toggle_on : Icons.toggle_off,
                    color: Colors.white,
                    size: size * 0.6,
                  ),
          ),
        ),
      ],
    );
  }
}
