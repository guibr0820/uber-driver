import 'dart:async';
import 'package:driver/screens/drivers/components/ride_avaiable_card.dart';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class RideRequestContainer extends StatefulWidget {
  final Map<String, dynamic> ride;
  final String rideId;
  final Future<void> Function(String, LatLng, double) acceptRide;

  const RideRequestContainer({
    super.key,
    required this.ride,
    required this.rideId,
    required this.acceptRide,
  });

  @override
  State<RideRequestContainer> createState() =>
      _RideRequestContainerState();
}

class _RideRequestContainerState
    extends State<RideRequestContainer> {
  bool _isExpanded = false;
  int _secondsLeft = 40;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final origin = widget.ride["origin"];
    final destination = widget.ride["destination"];

    final originLatLng = LatLng(
      latitude: origin["lat"],
      longitude: origin["lng"],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Header
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              children: [
                const Icon(Icons.local_taxi, color: Colors.amber),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Nova corrida disponível",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(_isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// Progress + contador
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Aguardando você aceitar...",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    "$_secondsLeft s",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _secondsLeft <= 10
                          ? Colors.red
                          : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _secondsLeft / 40,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _secondsLeft <= 5
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ),
            ],
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 15),
            RideAvailableCard(
              ride: widget.ride,
              rideId: widget.rideId,
              passengerName: widget.ride["passengerName"] ?? "Passageiro",
              origin: origin,
              destination: destination,
              originLatLng: originLatLng,
              showRideCard: true,
              acceptRide: widget.acceptRide,

              getAddressFromLatLng: (lat, lng) async {
                return "Endereço não disponível";
              },

              onClose: () {
                setState(() {
                  _isExpanded = false;
                });
              },

              onSetAcceptedRideData: (data) {},

              addPassengerMarker: (latLng) {},

              addDestinationMarker: (latLng) {},
            ),
          ]
        ],
      ),
    );
  }
}