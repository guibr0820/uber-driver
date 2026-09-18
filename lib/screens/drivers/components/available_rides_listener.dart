import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';
import '../../../manager/RideManager.dart';
import 'ride_request_container.dart';

class AvailableRidesListener extends StatelessWidget {
  final RideManager rideManager;
  final String driverId;
  final Future<void> Function(String, LatLng, double) acceptRide;

  const AvailableRidesListener({
    super.key,
    required this.rideManager,
    required this.driverId,
    required this.acceptRide,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: rideManager.offeredRideStream(driverId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final rides = snapshot.data!.docs;

        if (rides.isEmpty) return const SizedBox();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: rides.map((doc) {
            final rideData = doc.data() as Map<String, dynamic>;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RideRequestContainer(
                ride: rideData,
                rideId: doc.id,
                acceptRide: acceptRide,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}