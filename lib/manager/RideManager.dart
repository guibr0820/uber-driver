import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver/manager/user_manager.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';


class RideManager {
  final UserManager userManager;
  RideManager(this.userManager);

  final CollectionReference ridesCollection =
  FirebaseFirestore.instance.collection('rides');


  Stream<QuerySnapshot> offeredRideStream(String driverId) {
    return FirebaseFirestore.instance
        .collection('rides')
        .where('status', isEqualTo: 'offered')
        .where('currentDriver', isEqualTo: driverId)
        .snapshots();
  }

  /// Cria uma nova corrida

  /// Retorna stream de atualizações da corrida
  Stream<Map<String, dynamic>?> rideStream(String rideId) {
    return ridesCollection.doc(rideId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return null;
    });
  }

  /// Atualiza posição do motorista
  Future<void> updateDriverLocation(
      String rideId, LatLng driverLocation, String driverId) async {
    await ridesCollection.doc(rideId).update({
      'driverId': driverId,
      'driverLocation': {
        'lat': driverLocation.latitude,
        'lng': driverLocation.longitude
      },
      'driverLocationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Motorista aceita a corrida
  Future<void> acceptRide(
      String rideId,
      String driverId,
      LatLng initialLocation,
      ) async {
    final ref = ridesCollection.doc(rideId);
    bool accepted = false;

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;

      // 🔒 SEGURANÇA TOTAL
      if (data['status'] != 'offered') return;
      if (data['currentDriver'] != driverId) return;

      tx.update(ref, {
        'status': 'accepted',
        'driverId': driverId,
        'driverLocation': {
          'lat': initialLocation.latitude,
          'lng': initialLocation.longitude,
        },
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      accepted = true;
    });

    // 🔐 deixa o motorista indisponível SOMENTE se aceitou
    if (accepted) {
      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .update({
        'available': false,
      });
    }
  }  /// Atualiza status
  Future<void> updateRideStatus(String rideId, String status) async {
    await ridesCollection.doc(rideId).update({'status': status});
  }

  Future<void> updateDriverPresence({
    required String driverId,
    required double lat,
    required double lng,
  }) async {
    await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .set({
      'lat': lat,
      'lng': lng,
      'online': true,
      'available': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}