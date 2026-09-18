import 'dart:async';

import 'widget/online_status_button.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../manager/user_manager.dart';
import '../../Home/CustomAppBar.dart';
import '../../manager/RideManager.dart';
import 'package:geocoding/geocoding.dart';

import '../../services/geocoding_service.dart';
import '../../services/navigation_session_service.dart';
import 'components/accept_ride_conteiner.dart';
import 'dialogs/show_start_ride_dialog.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
part 'driver_navigation_methods.dart';

class DriverNavigationScreen extends StatefulWidget {
  final double destinoLat;
  final double destinoLng;

  const DriverNavigationScreen({
    super.key,
    required this.destinoLat,
    required this.destinoLng,
  });

  @override
  State<DriverNavigationScreen> createState() =>
      _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  GoogleNavigationViewController? _controller;
  bool _sessionReady = false;

  bool _rideAccepted = false;
  bool _rideStarted = false;
  bool _rideFinished = false;
  bool _ridePaymentApproved = false;
  bool _finishRideDialogShowing = false;
  bool _isExpanded = false;
  bool _acceptedCardExpanded = false;
  bool _timerStarted = false;
  bool _rideCanNavigateToPickup = true;
  bool _rideCanStartPassengerTrip = true;
  bool _pickupNavigationStarted = false;
  DateTime? _pickupNavigationStartedAt;
  bool _recoveringActiveRide = false;
  bool _activeRideRecovered = false;
  // Ajuste Move: tolerÃ¢ncia em linha reta para considerar o motorista no ponto de embarque.
  static const double _pickupArrivalToleranceMeters = 80;
  static const double _destinationArrivalToleranceMeters = 120;


  Map<String, dynamic>? _acceptedRideData;
  String? _acceptedRideId;
  String? _ignoredRideId;
  String? _lastNotifiedRideId;

  int _secondsLeft = 30;
  Timer? _rideTimer;
  final AudioPlayer _rideNotificationPlayer = AudioPlayer();

  LatLng? _pickupLatLng;
  LatLng? _destinationLatLng;
  LatLng? _currentLatLng;
  // Ajuste Move: controla envio da posição do motorista para a corrida sem escrever no Firestore a cada tick do GPS.
  LatLng? _lastRideLocationSent;
  DateTime? _lastRideLocationSentAt;

  late RideManager _rideManager;
  late NavigationSessionService _navigationSessionService;
  StreamSubscription<DocumentSnapshot>? _rideStatusListener;

  Future<bool> _checkLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) return true;

    final fallbackStatus = await Permission.location.request();
    return fallbackStatus.isGranted;
  }

  void _onViewCreated(GoogleNavigationViewController controller) {
    _controller = controller;
    _navigationSessionService.controller = controller;
  }

  Future<void> _notifyNewRide(String rideId) async {
    if (_lastNotifiedRideId == rideId) return;
    _lastNotifiedRideId = rideId;
    HapticFeedback.mediumImpact();
    try {
      await _rideNotificationPlayer.stop();
      await _rideNotificationPlayer.play(AssetSource('song_notification.mp3'));
    } catch (_) {
      SystemSound.play(SystemSoundType.alert);
    }
  }

  void _dismissOfferedRide(String rideId) {
    _rideTimer?.cancel();
    setState(() {
      _ignoredRideId = rideId;
      _timerStarted = false;
      _isExpanded = false;
      _secondsLeft = 60;
    });
  }

  @override
  void initState() {
    super.initState();

    _rideManager = RideManager(UserManager());

    _navigationSessionService = NavigationSessionService(
      context: context,
      checkLocationPermission: _checkLocationPermission,
      canStartRide: () {
        final startedAt = _pickupNavigationStartedAt;
        final passedGracePeriod = startedAt != null &&
            DateTime.now().difference(startedAt) >
                const Duration(seconds: 12);
        final driverPosition = _currentLatLng;
        final pickupPosition = _pickupLatLng;
        final insidePickupTolerance =
            driverPosition != null &&
                pickupPosition != null &&
                Geolocator.distanceBetween(
                  driverPosition.latitude,
                  driverPosition.longitude,
                  pickupPosition.latitude,
                  pickupPosition.longitude,
                ) <=
                    _pickupArrivalToleranceMeters;

        // Ajuste Move: embarque sÃ³ libera se Pix/regra permitir, a rota jÃ¡ tiver comeÃ§ado e a distÃ¢ncia reta estiver dentro da tolerÃ¢ncia.
        return _rideCanStartPassengerTrip &&
            passedGracePeriod &&
            insidePickupTolerance;
      },
      startRide: _startRide,
      finishRide: _finishRide,
      onSessionReady: (ready) {
        if (mounted) {
          setState(() => _sessionReady = ready);
          if (ready) {
            // Ajuste Move: tenta recuperar a corrida depois que a sessÃ£o de navegaÃ§Ã£o estiver pronta.
            _recoverActiveRide();
          }
        }
      },
    );
    _navigationSessionService.initSession();
    _startLocationTracking();
    // ðŸ”¥ RECUPERA CORRIDA ATIVA
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recoverActiveRide();
    });
  }


  Widget _buildLocationBlock({
    required IconData icon,
    required Color color,
    required String title,
    required double lat,
    required double lng,
    required String? address,
  }) {
    final parts = (address ?? "").split(",");

    final titulo = parts.isNotEmpty ? parts[0].trim() : "";
    final resto = parts.length > 1
        ? parts.sublist(1).join(",").trim()
        : "";

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          /// ðŸ”¥ USA ADDRESS DIRETO
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            resto,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final driver = _rideManager.userManager.user;
    final driverId = driver?.id ?? "";

    return Scaffold(
    //  extendBodyBehindAppBar: true,

      // backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Builder(
          builder: (context) {
            return CustomAppBar(
              onMenuTap: () {
                Navigator.of(context).pushNamed('/driver_drawer');
              },
              onNotificationTap: () {
                print('ðŸ”” Abrir notificaÃ§Ãµes');
              },
            );
          },
        ),
      ),
      body: _sessionReady
          ? Stack(
        children: [
          GoogleMapsNavigationView(
            onViewCreated: _onViewCreated,
          ),
          // BotÃ£o Online/Offline flutuante no canto superior direito
          StreamBuilder<QuerySnapshot>(
            stream: _rideManager.offeredRideStream(driverId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              if (snapshot.data!.docs.isEmpty) {
                return const SizedBox();
              }

              final offeredRidesCount = snapshot.data!.docs.length;
              final rideDoc = snapshot.data!.docs.first;
              final ride = rideDoc.data() as Map<String, dynamic>;
              final rideId = rideDoc.id;

              double? distanceToPickup;
              double? distanceToDestination;

              if (_currentLatLng != null) {
                distanceToPickup = calculateDistanceKm(
                  _currentLatLng!.latitude,
                  _currentLatLng!.longitude,
                  ride['origin']['lat'],
                  ride['origin']['lng'],
                );

                distanceToDestination = calculateDistanceKm(
                  ride['origin']['lat'],
                  ride['origin']['lng'],
                  ride['destination']['lat'],
                  ride['destination']['lng'],
                );
              }

              if (_ignoredRideId == rideId) {
                return const SizedBox();
              }
              if (_rideAccepted) return const SizedBox();

              _notifyNewRide(rideId);

              if (!_timerStarted) {
                _timerStarted = true;
                _startRideTimer(rideId);
              }
              if (!_isExpanded) {
                return Positioned(
                  right: 16,
                  top: 18,
                  child: Dismissible(
                    key: ValueKey('ride-bubble-$rideId'),
                    direction: DismissDirection.horizontal,
                    onDismissed: (_) => _dismissOfferedRide(rideId),
                    child: GestureDetector(
                      onTap: () => setState(() => _isExpanded = true),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.92, end: 1),
                        duration: const Duration(milliseconds: 650),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) => Transform.scale(
                          scale: _secondsLeft <= 10 ? 1.04 : scale,
                          child: child,
                        ),
                        child: Container(
                          width: 152,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.26),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF111827),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.local_taxi,
                                  color: Color(0xFFFFC857),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      offeredRidesCount > 1
                                          ? '$offeredRidesCount chamadas'
                                          : 'Nova corrida',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF111827),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'R\$ ${(ride["price"] as num).toDouble().toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _secondsLeft <= 10
                                      ? Colors.redAccent
                                      : const Color(0xFFEAF8EF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${_secondsLeft}s',
                                  style: TextStyle(
                                    color: _secondsLeft <= 10
                                        ? Colors.white
                                        : const Color(0xFF117A3A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
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

              return Positioned(
                bottom: 104,
                left: 16,
                right: 16,
                child: Dismissible(
                  key: ValueKey('ride-card-$rideId'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) => _dismissOfferedRide(rideId),
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 24),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.24),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _isExpanded = !_isExpanded),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF111827),
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                    child: const Icon(
                                      Icons.local_taxi,
                                      color: Color(0xFFFFC857),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Nova corrida disponivel',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Color(0xFF111827),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 17,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          ride['passengerName'] ?? 'Passageiro',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF8EF),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      'R\$ ${(ride["price"] as num).toDouble().toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Color(0xFF117A3A),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tempo para aceitar',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '$_secondsLeft s',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: _secondsLeft <= 10
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF111827),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: (_secondsLeft / 60).clamp(0.0, 1.0).toDouble(),
                                    minHeight: 7,
                                    backgroundColor: const Color(0xFFE5E7EB),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _secondsLeft <= 10
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isExpanded) ...[
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.near_me, size: 18, color: Color(0xFF2563EB)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              distanceToPickup != null
                                                  ? '${distanceToPickup.toStringAsFixed(1)} km ate o passageiro'
                                                  : 'Calculando busca',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF1D4ED8),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F3FF),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.route, size: 18, color: Color(0xFF7C3AED)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              distanceToDestination != null
                                                  ? '${distanceToDestination.toStringAsFixed(1)} km ate o destino'
                                                  : 'Destino calculando',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Color(0xFF6D28D9),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  _buildLocationBlock(
                                    icon: Icons.location_pin,
                                    color: const Color(0xFF16A34A),
                                    title: 'PARTIDA',
                                    lat: ride['origin']['lat'],
                                    lng: ride['origin']['lng'],
                                    address: ride['origin']['address'],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildLocationBlock(
                                    icon: Icons.flag,
                                    color: const Color(0xFFEF4444),
                                    title: 'DESTINO',
                                    lat: ride['destination']['lat'],
                                    lng: ride['destination']['lng'],
                                    address: ride['destination']['address'],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: const Icon(Icons.payments, color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 11),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'VALOR DA CORRIDA',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white60,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'R\$ ${(ride["price"] as num).toDouble().toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.account_balance_wallet, color: Color(0xFF334155), size: 19),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Pagamento',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF8EF),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        (ride['paymentMethod'] ?? 'Nao informado').toString().toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF117A3A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: SizedBox(
                                height: 54,
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    _rideTimer?.cancel();
                                    _timerStarted = false;
                                    _isExpanded = false;

                                    final driver = _rideManager.userManager.user;
                                    print("ðŸ‘¤ Driver: $driver");

                                    if (driver == null) {
                                      print("âŒ Motorista NÃƒO estÃ¡ logado");
                                      return;
                                    }

                                    final driverId = driver.id;
                                    print("ðŸ†” Driver ID: $driverId");

                                    final driverDoc = await FirebaseFirestore
                                        .instance
                                        .collection('drivers')
                                        .doc(driverId)
                                        .get();
                                    final pixBeforePickup = driverDoc.data()?['pixBeforePickup'] == true;
                                    final cardBeforePickup = driverDoc.data()?['cardBeforePickup'] == true;
                                    final driverLocation = _currentLatLng ??
                                        LatLng(
                                          latitude: ride['origin']['lat'],
                                          longitude: ride['origin']['lng'],
                                        );

                                    await _rideManager.acceptRide(rideId, driverId!, driverLocation);
                                    print("âœ… Corrida aceita no Firestore");
                                    _acceptRide(
                                      ride,
                                      rideId,
                                      pixBeforePickup: pixBeforePickup,
                                      cardBeforePickup: cardBeforePickup,
                                    );
                                  },
                                  icon: const Icon(Icons.check_circle, color: Colors.white),
                                  label: const Text(
                                    'Aceitar corrida',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF16A34A),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(17),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // âœ… BOTÃƒO ONLINE / OFFLINE FLUTUANTE
          Positioned(
            bottom: 20, // distÃ¢ncia do rodapÃ©
            right: 20,  // distÃ¢ncia da borda direita
            child: OnlineStatusButton(
              driverId: _rideManager.userManager.user?.id ?? "",
              size: 70,
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),

      // â¬‡ï¸ â¬‡ï¸ â¬‡ï¸ Ã‰ AQUI QUE VOCÃŠ COLA â¬‡ï¸ â¬‡ï¸ â¬‡ï¸
      bottomNavigationBar: _rideAccepted && _acceptedRideData != null
          ? SafeArea(
        top: false,
        child: AcceptRideConteiner(
          rideCardExpanded: _acceptedCardExpanded,
          onToggleExpand: () {
            setState(() {
              _acceptedCardExpanded = !_acceptedCardExpanded;
            });
          },
          onCancelRide: () {
            // opcional
          },
          onCloseSummary: () {
            setState(() {
              _isExpanded = false;
              _rideAccepted = false;
              _rideFinished = false;
              _ridePaymentApproved = false;
              _finishRideDialogShowing = false;
              _acceptedRideData = null;
              _acceptedRideId = null;
              _rideCanNavigateToPickup = true;
              _rideCanStartPassengerTrip = true;
              _pickupNavigationStarted = false;
              _pickupNavigationStartedAt = null;
              _activeRideRecovered = false;
            });
          },
          pixGerado: _acceptedRideData?['pix_qr_code'] != null,
          pixLoading: _acceptedRideData?['paymentMethod']
                      ?.toString()
                      .toLowerCase() ==
                  'pix' &&
              _acceptedRideData?['pix_status'] != 'approved',
          onGerarPix: () {},
          acceptedRideData: _acceptedRideData!,
          rideId: _acceptedRideId,
          rideStarted: _rideStarted,
          rideFinished: _rideFinished,
          paymentApproved: _ridePaymentApproved,
        ),

      )
          : null,

    );

  }

  @override
  void dispose() {
    _rideTimer?.cancel();
    _rideStatusListener?.cancel();
    _rideNotificationPlayer.dispose(); // ðŸ‘ˆ importante
    _navigationSessionService.dispose();
    super.dispose();
  }
}
