// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:http/http.dart' as http;
import 'package:is_project_1/pages/user_pages/location_webservices.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

import 'package:is_project_1/components/custom_bootom_navbar.dart';
import 'package:is_project_1/services/api_service.dart';
import 'package:is_project_1/models/emergency_contact.dart'
    hide EmergencyContact;
import 'package:is_project_1/models/profile_response.dart';
import 'package:share_plus/share_plus.dart';

class MapPage extends StatefulWidget {
  final bool triggerPanic;

  const MapPage({Key? key, this.triggerPanic = false}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class PoliceLocation {
  final String name;
  final double latitude;
  final double longitude;
  final String contactNumber;

  PoliceLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.contactNumber,
  });

  factory PoliceLocation.fromJson(Map<String, dynamic> json) {
    return PoliceLocation(
      name: json['name'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      contactNumber: json['contact_number'],
    );
  }
}

class DangerZone {
  final String name;
  final double latitude;
  final double longitude;
  final String description;
  final double radius; // in meters

  DangerZone({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.radius,
  });

  factory DangerZone.fromJson(Map<String, dynamic> json) {
    return DangerZone(
      name: json['name'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      description: json['description'] ?? '',
      radius: json['radius']?.toDouble() ?? 500.0, // default 500m
    );
  }
}

class _MapPageState extends State<MapPage> with WidgetsBindingObserver {
  mp.MapboxMap? mapboxMapController;
  StreamSubscription? userPositionStream;
  StreamSubscription? accelerometerSubscription;
  bool isMapReady = false;
  bool isRealTimeTrackingEnabled = false;
  int currentActivityId = 1; // You can make this dynamic
  Timer? gpsLoggingTimer;
  Map<String, dynamic>? activeSharingSession;
  StreamSubscription? _locationUpdateSubscription;
  StreamSubscription? _connectionStatusSubscription;
  Map<String, dynamic>? _lastReceivedLocation;
  List<PoliceLocation> policeLocations = [];
  List<DangerZone> dangerZones = [];
  Set<String> notifiedDangerZones = {};

  static const String API_BASE_URL =
      'https://423c-197-136-185-70.ngrok-free.app';

  // Emergency features
  List<EmergencyContact> emergencyContacts = [];
  ProfileResponse? profile;
  bool isInPanicMode = false;
  int shakeCount = 0;
  DateTime? lastShakeTime;
  List<double> accelerometerValues = [];
  Timer? shakeResetTimer;
  gl.Position? currentPosition;

  // Shake detection parameters
  static const double shakeThreshold = 12.0;
  static const int shakeCountThreshold = 3;
  static const Duration shakeTimeWindow = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeMapbox();
    _setupPositionTracking();
    _loadEmergencyContacts();
    _setupShakeDetection();
    _initializeWebSocket();
    _loadMapData();
    _loadEmergencyContacts();
    if (widget.triggerPanic) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerPanicMode();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    userPositionStream?.cancel();
    accelerometerSubscription?.cancel();
    shakeResetTimer?.cancel();
    gpsLoggingTimer?.cancel();
    _locationUpdateSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    LocationWebSocketService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && isInPanicMode) {
      // App was brought to foreground while in panic mode
      _showPanicScreen();
    }
  }

  Future<void> _loadMapData() async {
    await Future.wait([_fetchPoliceLocations(), _fetchDangerZones()]);

    if (isMapReady) {
      _addMarkersToMap();
    }
  }

  Future<void> _fetchPoliceLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/police-locations'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          policeLocations = data
              .map((json) => PoliceLocation.fromJson(json))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching police locations: $e');
    }
  }

  Future<void> _fetchDangerZones() async {
    try {
      final response = await http.get(
        Uri.parse('$API_BASE_URL/danger-zones'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          dangerZones = data.map((json) => DangerZone.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error fetching danger zones: $e');
    }
  }

  void _toggleRealTimeTracking() async {
    setState(() {
      isRealTimeTrackingEnabled = !isRealTimeTrackingEnabled;
    });

    if (isRealTimeTrackingEnabled) {
      await _startRealTimeTracking();
    } else {
      await _stopRealTimeTracking();
    }
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final profileData = await ApiService.getProfile();
      List<EmergencyContact> contacts = [];

      if (profileData.roleId == 5) {
        try {
          contacts = await ApiService.getEmergencyContacts();
        } catch (e) {
          debugPrint('Failed to load emergency contacts: $e');
        }
      }

      setState(() {
        profile = profileData;
        emergencyContacts = contacts;
      });
    } catch (e) {
      debugPrint('Error loading profile/emergency contacts: $e');
    }
  }

  Future<void> _initializeWebSocket() async {
    try {
      final profileData = await ApiService.getProfile();
      // Get current user ID (you'll need to implement this)
      final userId = profileData.id; // Replace with actual user ID

      await LocationWebSocketService.instance.connect(userId as String);

      // Listen to location updates from other users
      _locationUpdateSubscription = LocationWebSocketService
          .instance
          .locationUpdates
          .listen((locationData) {
            _handleLocationUpdate(locationData);
          });

      // Listen to connection status
      _connectionStatusSubscription = LocationWebSocketService
          .instance
          .connectionStatus
          .listen((isConnected) {
            setState(() {
              // Update UI based on connection status
            });

            if (isConnected && isRealTimeTrackingEnabled) {
              // Resume real-time tracking if it was enabled
              _startRealTimeTracking();
            }
          });
    } catch (e) {
      debugPrint('Error initializing WebSocket: $e');
    }
  }

  void _handleLocationUpdate(Map<String, dynamic> locationData) {
    setState(() {
      _lastReceivedLocation = locationData;
    });

    // Update map with received location if it's from someone being tracked
    final data = locationData['data'];
    if (data != null && data['latitude'] != null && data['longitude'] != null) {
      // You can update the map to show the tracked user's location
      debugPrint(
        'Received location update: ${data['latitude']}, ${data['longitude']}',
      );
    }
  }

  // Enhanced real-time tracking with WebSocket
  Future<void> _startRealTimeTracking() async {
    try {
      // Start logging GPS data every 10 seconds
      gpsLoggingTimer = Timer.periodic(const Duration(seconds: 10), (
        timer,
      ) async {
        if (currentPosition != null) {
          try {
            await ApiService.logGPSLocationRealtime(
              latitude: currentPosition!.latitude,
              longitude: currentPosition!.longitude,
              activityId: currentActivityId,
            );
            debugPrint('GPS location logged successfully');
          } catch (e) {
            debugPrint('Failed to log GPS location: $e');
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Real-time tracking enabled'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting real-time tracking: $e');
    }
  }

  Future<void> _stopRealTimeTracking() async {
    gpsLoggingTimer?.cancel();
    gpsLoggingTimer = null;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Real-time tracking disabled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _updateUserLocationOnMap(gl.Position position) async {
    if (mapboxMapController == null) return;

    try {
      // Update camera to follow user
      await mapboxMapController!.setCamera(
        mp.CameraOptions(
          center: mp.Point(
            coordinates: mp.Position(position.longitude, position.latitude),
          ),
          zoom: 16.0,
        ),
      );

      // Add/update user location marker
      await mapboxMapController!.annotations
          .createPointAnnotationManager()
          .then((manager) async {
            final options = mp.PointAnnotationOptions(
              geometry: mp.Point(
                coordinates: mp.Position(position.longitude, position.latitude),
              ),
              iconImage: "user-location", // You'll need to add this image asset
              iconSize: 1.2,
            );

            await manager.create(options);
          });
    } catch (e) {
      print('Error updating user location: $e');
    }
  }

  // Enhanced location sharing with real-time tracking
  Future<void> _shareCurrentLocationRealTime() async {
    try {
      // Get contact numbers for sharing
      List<String> contactNumbers = emergencyContacts
          .map((contact) => contact.contactNumber)
          .toList();

      if (contactNumbers.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No emergency contacts available for real-time sharing',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show duration selection dialog
      int? selectedHours = await _showDurationSelectionDialog();
      if (selectedHours == null) return;

      // Start location sharing session
      final sharingResult = await ApiService.startLocationSharing(
        activityId: currentActivityId,
        contacts: contactNumbers,
        durationHours: selectedHours,
      );

      setState(() {
        activeSharingSession = sharingResult;
        isRealTimeTrackingEnabled = true;
      });

      // Start real-time tracking
      await _startRealTimeTracking();

      // Send initial notification to contacts
      await _sendLocationSharingNotification(sharingResult['share_url']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Real-time location sharing started for $selectedHours hours',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error starting real-time location sharing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start real-time sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<int?> _showDurationSelectionDialog() async {
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Duration'),
        content: const Text('How long would you like to share your location?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 1),
            child: const Text('1 Hour'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 4),
            child: const Text('4 Hours'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 24),
            child: const Text('24 Hours'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendLocationSharingNotification(String shareUrl) async {
    try {
      final String message =
          '''
📍 Real-time Location Sharing

${profile?.name ?? 'Someone'} is sharing their live location with you.

Track their location here: $shareUrl

This link will be active for the selected duration.

Sent at: ${DateTime.now().toString()}
''';

      for (final contact in emergencyContacts) {
        try {
          await ApiService.sendLocationSMS(
            phoneNumber: contact.contactNumber,
            message: message,
          );
        } catch (e) {
          debugPrint(
            'Failed to send sharing notification to ${contact.contactName}: $e',
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending location sharing notifications: $e');
    }
  }

  Future<void> _stopLocationSharing() async {
    setState(() {
      activeSharingSession = null;
      isRealTimeTrackingEnabled = false;
    });

    await _stopRealTimeTracking();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location sharing stopped'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _setupShakeDetection() {
    accelerometerSubscription = accelerometerEvents.listen((event) {
      double gForce = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

      if (gForce > shakeThreshold) {
        DateTime now = DateTime.now();

        if (lastShakeTime == null ||
            now.difference(lastShakeTime!) < shakeTimeWindow) {
          shakeCount++;
          lastShakeTime = now;

          if (shakeCount >= shakeCountThreshold) {
            _triggerPanicMode();
            shakeCount = 0; // Reset after triggering
          }

          // Reset shake count after time window
          shakeResetTimer?.cancel();
          shakeResetTimer = Timer(shakeTimeWindow, () {
            shakeCount = 0;
          });
        } else {
          shakeCount = 1;
          lastShakeTime = now;
        }
      }
    });
  }

  Future<void> _triggerPanicMode() async {
    if (isInPanicMode) return; // Prevent multiple triggers

    setState(() {
      isInPanicMode = true;
    });

    // Vibrate the phone
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 1000, 500, 1000], repeat: 1);
    }

    // Show panic screen
    _showPanicScreen();
  }

  void _showPanicScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: PanicScreen(
            onSendDistress: _sendDistressSignal,
            onCancel: _cancelPanicMode,
          ),
        );
      },
    );
  }

  Future<void> _sendDistressSignal() async {
    try {
      // Get current location if not available
      currentPosition ??= await gl.Geolocator.getCurrentPosition();

      final latitude = currentPosition!.latitude;
      final longitude = currentPosition!.longitude;
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

      // Send to emergency contacts via Africa's Talking
      await _sendEmergencyMessages(googleMapsUrl, latitude, longitude);

      _cancelPanicMode();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Distress signal sent to emergency contacts'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending distress signal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send distress signal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendEmergencyMessages(
    String mapUrl,
    double lat,
    double lng,
  ) async {
    if (emergencyContacts.isEmpty) {
      throw Exception('No emergency contacts available');
    }

    final String message =
        '''
🚨 EMERGENCY ALERT 🚨

${profile?.name ?? 'Someone'} has triggered an emergency alert!

Location: $lat, $lng
Map: $mapUrl

Time: ${DateTime.now().toString()}

Please check on them immediately!
''';

    // Send SMS to each emergency contact
    for (final contact in emergencyContacts) {
      try {
        await ApiService.sendEmergencySMS(
          phoneNumber: contact.contactNumber,
          message: message,
        );
        debugPrint('Emergency SMS sent to ${contact.contactName}');
      } catch (e) {
        debugPrint('Failed to send SMS to ${contact.contactName}: $e');
      }
    }
  }

  void _cancelPanicMode() {
    setState(() {
      isInPanicMode = false;
    });

    // Stop vibration
    Vibration.cancel();

    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _initializeMapbox() async {
    try {
      final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
      if (token == null || token.isEmpty) {
        debugPrint('Error: MAPBOX_ACCESS_TOKEN not found in .env file');
        return;
      }

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
              center: mp.Point(coordinates: mp.Position(0, 0)),
              zoom: 10.0,
            ),
          ),
          if (!isMapReady) const Center(child: CircularProgressIndicator()),

          // Connection status indicator
          Positioned(
            top: 120,
            left: 16,
            child: _buildConnectionStatusIndicator(),
          ),

          // Panic Button
          Positioned(top: 60, right: 16, child: _buildPanicButton()),

          // Real-time tracking toggle
          Positioned(top: 60, left: 16, child: _buildRealTimeTrackingButton()),

          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: _buildEnhancedShareLocationCard(),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 2),
    );
  }

  Widget _buildRealTimeTrackingButton() {
    return GestureDetector(
      onTap: _toggleRealTimeTracking,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRealTimeTrackingEnabled ? Colors.green : Colors.grey,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: (isRealTimeTrackingEnabled ? Colors.green : Colors.grey)
                  .withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRealTimeTrackingEnabled ? Icons.gps_fixed : Icons.gps_off,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isRealTimeTrackingEnabled ? 'Live' : 'Offline',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanicButton() {
    return GestureDetector(
      onTap: _triggerPanicMode,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              spreadRadius: 3,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.warning, color: Colors.white, size: 30),
      ),
    );
  }

  void _onMapCreated(mp.MapboxMap controller) async {
    debugPrint('Map created successfully');
    setState(() {
      mapboxMapController = controller;
      isMapReady = true;
    });
    _addMarkersToMap();
    _getCurrentLocation();

    try {
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

  Future<void> _addMarkersToMap() async {
    if (mapboxMapController == null) return;

    // Create ONE annotation manager for all markers
    final annotationManager = await mapboxMapController!.annotations
        .createPointAnnotationManager();

    print('Adding ${policeLocations.length} police locations');
    print('Adding ${dangerZones.length} danger zones');

    // Add police markers
    for (final police in policeLocations) {
      await _addPoliceMarkerWithManager(annotationManager, police);
    }

    // Add danger zone markers
    for (final danger in dangerZones) {
      await _addDangerZoneMarkerWithManager(annotationManager, danger);
    }
  }

  Future<void> _addPoliceMarkerWithManager(
    manager,
    PoliceLocation police,
  ) async {
    try {
      final options = mp.PointAnnotationOptions(
        geometry: mp.Point(
          coordinates: mp.Position(police.longitude, police.latitude),
        ),
        iconImage: "assets/images/police_marker.png", // Fixed quote
        iconSize: 1.0,
        textField: police.name,
        textOffset: [0.0, -2.0],
        textColor: Colors.green.value,
        textSize: 12.0,
      );

      await manager.create(options);
      print('Police marker added: ${police.name}');
    } catch (e) {
      print('Error adding police marker: $e');
    }
  }

  Future<void> _addDangerZoneMarkerWithManager(
    // ignore: strict_top_level_inference
    manager,
    DangerZone danger,
  ) async {
    try {
      final options = mp.PointAnnotationOptions(
        geometry: mp.Point(
          coordinates: mp.Position(danger.longitude, danger.latitude),
        ),
        iconImage: "assets/images/danger_marker.png", // Fixed quote
        iconSize: 1.0,
        textField: danger.name,
        textOffset: [0.0, -2.0],
        textColor: Colors.red.value,
        textSize: 12.0,
      );

      await manager.create(options);
      print('Danger marker added: ${danger.name}');
    } catch (e) {
      print('Error adding danger marker: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      gl.LocationPermission permission = await gl.Geolocator.checkPermission();
      if (permission == gl.LocationPermission.denied) {
        permission = await gl.Geolocator.requestPermission();
        if (permission == gl.LocationPermission.denied) return;
      }

      currentPosition = await gl.Geolocator.getCurrentPosition();
      if (currentPosition != null && mapboxMapController != null) {
        await mapboxMapController!.setCamera(
          mp.CameraOptions(
            center: mp.Point(
              coordinates: mp.Position(
                currentPosition!.longitude,
                currentPosition!.latitude,
              ),
            ),
            zoom: 14.0,
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _setupPositionTracking() async {
    try {
      bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return;
      }

      gl.LocationPermission permission = await gl.Geolocator.checkPermission();
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
        distanceFilter: 10,
      );

      userPositionStream?.cancel();
      userPositionStream =
          gl.Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (gl.Position position) {
              currentPosition = position;
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
      final position =
          currentPosition ?? await gl.Geolocator.getCurrentPosition();
      final latitude = position.latitude;
      final longitude = position.longitude;
      final googleMapsUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

      // Option 1: Regular share
      await Share.share('Here is my current location: $googleMapsUrl');

      // Option 2: Send to emergency contacts if available
      if (emergencyContacts.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share Location'),
            content: const Text(
              'Would you like to also send your location to your emergency contacts?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('No, thanks'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _sendLocationToEmergencyContacts(
                    googleMapsUrl,
                    latitude,
                    longitude,
                  );
                },
                child: const Text('Yes, send'),
              ),
            ],
          ),
        );
      }

      debugPrint('Location shared successfully');
    } catch (e) {
      debugPrint('Error sharing location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share location. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _sendLocationToEmergencyContacts(
    String mapUrl,
    double lat,
    double lng,
  ) async {
    try {
      final String message =
          '''
📍 Location Share from ${profile?.name ?? 'Contact'}

I'm sharing my current location with you:
$mapUrl

Latitude: $lat
Longitude: $lng

Sent at: ${DateTime.now().toString()}
''';

      for (final contact in emergencyContacts) {
        try {
          await ApiService.sendLocationSMS(
            phoneNumber: contact.contactNumber,
            message: message,
          );
        } catch (e) {
          debugPrint('Failed to send location to ${contact.contactName}: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location sent to emergency contacts'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending location to emergency contacts: $e');
    }
  }

  Widget _buildEnhancedShareLocationCard() {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activeSharingSession != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radio_button_checked, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Location sharing active',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _stopLocationSharing,
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Police: ${policeLocations.length} nearby',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'Danger zones: ${dangerZones.length}',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Share Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activeSharingSession != null
                          ? 'Real-time sharing active'
                          : 'Share current or real-time location',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton(
                onSelected: (value) {
                  if (value == 'current') {
                    _shareCurrentLocation();
                  } else if (value == 'realtime') {
                    _shareCurrentLocationRealTime();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'current',
                    child: Text('Current Location'),
                  ),
                  const PopupMenuItem(
                    value: 'realtime',
                    child: Text('Real-time Tracking'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Share',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: LocationWebSocketService.instance.isConnected
            ? Colors.green
            : Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LocationWebSocketService.instance.isConnected
                ? Icons.wifi
                : Icons.wifi_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            LocationWebSocketService.instance.isConnected
                ? 'Connected'
                : 'Offline',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  emergencyContacts.isNotEmpty
                      ? 'Send to contacts or emergency contacts'
                      : 'Send your location to trusted contacts',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
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

class PanicScreen extends StatefulWidget {
  final VoidCallback onSendDistress;
  final VoidCallback onCancel;

  const PanicScreen({
    super.key,
    required this.onSendDistress,
    required this.onCancel,
  });

  @override
  State<PanicScreen> createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  int tapCount = 0;
  Timer? tapTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _pulseController.repeat(reverse: true);

    // Auto-cancel after 30 seconds if no action
    Timer(const Duration(seconds: 30), () {
      if (mounted) {
        widget.onCancel();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    tapTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      tapCount++;
    });

    if (tapCount == 1) {
      // First tap - show accidental message and start timer
      tapTimer = Timer(const Duration(seconds: 3), () {
        if (tapCount == 1) {
          // Only one tap in 3 seconds - treat as accidental
          widget.onCancel();
        }
      });
    } else if (tapCount >= 2) {
      // Two or more taps - send distress signal
      tapTimer?.cancel();
      widget.onSendDistress();
    }

    // Shake animation on tap
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.red,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: const Icon(
                            Icons.warning,
                            size: 100,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'EMERGENCY MODE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    if (tapCount == 0) ...[
                      const Text(
                        'Tap TWICE to send distress signal\nTap ONCE if accidental',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ] else if (tapCount == 1) ...[
                      const Text(
                        'Tap AGAIN to confirm distress signal\nOr wait 3 seconds to cancel',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 60),
                    GestureDetector(
                      onTap: _handleTap,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Center(
                          child: Text(
                            tapCount == 0 ? 'TAP HERE' : 'TAP AGAIN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (tapCount == 0)
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
