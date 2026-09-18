part of 'driver_navigation_screen.dart';

extension DriverNavigationMethods on _DriverNavigationScreenState {

  Future<Map<String, dynamic>> _driverPaymentPickupRules() async {
    final driverId = _rideManager.userManager.user?.id;
    if (driverId == null || driverId.isEmpty) {
      return {
        'pixBeforePickup': true,
        'cardBeforePickup': true,
      };
    }

    final driverDoc = await FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .get();

    final data = driverDoc.data() ?? <String, dynamic>{};
    return {
      'pixBeforePickup': data['pixBeforePickup'] == true,
      'cardBeforePickup': data['cardBeforePickup'] == true,
    };
  }

  bool _isCardPaymentMethod(String? paymentMethod) {
    final method = paymentMethod?.toLowerCase().trim() ?? '';
    return method == 'card' ||
        method == 'credit_card' ||
        method == 'credito' ||
        method == 'cartao' ||
        method == 'cartao_credito' ||
        method == 'credit';
  }


  bool _isRidePaymentSettled(Map<String, dynamic> ride) {
    final paymentMethod = ride['paymentMethod']?.toString().trim().toLowerCase();
    final pixStatus = ride['pix_status']?.toString().trim().toLowerCase();

    if (paymentMethod == 'pix') return pixStatus == 'approved';

    final cardStatus = ride['card_status']?.toString().trim().toLowerCase();
    if (_isCardPaymentMethod(paymentMethod)) {
      return cardStatus == 'approved' ||
          cardStatus == 'captured' ||
          cardStatus == 'paid';
    }

    final paymentStatus = ride['payment_status']?.toString().trim().toLowerCase() ??
        ride['paymentStatus']?.toString().trim().toLowerCase();
    return paymentStatus == 'approved' ||
        paymentStatus == 'authorized' ||
        paymentStatus == 'paid' ||
        paymentStatus == 'captured' ||
        paymentMethod == 'cash' ||
        paymentMethod == 'dinheiro';
  }
  bool _isPaymentApproved(Map<String, dynamic> ride) {
    final values = [
      ride['pix_status'],
      ride['card_status'],
      ride['credit_status'],
      ride['payment_status'],
      ride['paymentStatus'],
    ].map((value) => value?.toString().toLowerCase().trim()).toList();

    return values.any(
      (status) =>
          status == 'approved' ||
          status == 'authorized' ||
          status == 'paid' ||
          status == 'captured',
    );
  }

  Future<void> _syncPixRules(
    Map<String, dynamic> ride, {
    bool? pixBeforePickup,
    bool? cardBeforePickup,
  }) async {
    final paymentMethod = ride['paymentMethod']?.toString().toLowerCase();
    final isPixRide = paymentMethod == 'pix';
    final isCardRide = _isCardPaymentMethod(paymentMethod);
    final paymentApproved = _isPaymentApproved(ride);
    final rules = (pixBeforePickup == null || cardBeforePickup == null)
        ? await _driverPaymentPickupRules()
        : <String, dynamic>{};

    final requirePixBeforePickup =
        isPixRide && (pixBeforePickup ?? rules['pixBeforePickup'] == true);
    final requireCardBeforePickup =
        isCardRide && (cardBeforePickup ?? rules['cardBeforePickup'] == true);
    final requiresPaymentBeforePickup =
        requirePixBeforePickup || requireCardBeforePickup;

    _rideCanNavigateToPickup = !requiresPaymentBeforePickup || paymentApproved;
    _rideCanStartPassengerTrip =
        !requiresPaymentBeforePickup || paymentApproved;
  }
  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final place = placemarks.first;

      return "${place.street}, ${place.subLocality}, ${place.locality}";
    } catch (e) {
      return "EndereÃ§o nÃ£o encontrado";
    }
  }

  // TEMPO DE CORRIDA DISPONIVEL APARECENDO NA TELA
  void _startRideTimer(String rideId) {
    _rideTimer?.cancel();
    _secondsLeft = 60;

    _rideTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsLeft--;

        if (_secondsLeft <= 0) {
          timer.cancel();

          _timerStarted = false;
          _isExpanded = false;

          // ðŸš« marca como ignorada
          _ignoredRideId = rideId;
        }
      });
    });
  }

  // DEFININDO ROTA ATÃ‰ O PASSAGEIRO
  Future<void> _navigateToPickup() async {
    if (_pickupLatLng == null) return;

    print("ðŸ“ Definindo destino passageiro...");

    _pickupNavigationStartedAt = DateTime.now();

    final waypoint = NavigationWaypoint(
      title: "Passageiro",
      target: LatLng(
        latitude: _pickupLatLng!.latitude,
        longitude: _pickupLatLng!.longitude,
      ),
    );

    final destinations = Destinations(
      waypoints: [waypoint],
      displayOptions: NavigationDisplayOptions(),
    );

    await GoogleMapsNavigator.setDestinations(destinations);

    print("ðŸ§­ Iniciando guidance...");
    await GoogleMapsNavigator.startGuidance();

    print("âœ… Guidance iniciado");
  }

  // DEFININDO ROTA ATÃ‰ O DESTINO DO PASSAGEIRO
  Future<void> _navigateToDestination() async {
    if (_destinationLatLng == null) return;

    final waypoint = NavigationWaypoint(
      title: "Destino",
      target: LatLng(
        latitude: _destinationLatLng!.latitude,
        longitude: _destinationLatLng!.longitude,
      ),
    );

    final destinations = Destinations(
      waypoints: [waypoint],
      displayOptions: NavigationDisplayOptions(),
    );

    await GoogleMapsNavigator.setDestinations(destinations);
    await GoogleMapsNavigator.startGuidance();
  }

  // ACEITANDO A CORRIDA
  void _acceptRide(
    Map<String, dynamic> ride,
    String rideId, {
    bool? pixBeforePickup,
      bool? cardBeforePickup,
  }) async {
    if (!_sessionReady) return;

    await _syncPixRules(
      ride,
      pixBeforePickup: pixBeforePickup,
      cardBeforePickup: cardBeforePickup,
    );
    _pickupNavigationStarted = _rideCanNavigateToPickup;

    setState(() {
      _rideAccepted = true;
      _rideFinished = false;
      _ridePaymentApproved = false;
      _finishRideDialogShowing = false;
      _acceptedRideData = ride;
      _acceptedRideId = rideId;

      _pickupLatLng = LatLng(
        latitude: ride['origin']['lat'],
        longitude: ride['origin']['lng'],
      );

      _destinationLatLng = LatLng(
        latitude: ride['destination']['lat'],
        longitude: ride['destination']['lng'],
      );
    });

    print('indo buscar passageiro');

    _listenRideStatus(rideId); // ðŸ‘ˆ AQUI
    if (_rideCanNavigateToPickup) {
      await _navigateToPickup();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aguardando confirmacao do pagamento')),
      );
    }
  }

  // CORRIDA INICIADA
  void _startRide() async {
    if (!_rideCanStartPassengerTrip) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aguarde o pagamento ser confirmado')),
      );
      return;
    }

    if (_acceptedRideId != null) {
      // Ajuste Move: ao confirmar o embarque, marca a corrida em andamento.
      await _rideManager.updateRideStatus(_acceptedRideId!, 'started');
    }

    setState(() {
      _rideStarted = true;
      _rideFinished = false;
      _ridePaymentApproved = false;
      if (_acceptedRideData != null) {
        _acceptedRideData = {
          ..._acceptedRideData!,
          'status': 'started',
        };
      }
    });

    await _navigateToDestination();
  }

  // CORRIDA FINALIZADA
  void _finishRide() async {
    if (_acceptedRideId == null) return;

    final rideData = _acceptedRideData ?? <String, dynamic>{};
    final paymentMethod = rideData['paymentMethod']?.toString().toLowerCase();
    final isCardRide = _isCardPaymentMethod(paymentMethod);
    final cardStatus = rideData['card_status']?.toString().toLowerCase();
    final driverId = _rideManager.userManager.user?.id;

    if (isCardRide &&
        cardStatus == 'authorized' &&
        driverId != null &&
        driverId.isNotEmpty) {
      try {
        final callable = FirebaseFunctions.instance
            .httpsCallable('captureAuthorizedCardPayment');
        await callable.call({
          'rideId': _acceptedRideId,
          'driverUid': driverId,
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel cobrar o cartao.')),
        );
        return;
      }
    }

    await _rideManager.updateRideStatus(_acceptedRideId!, 'finished');
    await GoogleMapsNavigator.stopGuidance();
    await GoogleMapsNavigator.clearDestinations();

    final paymentSettled = _isRidePaymentSettled(rideData);

    setState(() {
      _rideStarted = false;
      _rideFinished = true;
      _ridePaymentApproved = paymentSettled;
      _acceptedCardExpanded = true;
      _pickupNavigationStarted = false;
      _pickupNavigationStartedAt = null;
      if (_acceptedRideData != null) {
        _acceptedRideData = {
          ..._acceptedRideData!,
          'status': 'finished',
        };
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          paymentSettled
              ? 'Corrida concluida. Pagamento confirmado.'
              : 'Viagem finalizada. Aguardando pagamento do passageiro.',
        ),
      ),
    );
  }
  // ATUALIZAÃ‡ÃƒO EM TEMPO REAL DO STATUS DA CORRIDA
  void _listenRideStatus(String rideId) {
    _rideStatusListener?.cancel();

    _rideStatusListener = FirebaseFirestore.instance
        .collection('rides')
        .doc(rideId)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      await _syncPixRules(data);

      final status = data['status']?.toString().trim().toLowerCase();
      final paymentSettled = _isRidePaymentSettled(data);

      if (_acceptedRideData != null) {
        setState(() {
          _acceptedRideData = {..._acceptedRideData!, ...data};
          _rideFinished = status == 'finished';
          _ridePaymentApproved = paymentSettled;
          if (_rideFinished) {
            _rideStarted = false;
            _acceptedCardExpanded = true;
          }
        });
      }

      if (_rideCanNavigateToPickup &&
          !_pickupNavigationStarted &&
          !_rideStarted &&
          !_rideFinished) {
        _pickupNavigationStarted = true;
        await _navigateToPickup();
      }

      if (data['status'] == 'canceled') {
        print("âŒ Corrida cancelada pelo usuÃ¡rio");

        await GoogleMapsNavigator.stopGuidance();
        await GoogleMapsNavigator.clearDestinations(); // ðŸ‘ˆ AQUI

        if (!mounted) return;

        setState(() {
          _rideAccepted = false;
          _rideStarted = false;
          _rideFinished = false;
          _ridePaymentApproved = false;
          _finishRideDialogShowing = false;
          _acceptedRideData = null;
          _acceptedRideId = null;
          _pickupLatLng = null;
          _destinationLatLng = null;
          _isExpanded = false;
          _acceptedCardExpanded = false;
          _rideCanNavigateToPickup = true;
          _rideCanStartPassengerTrip = true;
          _pickupNavigationStarted = false;
          _pickupNavigationStartedAt = null;
          _activeRideRecovered = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("A corrida foi cancelada pelo usuÃ¡rio"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  ///////////////////////////////
  // RECUPERA A CORRIDA MESMO SE FECHAR O APP

  Future<void> _recoverActiveRide() async {
    if (_recoveringActiveRide || _activeRideRecovered || !_sessionReady) return;

    _recoveringActiveRide = true;
    final driver = _rideManager.userManager.user;
    if (driver == null) {
      _recoveringActiveRide = false;
      // Ajuste Move: UserManager pode carregar depois do initState; tenta recuperar novamente.
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _recoverActiveRide();
      });
      return;
    }

    final query = await FirebaseFirestore.instance
        .collection('rides')
        .where('driverId', isEqualTo: driver.id)
        // Ajuste Move: recupera qualquer corrida em andamento quando o motorista reabre o app.
        .where('status', whereIn: [
          'accepted',
          'driver_arrived',
          'started',
          'finished',
          'in_progress',
        ])
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      _recoveringActiveRide = false;
      return;
    }

    final doc = query.docs.first;
    final data = doc.data();
    _activeRideRecovered = true;

    final origin = data['origin'];
    final destination = data['destination'];

    await _syncPixRules(data);
    final activeStatus = data['status']?.toString();
    final isPassengerTripStarted = activeStatus == 'started';
    final isFinished = activeStatus == 'finished';
    final paymentSettled = _isRidePaymentSettled(data);

    _pickupNavigationStarted = isPassengerTripStarted ||
        _rideCanNavigateToPickup;

    setState(() {
      _acceptedRideId = doc.id;
      _acceptedRideData = data;
      _rideAccepted = true;
      _rideStarted = isPassengerTripStarted;
      _rideFinished = isFinished;
      _ridePaymentApproved = paymentSettled;
      _acceptedCardExpanded = isFinished;

      _pickupLatLng = LatLng(
        latitude: origin['lat'],
        longitude: origin['lng'],
      );

      _destinationLatLng = LatLng(
        latitude: destination['lat'],
        longitude: destination['lng'],
      );
    });

    _listenRideStatus(doc.id);

    // ðŸ”¥ Espera o mapa estar pronto
    await Future.delayed(const Duration(milliseconds: 800));

    if (_rideStarted) {
      await _navigateToDestination();
    } else if (_rideFinished) {
      await GoogleMapsNavigator.stopGuidance();
      await GoogleMapsNavigator.clearDestinations();
    } else if (_rideCanNavigateToPickup) {
      await _navigateToPickup();
    }

    _recoveringActiveRide = false;
  }/////////////////////////////////////////
// EX: 2 KM PRA BUSCAR, 10 KM PRA LEVAR
  double calculateDistanceKm(
      double lat1,
      double lon1,
      double lat2,
      double lon2,
      ) {
    const R = 6371; // raio da Terra em km

    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_degToRad(lat1)) *
                cos(_degToRad(lat2)) *
                sin(dLon / 2) *
                sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  Future<void> _publishDriverLocationForActiveRide(LatLng position) async {
    final rideId = _acceptedRideId;
    final driverId = _rideManager.userManager.user?.id;

    if (!_rideAccepted || rideId == null || driverId == null || driverId.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final lastPosition = _lastRideLocationSent;
    final lastSentAt = _lastRideLocationSentAt;
    final movedEnough = lastPosition == null ||
        Geolocator.distanceBetween(
              lastPosition.latitude,
              lastPosition.longitude,
              position.latitude,
              position.longitude,
            ) >=
            8;
    final waitedEnough = lastSentAt == null ||
        now.difference(lastSentAt) >= const Duration(seconds: 3);

    if (!movedEnough && !waitedEnough) return;

    // Ajuste Move: publica a posiï¿½ï¿½o atual do motorista na ride para o passageiro ver o carro se movendo no mapa.
    await _rideManager.updateDriverLocation(rideId, position, driverId);
    _lastRideLocationSent = position;
    _lastRideLocationSentAt = now;
  }


  void _maybeConfirmDestinationArrival(LatLng currentPosition) {
    if (_finishRideDialogShowing || !_rideStarted || _destinationLatLng == null) {
      return;
    }

    final distanceToDestinationMeters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      _destinationLatLng!.latitude,
      _destinationLatLng!.longitude,
    );

    if (distanceToDestinationMeters >
        _DriverNavigationScreenState._destinationArrivalToleranceMeters) {
      return;
    }

    _finishRideDialogShowing = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Finalizar corrida?'),
          content: Text(
            'Voce esta a ${distanceToDestinationMeters.round()} m do destino. '
            'Se a entrada correta e por esta rua, finalize a viagem e aguarde o pagamento.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _finishRideDialogShowing = false;
              },
              child: const Text('Ainda nao'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _finishRideDialogShowing = false;
                _finishRide();
              },
              child: const Text('Finalizar viagem'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      if (_rideStarted) _finishRideDialogShowing = false;
    });
  }
  void _startLocationTracking() {

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // atualiza a cada 5 metros
      ),
    ).listen((Position position) {
      if (!mounted) return;

      final currentPosition = LatLng(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _currentLatLng = currentPosition;
      });

      _publishDriverLocationForActiveRide(currentPosition);
      _maybeConfirmDestinationArrival(currentPosition);
      
      // Ajuste Move: usa distÃ¢ncia reta atÃ© o passageiro para liberar o diÃ¡logo de embarque com tolerÃ¢ncia.
      if (_rideAccepted &&
          !_rideStarted &&
          _pickupNavigationStarted &&
          _currentLatLng != null &&
          _pickupLatLng != null) {
        final straightDistanceMeters = Geolocator.distanceBetween(
          _currentLatLng!.latitude,
          _currentLatLng!.longitude,
          _pickupLatLng!.latitude,
          _pickupLatLng!.longitude,
        );

        if (straightDistanceMeters <=
            _DriverNavigationScreenState._pickupArrivalToleranceMeters) {
          _navigationSessionService.maybeShowStartRideDialog();
        }
      }
      print("ðŸ“ POSIÃ‡ÃƒO RECEBIDA: ${position.latitude}, ${position.longitude}");

      print("ðŸ“ LocalizaÃ§Ã£o atual: $_currentLatLng");
    });
  }
}
/////////////////



