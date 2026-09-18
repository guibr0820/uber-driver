import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

class RideAvailableCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final String rideId;
  final String passengerName;

  final Map origin;
  final Map destination;

  final LatLng originLatLng;

  final double? distanceToPickupKm;
  final int? durationToPickupMin;

  final double? rideDistanceKm;
  final int? rideDurationMin;

  final bool showRideCard;

  final Future<String> Function(double, double) getAddressFromLatLng;

  final VoidCallback onClose;

  final void Function(Map<String, dynamic>) onSetAcceptedRideData;

  final Function(LatLng) addPassengerMarker;
  final Function(LatLng) addDestinationMarker;

  final Future<void> Function(String, LatLng, double) acceptRide;

  const RideAvailableCard({
    Key? key,
    required this.ride,
    required this.rideId,
    required this.passengerName,
    required this.origin,
    required this.destination,
    required this.originLatLng,
    required this.getAddressFromLatLng,
    required this.onClose,
    required this.onSetAcceptedRideData,
    required this.addPassengerMarker,
    required this.addDestinationMarker,
    required this.acceptRide,
    this.distanceToPickupKm,
    this.durationToPickupMin,
    this.rideDistanceKm,
    this.rideDurationMin,
    required this.showRideCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showRideCard) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [

        /// HEADER
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueGrey.shade400,
                Colors.blueGrey.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Corrida disponível",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: onClose,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        /// PASSAGEIRO
        Row(
          children: [
            const Icon(Icons.person, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                passengerName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        /// DISTÂNCIA ATÉ PASSAGEIRO
        if (distanceToPickupKm != null &&
            durationToPickupMin != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, size: 18, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    "${distanceToPickupKm!.toStringAsFixed(1)} km",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, size: 18, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    "$durationToPickupMin min",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 15),

        /// PARTIDA
        _buildLocationBlock(
          context,
          icon: Icons.location_pin,
          color: Colors.green,
          title: "PARTIDA",
          lat: origin['lat'],
          lng: origin['lng'],
        ),

        /// DISTÂNCIA DA CORRIDA
        if (rideDistanceKm != null &&
            rideDurationMin != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    "${rideDistanceKm!.toStringAsFixed(1)} km • $rideDurationMin min",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        /// DESTINO
        _buildLocationBlock(
          context,
          icon: Icons.flag,
          color: Colors.red,
          title: "DESTINO",
          lat: destination['lat'],
          lng: destination['lng'],
        ),

        const SizedBox(height: 15),

        /// VALOR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blueAccent.shade400,
                Colors.blueAccent.shade400,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "VALOR DA CORRIDA",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "R\$ ${(ride["price"] as num).toDouble().toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 15),

        /// BOTÃO ACEITAR
        ElevatedButton(
          onPressed: () async {

            final originName =
            await getAddressFromLatLng(origin['lat'], origin['lng']);
            final destinationName =
            await getAddressFromLatLng(destination['lat'], destination['lng']);

            await FirebaseFirestore.instance
                .collection("rides")
                .doc(rideId)
                .update({
              "originName": originName,
              "destinationName": destinationName,
            });

            final acceptedData = {
              "passengerName": passengerName,
              "origin": originLatLng,
              "destination": LatLng(
                latitude: destination['lat'],
                longitude: destination['lng'],
              ),
              "originName": originName,
              "destinationName": destinationName,
              "price": ride["price"],
              "paymentMethod": ride["paymentMethod"],
              "pix_status": ride["pix_status"],
              "pix_qr_code": ride["pix_qr_code"],
            };

            onSetAcceptedRideData(acceptedData);

            addPassengerMarker(originLatLng);
            addDestinationMarker(
              LatLng(
                latitude: destination['lat'],
                longitude: destination['lng'],
              ),
            );
            acceptRide(rideId, originLatLng, acceptedData["price"]);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            "Aceitar corrida",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBlock(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required double lat,
        required double lng,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// LINHA + PONTO
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 60,
              color: Colors.grey.shade300,
            ),
          ],
        ),

        const SizedBox(width: 12),

        /// BLOCO DE ENDEREÇO
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: FutureBuilder<String>(
              future: getAddressFromLatLng(lat, lng),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Text("Carregando...");
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snap.data!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }}
