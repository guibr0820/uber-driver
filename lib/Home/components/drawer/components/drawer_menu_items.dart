import 'package:flutter/material.dart';

class DrawerMenuItems extends StatelessWidget {
  final VoidCallback? onWalletTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onRideHistoryTap;
  final VoidCallback? onMessagesTap;
  final VoidCallback? onSettingsTap;
  final bool hasMessages;
  final int messageCount;

  const DrawerMenuItems({
    super.key,
    this.onWalletTap,
    this.onProfileTap,
    this.onRideHistoryTap,
    this.onMessagesTap,
    this.onSettingsTap,
    this.hasMessages = false,
    this.messageCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DrawerMenuItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Carteira',
          subtitle: 'Saldo, Pix e repasses',
          color: const Color(0xFF0E9F6E),
          onTap: onWalletTap,
        ),
        _DrawerMenuItem(
          icon: Icons.person_outline,
          title: 'Meus dados',
          subtitle: 'Perfil, carro e conta',
          color: const Color(0xFF2F80ED),
          onTap: onProfileTap,
        ),
        _DrawerMenuItem(
          icon: Icons.history,
          title: 'Historico de corridas',
          subtitle: 'Viagens finalizadas',
          color: const Color(0xFF7C3AED),
          onTap: onRideHistoryTap,
        ),
        _DrawerMenuItem(
          icon: Icons.notifications_none,
          title: 'Mensagens',
          subtitle: hasMessages ? 'Conversas recentes' : 'Sem novas conversas',
          color: const Color(0xFFF59E0B),
          onTap: onMessagesTap,
          hasNotification: hasMessages,
          notificationCount: messageCount,
        ),
        _DrawerMenuItem(
          icon: Icons.tune,
          title: 'Configuracao',
          subtitle: 'Pagamentos antes do embarque',
          color: const Color(0xFF111827),
          onTap: onSettingsTap,
        ),
      ],
    );
  }
}

class _DrawerMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool hasNotification;
  final int notificationCount;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
    this.hasNotification = false,
    this.notificationCount = 0,
  });

  @override
  State<_DrawerMenuItem> createState() => _DrawerMenuItemState();
}

class _DrawerMenuItemState extends State<_DrawerMenuItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE6EAF0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            splashColor: widget.color.withOpacity(0.12),
            highlightColor: Colors.transparent,
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: widget.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(widget.icon, size: 23, color: widget.color),
                      ),
                      if (widget.hasNotification)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE11D48),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                widget.notificationCount > 9
                                    ? '9+'
                                    : '${widget.notificationCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
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
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
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
      ),
    );
  }
}

