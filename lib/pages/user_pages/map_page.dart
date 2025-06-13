// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;

import 'package:is_project_1/components/custom_bootom_navbar.dart';
import 'package:share_plus/share_plus.dart';

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  mp.MapboxMap? mapboxMapController;
  StreamSubscription? userPositionStream;
  bool isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initializeMapbox();
    _setupPositionTracking();
  }

  @override
  void dispose() {
    userPositionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeMapbox() async {
    try {
      // Make sure the access token is set
      final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
      if (token == null || token.isEmpty) {
        debugPrint('Error: MAPBOX_ACCESS_TOKEN not found in .env file');
        return;
      }

      // Set the access token
      mp.MapboxOptions.setAccessToken(token);
      debugPrint('Mapbox token initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Mapbox: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          mp.MapWidget(
            key: const ValueKey("mapWidget"),
            onMapCreated: _onMapCreated,
            styleUri: mp.MapboxStyles.DARK,
            cameraOptions: mp.CameraOptions(
              center: mp.Point(
                coordinates: mp.Position(0, 0),
              ), // Default center
              zoom: 10.0,
            ),
          ),
          if (!isMapReady) const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: _buildShareLocationCard(),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 2),
    );
  }

  void _onMapCreated(mp.MapboxMap controller) async {
    debugPrint('Map created successfully');
    setState(() {
      mapboxMapController = controller;
      isMapReady = true;
    });

    try {
      // Enable location component
      await mapboxMapController?.location.updateSettings(
        mp.LocationComponentSettings(
          enabled: true,
          pulsingEnabled: true,
          showAccuracyRing: true,
        ),
      );
      debugPrint('Location component enabled');
    } catch (e) {
      debugPrint('Error enabling location component: $e');
    }
  }

  Future<void> _setupPositionTracking() async {
    try {
      bool serviceEnabled;
      gl.LocationPermission permission;

      serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return;
      }

      permission = await gl.Geolocator.checkPermission();
      if (permission == gl.LocationPermission.denied) {
        permission = await gl.Geolocator.requestPermission();
        if (permission == gl.LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == gl.LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      gl.LocationSettings locationSettings = const gl.LocationSettings(
        accuracy: gl.LocationAccuracy.high,
        distanceFilter: 10, // Reduced for more frequent updates
      );

      userPositionStream?.cancel();
      userPositionStream =
          gl.Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (gl.Position position) {
              debugPrint(
                'Position updated: ${position.latitude}, ${position.longitude}',
              );

              if (mapboxMapController != null && isMapReady) {
                mapboxMapController?.setCamera(
                  mp.CameraOptions(
                    zoom: 15.0,
                    center: mp.Point(
                      coordinates: mp.Position(
                        position.longitude,
                        position.latitude,
                      ),
                    ),
                  ),
                );
              }
            },
            onError: (error) {
              debugPrint('Error getting position: $error');
            },
          );

      debugPrint('Position tracking setup completed');
    } catch (e) {
      debugPrint('Error setting up position tracking: $e');
    }
  }

  Future<void> _shareCurrentLocation() async {
    try {
      final position = await gl.Geolocator.getCurrentPosition();

      final latitude = position.latitude;
      final longitude = position.longitude;

      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

      await Share.share('Here is my current location: $googleMapsUrl');

      debugPrint('Location shared successfully');
    } catch (e) {
      debugPrint('Error sharing location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share location. Please try again.')),
      );
    }
  }

  Widget _buildShareLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.location_on, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Send your location to trusted contacts',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _shareCurrentLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Share',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
