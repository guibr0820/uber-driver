import 'package:flutter/material.dart';

import '../../Chat/chat_screen.dart';

class AcceptRideConteiner extends StatelessWidget {
  final bool rideCardExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onCancelRide;
  final bool pixGerado;
  final bool pixLoading;
  final bool rideStarted;
  final bool rideFinished;
  final bool paymentApproved;
  final VoidCallback onGerarPix;
  final VoidCallback onCloseSummary;
  final Map<String, dynamic> acceptedRideData;
  final String? rideId;

  const AcceptRideConteiner({
    super.key,
    required this.rideCardExpanded,
    required this.onToggleExpand,
    required this.onCancelRide,
    required this.onCloseSummary,
    required this.pixGerado,
    required this.pixLoading,
    required this.onGerarPix,
    required this.acceptedRideData,
    required this.rideId,
    required this.rideStarted,
    required this.rideFinished,
    required this.paymentApproved,
  });

  @override
  Widget build(BuildContext context) {
    final passengerName = acceptedRideData['passengerName']?.toString() ?? 'Passageiro';
    final paymentMethod = acceptedRideData['paymentMethod']?.toString() ?? '-';
    final price = (acceptedRideData['price'] as num?)?.toDouble() ?? 0;
    final title = rideFinished
        ? paymentApproved
            ? 'Corrida concluida'
            : 'Aguardando pagamento'
        : rideStarted
            ? 'Corrida iniciada'
            : 'Corrida aceita';
    final subtitle = rideFinished
        ? paymentApproved
            ? 'Pagamento confirmado. Veja o resumo da corrida'
            : 'A viagem acabou. Aguarde o passageiro pagar'
        : rideStarted
            ? 'Leve o passageiro ate o destino final'
            : 'Siga ate o ponto de embarque';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onToggleExpand,
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (rideFinished && paymentApproved) ...[
                        _IconButtonBox(
                          icon: Icons.close,
                          color: const Color(0xFF111827),
                          onTap: onCloseSummary,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: rideFinished
                              ? paymentApproved
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFF59E0B)
                              : rideStarted
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          rideFinished
                              ? paymentApproved
                                  ? Icons.check_circle
                                  : Icons.hourglass_top
                              : rideStarted
                                  ? Icons.navigation
                                  : Icons.person_pin_circle,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _IconButtonBox(
                        icon: rideCardExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up,
                        color: const Color(0xFF0F172A),
                        onTap: onToggleExpand,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoPanel(
                    icon: Icons.person,
                    iconColor: const Color(0xFF2563EB),
                    label: 'PASSAGEIRO',
                    value: passengerName,
                  ),
                ),
                const SizedBox(width: 10),
                _IconButtonBox(
                  icon: Icons.chat_bubble_outline,
                  color: const Color(0xFF2563EB),
                  onTap: rideId == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(rideId: rideId!),
                            ),
                          );
                        },
                ),
                const SizedBox(width: 8),
                _IconButtonBox(
                  icon: pixLoading ? Icons.hourglass_top : Icons.pix,
                  color: pixGerado ? const Color(0xFF94A3B8) : const Color(0xFF16A34A),
                  onTap: (pixGerado || pixLoading) ? null : onGerarPix,
                ),
              ],
            ),
            if (rideCardExpanded) ...[
              const SizedBox(height: 12),
              if (!rideStarted && acceptedRideData['origin'] is Map)
                _RoutePanel(
                  icon: Icons.my_location,
                  color: const Color(0xFF16A34A),
                  label: 'EMBARQUE',
                  location: Map<String, dynamic>.from(acceptedRideData['origin']),
                ),
              if (!rideStarted && acceptedRideData['origin'] is Map)
                const SizedBox(height: 10),
              if (acceptedRideData['destination'] is Map)
                _RoutePanel(
                  icon: Icons.flag,
                  color: const Color(0xFFEF4444),
                  label: rideStarted ? 'DESTINO FINAL' : 'DESTINO',
                  location: Map<String, dynamic>.from(acceptedRideData['destination']),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MoneyPanel(price: price),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoPanel(
                      icon: Icons.payments_outlined,
                      iconColor: const Color(0xFF7C3AED),
                      label: 'PAGAMENTO',
                      value: paymentMethod.toUpperCase(),
                    ),
                  ),
                ],
              ),
              if (rideFinished && !paymentApproved) ...[
                const SizedBox(height: 12),
                _PaymentWaitingPanel(paymentMethod: paymentMethod),
              ],
              if (rideFinished && paymentApproved) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCloseSummary,
                    icon: const Icon(Icons.done_all, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: const Text(
                      'Voltar ao modo online',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}


class _PaymentWaitingPanel extends StatelessWidget {
  final String paymentMethod;

  const _PaymentWaitingPanel({required this.paymentMethod});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pagamento pendente',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Metodo: ${paymentMethod.toUpperCase()}. O app libera o resumo assim que aprovar.',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _RoutePanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Map<String, dynamic> location;

  const _RoutePanel({
    required this.icon,
    required this.color,
    required this.label,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    final address = location['address']?.toString() ?? '';
    final parts = address.split(',');
    final title = parts.isNotEmpty ? parts.first.trim() : 'Endereco';
    final subtitle = parts.length > 1 ? parts.sublist(1).join(',').trim() : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoPanel({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyPanel extends StatelessWidget {
  final double price;

  const _MoneyPanel({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF052E16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.attach_money, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VALOR',
                  style: TextStyle(
                    color: Color(0xFFBBF7D0),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'R\$ ${price.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButtonBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _IconButtonBox({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withOpacity(onTap == null ? 0.04 : 0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(onTap == null ? 0.08 : 0.16)),
        ),
        child: Icon(icon, color: onTap == null ? const Color(0xFF94A3B8) : color),
      ),
    );
  }
}