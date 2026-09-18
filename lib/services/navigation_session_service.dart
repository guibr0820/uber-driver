import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_navigation_flutter/google_navigation_flutter.dart';

import '../screens/drivers/dialogs/show_start_ride_dialog.dart';

class NavigationSessionService {
  final BuildContext context;
  final Future<bool> Function() checkLocationPermission;
  final bool Function() canStartRide;
  final VoidCallback startRide;
  final VoidCallback finishRide;
  final void Function(bool) onSessionReady;

  GoogleNavigationViewController? controller;
  StreamSubscription<OnArrivalEvent>? arrivalSubscription;

  bool _initializingSession = false;
  bool _sessionInitialized = false;
  bool _rideStarted = false;
  bool _startDialogPending = false;

  NavigationSessionService({
    required this.context,
    required this.checkLocationPermission,
    required this.canStartRide,
    required this.startRide,
    required this.finishRide,
    required this.onSessionReady,
  });

  /// ⛔ MÉTODO INTACTO (somente copiado)
  Future<void> initSession() async {
    if (_initializingSession || _sessionInitialized) return;

    _initializingSession = true;

    try {
      print("✅ Iniciando sessão...");

      bool permissionGranted = await checkLocationPermission();
      if (!permissionGranted) {
        print("❌ Permissão de localização negada.");
        return;
      }

      bool accepted = await GoogleMapsNavigator.areTermsAccepted();

      if (!accepted) {
        accepted = await GoogleMapsNavigator.showTermsAndConditionsDialog(
          "Move Driver",
          "Move Tecnologia",
        );
      }

      if (!accepted) {
        print("❌ Usuário não aceitou os termos.");
        return;
      }

      await GoogleMapsNavigator.initializeNavigationSession(
        taskRemovedBehavior: TaskRemovedBehavior.continueService,
      );

      arrivalSubscription = GoogleMapsNavigator.setOnArrivalListener(
            (OnArrivalEvent event) {
          print("📍 Chegou no destino atual");

          if (!_rideStarted) {

            _showStartRideDialogWhenAllowed();
          } else {
            finishRide();
          }
        },
      );

      print("✅ Sessão inicializada");

      _sessionInitialized = true;
      onSessionReady(true);
    } on SessionInitializationException catch (e) {
      print("❌ Erro ao inicializar sessão: ${e.code}");
    } catch (e) {
      print("❌ Erro inesperado: $e");
    } finally {
      _initializingSession = false;
    }
  }

  // Ajuste Move: permite disparar o diálogo por distância reta, sem depender só do evento de chegada do Google Navigation.
  void maybeShowStartRideDialog() {
    _showStartRideDialogWhenAllowed();
  }

  void _showStartRideDialogWhenAllowed() {
    if (_startDialogPending || _rideStarted) return;

    if (!canStartRide()) {
      print("Corrida ainda nao liberada para embarque.");
      _startDialogPending = true;

      Future.delayed(const Duration(seconds: 12), () {
        _startDialogPending = false;
        if (canStartRide() && !_rideStarted) {
          _showStartRideDialogWhenAllowed();
        }
      });
      return;
    }

    _startDialogPending = true;
    showStartRideDialog(
      context: context,
      onConfirm: () {
        _rideStarted = true;
        _startDialogPending = false;
        startRide();
      },
    ).whenComplete(() {
      if (!_rideStarted) {
        _startDialogPending = false;
      }
    });
  }

  void dispose() {
    arrivalSubscription?.cancel();
    GoogleMapsNavigator.cleanup();
  }
}
