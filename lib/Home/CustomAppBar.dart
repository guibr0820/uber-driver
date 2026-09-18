import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationTap;

  const CustomAppBar({
    super.key,
    required this.onMenuTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.blueAccent,
      centerTitle: true,

      // ☰ MENU
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: onMenuTap, // ✅ AQUI
      ),
      // 🚕 TÍTULO COM MENOS ESPAÇO EMBAIXO
      title: const Padding(
        padding: EdgeInsets.only(bottom: 6),
        child: Text(
          'Move',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            height: 1.2, // 🔥 diminui altura da linha
          ),
        ),
      ),

      // 🔔 NOTIFICAÇÕES
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: onNotificationTap,
        ),
      ],
    );
  }

  // 🔽 ALTURA MENOR
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

}
