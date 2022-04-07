import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutterpolyline/google_mapapi.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class LocationTracking extends StatefulWidget {
  const LocationTracking({Key? key}) : super(key: key);

  @override
  _LocationTrackingState createState() => _LocationTrackingState();
}

class _LocationTrackingState extends State<LocationTracking> {
  LatLng sourceLocation = const LatLng(33.667538, 73.057643);
  LatLng destinationLatlng = const LatLng(33.667282, 73.059312);
  bool isLoading = false;
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _marker = Set<Marker>();
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polyCoordinates = [];
  late PolylinePoints polylinePoints;
  late StreamSubscription subscription;

  LocationData? currentLocation;
  LocationData? destinationLocation;
  late Location location;

  @override
  void initState() {
    super.initState();
    location = Location();
    polylinePoints = PolylinePoints();
    subscription = location.onLocationChanged.listen((userLocation) {
      currentLocation = userLocation;
    });
    setInitialLocation();
  }

  void setInitialLocation() async {
    currentLocation = await location.getLocation();
    destinationLocation = LocationData.fromMap({
      "latitude": destinationLocation!.altitude,
      "longitude": destinationLatlng.longitude
    });
  }

  void showLocationPins() {
    var sourcePosition = LatLng(
        currentLocation!.latitude ?? 0.0, currentLocation!.longitude ?? 0.0);
    var destinationPosition =
        LatLng(destinationLatlng.latitude, destinationLatlng.longitude);
    _marker.add(Marker(
        markerId: const MarkerId('sourcePosition'), position: sourcePosition));
    _marker.add(Marker(
        markerId: const MarkerId('destinationPosition'),
        position: destinationPosition));

    setPolylinesInMap();
  }

  void setPolylinesInMap() async {
    var result = await polylinePoints.getRouteBetweenCoordinates(
        GoogleMapApi().url,
        PointLatLng(currentLocation!.latitude ?? 0.0,
            currentLocation!.longitude ?? 0.0),
        PointLatLng(destinationLatlng.latitude, destinationLatlng.longitude));

    if (result.points.isNotEmpty) {
      result.points.forEach((pointLatLng) {
        polyCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    setState(() {
      _polylines.add(Polyline(
          width: 5,
          polylineId: const PolylineId('polyline'),
          color: Colors.blueAccent,
          points: polyCoordinates));
    });
  }

  void updatePinOnShop() async {
    CameraPosition cameraPosition = CameraPosition(
        zoom: 20,
        tilt: 80,
        bearing: 30,
        target: LatLng(currentLocation!.latitude ?? 0.0,
            currentLocation!.longitude ?? 0.0));

    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
    var sourcePosition = LatLng(
        currentLocation!.latitude ?? 0.0, currentLocation!.longitude ?? 0.0);
    setState(() {
      _marker.removeWhere((marker) => marker.mapsId.value == 'sourcePosition');
      _marker.add(Marker(
        markerId: const MarkerId('sourcePosition'),
        position: sourcePosition,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition initialCameraPosition = CameraPosition(
        zoom: 20,
        tilt: 80,
        bearing: 30,
        target: LatLng(currentLocation!.latitude ?? 0.0,
            currentLocation!.longitude ?? 0.0));
    return SafeArea(
        child: Scaffold(
            appBar: AppBar(
              title: const Text('polyline'),
            ),
            body: GoogleMap(
              markers: _marker,
              polylines: _polylines,
              mapType: MapType.normal,
              initialCameraPosition: initialCameraPosition,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                showLocationPins();
              },
            )));
  }
}
