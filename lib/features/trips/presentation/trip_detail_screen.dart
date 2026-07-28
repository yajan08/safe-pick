import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:safe_pick/core/services/mqtt_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/safe_pick_dialog.dart';

import '../data/trip_model.dart';
import '../domain/trip_service.dart';
import '../data/trip_manifest_model.dart';
import '../data/daily_session_model.dart';
import 'qr_scanner_screen.dart';
import '../../auth/domain/auth_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'utils/marker_generator.dart';
import '../../admin/data/school_service.dart';
import '../../admin/data/school_model.dart';

/// Future provider to fetch details of a specific trip.
final tripDetailsProvider = FutureProvider.family<TripModel, String>((ref, tripId) async {
  final firestore = ref.watch(firestoreProvider);
  final doc = await firestore.collection('trips').doc(tripId).get();
  if (!doc.exists) {
    throw 'Trip not found';
  }
  return TripModel.fromJson(doc.data()!, doc.id);
});

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  bool _isLoading = false;

  final MqttService _mqttService = MqttService();
  StreamSubscription<Position>? _positionStream;
  bool _isLiveTracking = false;

  Timer? _publishTimer;
  Position? _currentPosition;

  // ─── GEOFENCING STATE ──────────────────────────────
  String? _approachingStudentId;
  String? _approachingStudentName;
  String? _approachingStatusAction;
  String? _approachingNextStatus;
  final Set<String> _approachingNotifiedStudents = {};
  final Set<String> _arrivedNotifiedStudents = {};

  // ─── MAP STATE & MARKER CACHE ────────────────────────
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  BitmapDescriptor? _driverVanMarker;
  final Map<String, BitmapDescriptor> _studentMarkerCache = {};
  final Map<String, String> _studentStatusCache = {};

  final Map<String, BitmapDescriptor> _schoolMarkerCache = {};
  List<SchoolModel> _currentSchools = [];

  // ─── NETWORK & GPS STATE ────────────────────────────
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  StreamSubscription<ServiceStatus>? _serviceStatusSub;
  bool _isOffline = false;
  bool _isLocationDisabled = false;

  @override
  void initState() {
    super.initState();
    _initDriverMarker();
    _fetchInitialLocation();
    
    _connectivitySub = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (mounted) {
        setState(() {
          _isOffline = results.contains(ConnectivityResult.none);
        });
      }
    });

    _serviceStatusSub = Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (mounted) {
        setState(() {
          _isLocationDisabled = status == ServiceStatus.disabled;
        });
      }
    });
  }

  @override
  void dispose() {
    _publishTimer?.cancel();
    _positionStream?.cancel();
    _connectivitySub?.cancel();
    _serviceStatusSub?.cancel();
    _mqttService.disconnect();
    _stopLiveTracking(); 
    super.dispose();
  }

  Future<void> _fetchInitialLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          final manifestAsync = ref.read(tripManifestProvider(widget.tripId));
          if (manifestAsync.hasValue) {
            _buildMarkers(manifestAsync.value!);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching initial GPS location: $e");
    }
  }

  Future<void> _initDriverMarker() async {
    _driverVanMarker = await MarkerGenerator.createDriverVanMarker();
  }

  Future<void> _updateStudentMarkers(List<TripManifestModel> manifest, Map<String, String> attendanceMap, String tripType) async {
    bool changed = false;
    
    for (var student in manifest) {
      if (student.homeLocation == null) continue;
      final currentStatus = attendanceMap[student.studentId] ?? student.status;
      
      if (_studentStatusCache[student.studentId] != currentStatus || !_studentMarkerCache.containsKey(student.studentId)) {
        final color = MarkerGenerator.getStatusColor(currentStatus, tripType);
        final markerIcon = await MarkerGenerator.createStudentMarker(student.name, color);
        _studentMarkerCache[student.studentId] = markerIcon;
        _studentStatusCache[student.studentId] = currentStatus;
        changed = true;
      }
    }
    
    if (changed || _currentPosition != null) {
      _buildMarkers(manifest);
    }
  }

  Future<void> _updateSchoolMarkers(List<SchoolModel> schools, List<TripManifestModel> manifest) async {
    bool changed = false;
    _currentSchools = schools;
    for (var school in schools) {
      if (!_schoolMarkerCache.containsKey(school.schoolId)) {
        final markerIcon = await MarkerGenerator.createSchoolMarker(school.name);
        _schoolMarkerCache[school.schoolId] = markerIcon;
        changed = true;
      }
    }
    if (changed || _currentPosition != null) {
      _buildMarkers(manifest);
    }
  }

  void _buildMarkers(List<TripManifestModel> manifest) {
    final Set<Marker> newMarkers = {};
    if (_currentPosition != null && _driverVanMarker != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('driver_van'),
        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        icon: _driverVanMarker!,
        zIndexInt: 100,
        anchor: const Offset(0.5, 0.5),
      ));
    }
    
    for (var student in manifest) {
      if (student.homeLocation == null) continue;
      if (_studentMarkerCache.containsKey(student.studentId)) {
        newMarkers.add(Marker(
          markerId: MarkerId('student_${student.studentId}'),
          position: LatLng(student.homeLocation!.latitude, student.homeLocation!.longitude),
          icon: _studentMarkerCache[student.studentId]!,
        ));
      }
    }
    
    for (var school in _currentSchools) {
      if (_schoolMarkerCache.containsKey(school.schoolId)) {
        newMarkers.add(Marker(
          markerId: MarkerId('school_${school.schoolId}'),
          position: LatLng(school.location.latitude, school.location.longitude),
          icon: _schoolMarkerCache[school.schoolId]!,
          zIndexInt: 50,
        ));
      }
    }
    
    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  // ─── LIVE TRACKING ENGINE ────────────────────────────
  
  void _checkGeofences(Position currentPos, List<TripManifestModel> manifest, String sessionId, String tripType, List<SchoolModel> schools) {
    // 1. Process Geofence Push Notifications (Independent of driver's active screen banner)
    for (var student in manifest) {
      if (student.homeLocation == null) continue;

      final attendanceMap = ref.read(sessionAttendanceProvider(sessionId)).value ?? {};
      final currentStatus = attendanceMap[student.studentId] ?? student.status;

      bool isActiveTarget = false;
      if (tripType.toLowerCase() == 'morning') {
        if (currentStatus.toLowerCase() == 'at home') {
          isActiveTarget = true;
        }
      } else {
        if (currentStatus.toLowerCase() == 'in van') {
          isActiveTarget = true;
        }
      }

      if (!isActiveTarget) continue;

      final distance = Geolocator.distanceBetween(
        currentPos.latitude, currentPos.longitude,
        student.homeLocation!.latitude, student.homeLocation!.longitude,
      );

      // Check 500m geofence for "approaching" notification
      if (distance <= 500.0 && !_approachingNotifiedStudents.contains(student.studentId)) {
        _approachingNotifiedStudents.add(student.studentId);
        ref.read(tripServiceProvider).updateGeofenceNotificationStatus(
          sessionId,
          student.studentId,
          approachingNotified: true,
        );
      }

      // Check 50m geofence for "arrived" notification
      if (distance <= 50.0 && !_arrivedNotifiedStudents.contains(student.studentId)) {
        _arrivedNotifiedStudents.add(student.studentId);
        ref.read(tripServiceProvider).updateGeofenceNotificationStatus(
          sessionId,
          student.studentId,
          arrivedNotified: true,
        );
      }
    }

    // 2. Process Driver UI Banner (Only one active at a time)
    if (_approachingStudentId != null) return; 

    final isMorning = tripType.toLowerCase() == 'morning';
    
    if (isMorning) {
      for (var school in schools) {
        final distance = Geolocator.distanceBetween(
          currentPos.latitude, currentPos.longitude,
          school.location.latitude, school.location.longitude,
        );

        if (distance <= 50.0) {
          if (mounted) {
            setState(() {
              _approachingStudentId = 'SCHOOL_${school.schoolId}';
              _approachingStudentName = school.name;
              _approachingStatusAction = 'DROP OFF ALL STUDENTS IN VAN';
              _approachingNextStatus = 'DROP_ALL';
            });
          }
          return;
        }
      }
    }

    for (var student in manifest) {
      if (student.homeLocation == null) continue;
      
      final attendanceMap = ref.read(sessionAttendanceProvider(sessionId)).value ?? {};
      final currentStatus = attendanceMap[student.studentId] ?? student.status;
      
      bool isActiveTarget = false;
      String nextStatus = '';
      String actionLabel = '';

      if (tripType.toLowerCase() == 'morning') {
        if (currentStatus.toLowerCase() == 'at home') {
          isActiveTarget = true;
          nextStatus = 'In Van';
          actionLabel = 'MARK AS PICKED UP';
        }
      } else {
        if (currentStatus.toLowerCase() == 'in van') {
          isActiveTarget = true;
          nextStatus = 'At Home';
          actionLabel = 'MARK AS DROPPED OFF';
        }
      }
      
      if (!isActiveTarget) continue;

      final distance = Geolocator.distanceBetween(
        currentPos.latitude, currentPos.longitude,
        student.homeLocation!.latitude, student.homeLocation!.longitude,
      );

      if (distance <= 50.0) {
        if (mounted) {
          setState(() {
            _approachingStudentId = student.studentId;
            _approachingStudentName = student.name.split(' ').first;
            _approachingStatusAction = actionLabel;
            _approachingNextStatus = nextStatus;
          });
        }
        break; 
      }
    }
  }
  
  Future<void> _startLiveTracking(String sessionId) async {
    if (_isLiveTracking) return;

    _approachingNotifiedStudents.clear();
    _arrivedNotifiedStudents.clear();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final connected = await _mqttService.connect('driver_${widget.tripId}');
    if (!connected) return;

    setState(() => _isLiveTracking = true);

    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 3),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "SafePick Live Tracking Active",
          notificationTitle: "Running in background",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _currentPosition = position; 
      if (_isLiveTracking && _mapController != null) {
         _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
      }
      final manifestAsync = ref.read(tripManifestProvider(widget.tripId));
      if (manifestAsync.hasValue) {
        _buildMarkers(manifestAsync.value!);
        
        final sessionAsync = ref.read(activeSessionProvider(widget.tripId));
        final tripAsync = ref.read(tripDetailsProvider(widget.tripId));
        if (sessionAsync.hasValue && tripAsync.hasValue && sessionAsync.value != null) {
          _checkGeofences(position, manifestAsync.value!, sessionAsync.value!.sessionId, tripAsync.value!.tripType, _currentSchools);
        }
      }
    });

    _publishTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPosition != null && _isLiveTracking) {
        _mqttService.publishLocation(
          sessionId,
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          _currentPosition!.speed,
        );
      }
    });
  }

  void _stopLiveTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    
    _publishTimer?.cancel();
    _publishTimer = null;
    _currentPosition = null;

    _mqttService.disconnect();
    _isLiveTracking = false;
  }

  Future<void> _handleStartTrip() async {
    final selectedVehicle = await _selectVehicle();
    if (selectedVehicle == null) return; // User cancelled

    setState(() => _isLoading = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.startDailySession(widget.tripId, selectedVehicle: selectedVehicle);
      ref.invalidate(tripDetailsProvider(widget.tripId));
      
      try {
        final newSession = await ref.read(activeSessionProvider(widget.tripId).future);
        if (newSession != null) {
          await _startLiveTracking(newSession.sessionId);
        }
      } catch (e) {
        debugPrint('Tracking init delayed: $e');
      }
    } catch (e) {
      debugPrint('Error starting trip: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _selectVehicle() async {
    final firestore = ref.read(firestoreProvider);
    final auth = ref.read(firebaseAuthProvider);
    final uid = auth.currentUser?.uid;
    if (uid == null) return ''; // fallback

    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) return '';

    final data = doc.data()!;
    final primaryVehicle = data['vehicle_number'] as String?;
    final rawVehicles = data['vehicle_numbers'];
    
    List<String> vehicles = [];
    if (primaryVehicle != null && primaryVehicle.trim().isNotEmpty) {
      vehicles.add(primaryVehicle.trim());
    }
    if (rawVehicles is List) {
      for (var v in rawVehicles) {
        final str = v.toString().trim();
        if (str.isNotEmpty && !vehicles.contains(str)) {
          vehicles.add(str);
        }
      }
    }

    if (vehicles.isEmpty) return '';
    if (vehicles.length == 1) return vehicles.first;

    // Show dialog
    return await showDialog<String>(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SafePickDialog(
          title: 'Select Vehicle',
          secondaryActionLabel: 'Cancel',
          onSecondaryAction: () => Navigator.of(context).pop(),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: vehicles.length,
              separatorBuilder: (_,_) => Divider(color: AppTheme.border.withValues(alpha: 0.5)),
              itemBuilder: (context, index) {
                final v = vehicles[index];
                final isPrimary = v == primaryVehicle;
                return ListTile(
                  onTap: () => Navigator.of(context).pop(v),
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primaryGold.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.directions_car_rounded, color: AppTheme.primaryGold),
                  ),
                  title: Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textPrimary)),
                  subtitle: isPrimary ? const Text('Primary Vehicle', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.w700, fontSize: 13)) : null,
                );
              },
            ),
          ),
        );
      }
    );
  }

  Future<void> _handleEndTrip(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => SafePickDialog(
        title: 'End Trip',
        description: 'Are you sure you want to end this trip? You will stop tracking.',
        isDestructive: true,
        primaryActionLabel: 'End Trip',
        onPrimaryAction: () => Navigator.of(context).pop(true),
        secondaryActionLabel: 'Cancel',
        onSecondaryAction: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirm != true) return;

    _stopLiveTracking();

    setState(() => _isLoading = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.endDailySession(sessionId, widget.tripId);
      ref.invalidate(tripDetailsProvider(widget.tripId));
    } catch (e) {
      debugPrint('Error ending trip: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReopenTrip(String sessionId) async {
    final selectedVehicle = await _selectVehicle();
    if (selectedVehicle == null) return; // User cancelled

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => SafePickDialog(
        title: 'Reopen Trip',
        description: 'Are you sure you want to reopen this trip? This will set it back to In Progress and resume tracking.',
        primaryActionLabel: 'Reopen',
        onPrimaryAction: () => Navigator.of(context).pop(true),
        secondaryActionLabel: 'Cancel',
        onSecondaryAction: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.reopenDailySession(sessionId, widget.tripId, selectedVehicle: selectedVehicle);
      ref.invalidate(tripDetailsProvider(widget.tripId));

      try {
        await _startLiveTracking(sessionId);
      } catch (e) {
        debugPrint('Tracking resume delayed: $e');
      }
    } catch (e) {
      debugPrint('Error reopening trip: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEditTrip(TripModel trip) async {
    final manifestAsync = ref.read(tripManifestProvider(trip.tripId));
    final initialRoster = manifestAsync.value?.map((s) => {
      'id': s.studentId,
      'name': s.name,
      'school_name': s.schoolName,
    }).toList() ?? [];

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => _EditTripScreen(
          trip: trip,
          initialRoster: initialRoster,
        ),
      ),
    );

    if (result != null) {
      setState(() => _isLoading = true);
      try {
        final newName = result['name'] as String;
        final newType = result['type'] as String;
        final newStudentIds = (result['roster'] as List<dynamic>).cast<String>();
        
        await ref.read(tripServiceProvider).updateTrip(trip.tripId, newName, newStudentIds);
        await ref.read(firestoreProvider).collection('trips').doc(trip.tripId).update({'trip_type': newType});
        
        ref.invalidate(tripDetailsProvider(widget.tripId));
        ref.invalidate(tripManifestProvider(widget.tripId));
      } catch (e) {
        debugPrint('Error updating trip: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _isStudentParentSuspended(String studentId) async {
    try {
      final firestore = ref.read(firestoreProvider);
      final studentDoc = await firestore.collection('students').doc(studentId).get();
      if (!studentDoc.exists) return false;
      
      final parentUid = studentDoc.data()?['parent_uid'] as String?;
      if (parentUid == null) return false;
      
      final parentDoc = await firestore.collection('users').doc(parentUid).get();
      if (!parentDoc.exists) return false;
      
      final parentStatus = parentDoc.data()?['status'] as String?;
      if (parentStatus == 'suspended' || parentStatus == 'inactive') {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error checking parent status: $e");
      return false;
    }
  }

  Future<void> _handleScannedStudent(String studentId, String sessionId) async {
    final isSuspended = await _isStudentParentSuspended(studentId);
    if (isSuspended) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => SafePickDialog(
            title: 'Access Revoked',
            description: 'Payment not done. Student access is revoked.',
            isDestructive: true,
            primaryActionLabel: 'DISMISS',
            onPrimaryAction: () => Navigator.of(context).pop(),
          ),
        );
      }
      return;
    }

    final manifestAsync = ref.read(tripManifestProvider(widget.tripId));
    if (!manifestAsync.hasValue) return;

    final manifest = manifestAsync.value!;
    final manifestStudent = manifest.where((s) => s.studentId == studentId).firstOrNull;

    if (manifestStudent == null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => SafePickDialog(
            title: 'Invalid Student',
            description: 'Student ID $studentId is NOT assigned to this route.',
            isDestructive: true,
            primaryActionLabel: 'DISMISS',
            onPrimaryAction: () => Navigator.of(context).pop(),
          ),
        );
      }
      return;
    }

    final tripAsync = ref.read(tripDetailsProvider(widget.tripId));
    if (!tripAsync.hasValue) return;
    final trip = tripAsync.value!;

    final attendanceMap = ref.read(sessionAttendanceProvider(sessionId)).value ?? const {};
    final currentStatus = attendanceMap[studentId] ?? manifestStudent.status;

    final isMorning = trip.tripType.toLowerCase() == 'morning';
    String nextStatus;

    if (isMorning) {
      if (currentStatus == 'At Home') {
        nextStatus = 'In Van';
      } else if (currentStatus == 'In Van') {
        nextStatus = 'At School';
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => SafePickDialog(
              title: 'Scan Error',
              description: '${manifestStudent.name} is already marked as At School.',
              isDestructive: true,
              primaryActionLabel: 'OK',
              onPrimaryAction: () => Navigator.of(context).pop(),
            ),
          );
        }
        return;
      }
    } else {
      if (currentStatus == 'At School' || currentStatus == 'Absent') {
        nextStatus = 'In Van';
      } else if (currentStatus == 'In Van') {
        nextStatus = 'At Home';
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => SafePickDialog(
              title: 'Scan Error',
              description: '${manifestStudent.name} is already marked as At Home.',
              isDestructive: true,
              primaryActionLabel: 'OK',
              onPrimaryAction: () => Navigator.of(context).pop(),
            ),
          );
        }
        return;
      }
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => SafePickDialog(
        title: nextStatus == 'In Van'
            ? 'Board Student'
            : nextStatus == 'At School'
                ? 'Offboard Student (At School)'
                : 'Offboard Student (At Home)',
        description: 'Are you sure you want to mark ${manifestStudent.name} as $nextStatus?',
        primaryActionLabel: 'Confirm',
        primaryActionColor: nextStatus == 'In Van'
            ? AppTheme.primaryGoldDark
            : AppTheme.successGreen,
        onPrimaryAction: () => Navigator.of(context).pop(true),
        secondaryActionLabel: 'Cancel',
        onSecondaryAction: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(tripServiceProvider).processQrScan(studentId, sessionId);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => SafePickDialog(
            title: 'Status Updated',
            description: '${manifestStudent.name} is now $nextStatus.',
            primaryActionLabel: 'CONTINUE',
            primaryActionColor: AppTheme.successGreen,
            onPrimaryAction: () => Navigator.of(context).pop(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing scan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripDetailsProvider(widget.tripId));
    final sessionAsync = ref.watch(activeSessionProvider(widget.tripId));
    final schoolsAsync = ref.watch(activeSchoolsStreamProvider);

    final session = sessionAsync.asData?.value;
    final isTripActive = session?.status == 'in_progress';

    return PopScope(
      canPop: !isTripActive,
      onPopInvokedWithResult: (didPop, result) {
        // Silent block if they try to exit while active
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(isTripActive ? 'ACTIVE ROUTE' : 'Route Details', style: const TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: isTripActive ? AppTheme.surfaceCard : AppTheme.background,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight((_isOffline || _isLocationDisabled) ? 40.0 : 0.0),
            child: Column(
              children: [
                if (_isOffline)
                  Container(
                    width: double.infinity,
                    color: AppTheme.errorRed,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: const Text(
                      'You are offline. Syncing paused.',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_isLocationDisabled)
                  Container(
                    width: double.infinity,
                    color: AppTheme.warningOrange,
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    child: const Text(
                      'Location disabled. Parents cannot track you.',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
          leading: isTripActive
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
          automaticallyImplyLeading: !isTripActive,
          actions: [
            if (!isTripActive)
              tripAsync.when(
                data: (trip) => IconButton(
                  icon: const Icon(Icons.edit_note_rounded, size: 28, color: AppTheme.textPrimary),
                  onPressed: () => _handleEditTrip(trip),
                ),
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),
          ],
        ),
        bottomNavigationBar: sessionAsync.when(
          data: (session) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildActionButtons(session),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (err, _) => const SizedBox.shrink(),
        ),
        body: tripAsync.when(
          data: (trip) {
            return sessionAsync.when(
              data: (session) {
                final allSchools = schoolsAsync.value ?? [];
                final tripSchools = allSchools.where((s) => trip.schoolIds.contains(s.schoolId)).toList();
                
                ref.listen(tripManifestProvider(widget.tripId), (prev, next) {
                  final manifest = next.value ?? [];
                  final attendanceMap = session != null ? ref.read(sessionAttendanceProvider(session.sessionId)).value ?? {} : <String, String>{};
                  _updateStudentMarkers(manifest, attendanceMap, trip.tripType);
                  _updateSchoolMarkers(tripSchools, manifest);
                });

                if (session != null) {
                  ref.listen(sessionAttendanceProvider(session.sessionId), (prev, next) {
                    final attendanceMap = next.value ?? {};
                    final manifest = ref.read(tripManifestProvider(widget.tripId)).value ?? [];
                    _updateStudentMarkers(manifest, attendanceMap, trip.tripType);
                  });
                }
                
                // Initialize school markers if not yet initialized
                if (_currentSchools.isEmpty && tripSchools.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final manifest = ref.read(tripManifestProvider(widget.tripId)).value ?? [];
                    _updateSchoolMarkers(tripSchools, manifest);
                  });
                }

                if (session == null || session.status != 'in_progress') {
                  if (_isLiveTracking) _stopLiveTracking();
                  
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildTripDetailsCard(theme, trip, session),
                            const SizedBox(height: 16),
                            ref.watch(tripManifestProvider(widget.tripId)).when(
                                  data: (manifest) => _buildSchoolsSummary(theme, manifest),
                                  loading: () => const SizedBox.shrink(),
                                  error: (err, stack) => const SizedBox.shrink(),
                                ),
                            const SizedBox(height: 24),
                            _buildRosterHeader(theme, ref.watch(tripManifestProvider(widget.tripId))),
                            const SizedBox(height: 12),
                            ref.watch(tripManifestProvider(widget.tripId)).when(
                                  data: (manifest) {
                                    if (manifest.isEmpty) return _buildEmptyRosterCard(theme);
                                    final attendanceMap = session != null
                                        ? ref.watch(sessionAttendanceProvider(session.sessionId)).asData?.value ?? const {}
                                        : const <String, String>{};
                                    return Column(
                                      children: manifest.asMap().entries.map((entry) {
                                        return _buildStudentRow(theme, entry.value, entry.key, session, attendanceMap, trip.tripType);
                                      }).toList(),
                                    );
                                  },
                                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.primaryGold))),
                                  error: (err, _) => _buildErrorState(theme, err.toString()),
                                ),
                            const SizedBox(height: 40), 
                          ]),
                        ),
                      ),
                    ],
                  );
                }

                return Stack(
                  children: [
                    if (_currentPosition == null)
                      Container(
                        color: AppTheme.background,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold)),
                              const SizedBox(height: 16),
                              Text(
                                'Acquiring secure GPS lock...',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ).animate().fade(duration: 400.ms).slideY(begin: 0.1),
                            ],
                          ),
                        ),
                      )
                    else
                      GoogleMap(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.25), 
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          zoom: 16,
                        ),
                        markers: _markers,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                      ),

                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton(
                        heroTag: 'recenter_fab',
                        backgroundColor: AppTheme.surfaceCard,
                        foregroundColor: AppTheme.primaryGoldDark,
                        onPressed: () {
                          if (_currentPosition != null && _mapController != null) {
                            _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude)));
                          }
                        },
                        child: const Icon(Icons.my_location_rounded, size: 28),
                      ),
                    ),

                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      top: _approachingStudentId != null ? 16 : -300,
                      left: 16,
                      right: 88, 
                      child: _approachingStudentId != null
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.primaryGold, width: 0.5), 
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'ACTION REQUIRED',
                                        style: TextStyle(color: AppTheme.primaryGoldDark, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted, size: 28),
                                        onPressed: () => setState(() => _approachingStudentId = null),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Approaching ${_approachingStudentName?.toUpperCase()}',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGold,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      final studentId = _approachingStudentId!;
                                      final nextStatus = _approachingNextStatus!;
                                      setState(() => _approachingStudentId = null);
                                      try {
                                        if (nextStatus == 'DROP_ALL') {
                                          await ref.read(tripServiceProvider).dropOffAllStudentsAtSchool(session.sessionId);
                                        } else {
                                          await ref.read(tripServiceProvider).manualAttendanceOverride(session.sessionId, studentId, nextStatus);
                                        }
                                      } catch (e) {
                                        debugPrint('Override Error: $e');
                                      }
                                    },
                                    child: Text(
                                      _approachingStatusAction ?? '',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    DraggableScrollableSheet(
                      initialChildSize: 0.35,
                      minChildSize: 0.15,
                      maxChildSize: 0.85,
                      snap: true,
                      snapSizes: const [0.15, 0.35, 0.85],
                      builder: (context, scrollController) {
                        return Container(
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, -5))
                            ],
                          ),
                          child: CustomScrollView(
                            controller: scrollController,
                            physics: const ClampingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 12),
                                    Container(
                                      width: 48,
                                      height: 6,
                                      decoration: BoxDecoration(color: AppTheme.primaryGold.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(3)),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('SWIPE UP FOR FULL ROSTER', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w800, fontSize: 12)),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate([
                                    _buildTripDetailsCard(theme, trip, session),
                                    const SizedBox(height: 16),
                                    ref.watch(tripManifestProvider(widget.tripId)).when(
                                          data: (manifest) => _buildSchoolsSummary(theme, manifest),
                                          loading: () => const SizedBox.shrink(),
                                          error: (err, stack) => const SizedBox.shrink(),
                                        ),
                                    const SizedBox(height: 24),
                                    _buildRosterHeader(theme, ref.watch(tripManifestProvider(widget.tripId))),
                                    const SizedBox(height: 12),
                                    ref.watch(tripManifestProvider(widget.tripId)).when(
                                          data: (manifest) {
                                            if (manifest.isEmpty) return _buildEmptyRosterCard(theme);
                                            final attendanceMap = ref.watch(sessionAttendanceProvider(session.sessionId)).asData?.value ?? const {};
                                            return Column(
                                              children: manifest.asMap().entries.map((entry) {
                                                return _buildStudentRow(theme, entry.value, entry.key, session, attendanceMap, trip.tripType);
                                              }).toList(),
                                            );
                                          },
                                          loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.primaryGold))),
                                          error: (err, _) => _buildErrorState(theme, err.toString()),
                                        ),
                                    const SizedBox(height: 24), 
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold))),
              error: (err, _) => _buildErrorState(theme, err.toString()),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold))),
          error: (err, _) => _buildErrorState(theme, err.toString()),
        ),
      ),
    );
  }

  Widget _buildTripDetailsCard(ThemeData theme, TripModel trip, DailySessionModel? session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGold, width: 0.5), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.tripName.toUpperCase(),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.primaryGold, thickness: 0.5, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                trip.tripType.toLowerCase() == 'morning' ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded, 
                color: AppTheme.primaryGold, 
                size: 28
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  trip.tripType.toLowerCase() == 'morning' ? 'MORNING PICK-UP' : 'AFTERNOON DROP-OFF',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(DailySessionModel? session) {
    final isSessionActive = session != null && session.status == 'in_progress';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isSessionActive) ...[
          SizedBox(
            height: 64,
            child: ElevatedButton.icon(
              onPressed: () async {
                final scannedId = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (context) => QRScannerScreen(sessionId: session.sessionId)),
                );
                if (scannedId != null && scannedId.isNotEmpty) {
                  _handleScannedStudent(scannedId, session.sessionId);
                }
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 32),
              label: const Text('SCAN ID CARD', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGoldDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (session == null || session.status == 'not_started') ...[
          SizedBox(
            height: 64, 
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleStartTrip,
              icon: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Icon(Icons.play_arrow_rounded, size: 32),
              label: const Text('START ROUTE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ] else if (session.status == 'in_progress') ...[
          SizedBox(
            height: 64,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handleEndTrip(session.sessionId),
              icon: const Icon(Icons.stop_rounded, size: 32),
              label: const Text('END TRIP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ] else ...[
          SizedBox(
            height: 64,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _handleReopenTrip(session.sessionId),
              icon: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                  : const Icon(Icons.refresh_rounded, size: 32),
              label: const Text('REDO TRIP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.textPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildSchoolsSummary(ThemeData theme, List<TripManifestModel> manifest) {
    final schoolNames = manifest
        .map((m) => m.schoolName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    if (schoolNames.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGold, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school_rounded, color: AppTheme.primaryGold, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTINATION SCHOOLS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schoolNames.join(', '),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterHeader(ThemeData theme, AsyncValue<List<TripManifestModel>> manifestAsync) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'ROSTER',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: manifestAsync.when(
            data: (manifest) => Text(
              '${manifest.length} Students',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppTheme.primaryGoldDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            loading: () => const Text('...', style: TextStyle(fontWeight: FontWeight.bold)),
            error: (error, _) => const Text('Error', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Future<void> _handleManualOverride(String sessionId, String studentId, String status) async {
    final isSuspended = await _isStudentParentSuspended(studentId);
    if (isSuspended) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => SafePickDialog(
            title: 'Access Revoked',
            description: 'Payment not done. Student cannot be managed.',
            isDestructive: true,
            primaryActionLabel: 'DISMISS',
            onPrimaryAction: () => Navigator.of(context).pop(),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => SafePickDialog(
        title: status == 'In Van'
            ? 'Board Student'
            : status == 'At School'
                ? 'Offboard Student (At School)'
                : status == 'At Home'
                    ? 'Offboard Student (At Home)'
                    : 'Mark Student Absent',
        description: 'Are you sure you want to mark this student as '
            '${status == 'In Van' ? 'boarded (in the van)' : status == 'At School' ? 'offboarded (at school)' : status == 'At Home' ? 'offboarded (at home)' : 'absent'}?',
        primaryActionLabel: 'Confirm',
        primaryActionColor: status == 'In Van'
            ? AppTheme.primaryGoldDark
            : (status == 'At School' || status == 'At Home')
                ? AppTheme.successGreen
                : AppTheme.errorRed,
        onPrimaryAction: () => Navigator.of(context).pop(true),
        secondaryActionLabel: 'Cancel',
        onSecondaryAction: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirm != true) return;
    try {
      await ref.read(tripServiceProvider).manualAttendanceOverride(sessionId, studentId, status);
    } catch (e) {
      debugPrint('Override Error: $e');
    }
  }

  Widget _buildStudentRow(ThemeData theme, TripManifestModel student, int index, DailySessionModel? session, Map<String, String> attendanceMap, String tripType) {
    final status = attendanceMap[student.studentId] ?? student.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5), width: 0.5), 
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: AppTheme.primaryGold.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Center(
              child: Text(
                '${student.stopOrder}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryGoldDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary, letterSpacing: -0.2),
                ),
                const SizedBox(height: 4),
                if (student.schoolName.isNotEmpty)
                  Text(
                    student.schoolName,
                    style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          _buildStatusChip(theme, status),
          
          if (session != null && session.status == 'in_progress') ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.edit_location_alt_rounded, color: AppTheme.primaryGoldDark, size: 28),
                color: AppTheme.surfaceCard,
                tooltip: "Update Status",
                onSelected: (newStatus) {
                  _handleManualOverride(session.sessionId, student.studentId, newStatus);
                },
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: 'In Van',
                      child: Text('Board (In Van)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const PopupMenuItem(
                      value: 'At School',
                      child: Text('Drop (At School)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const PopupMenuItem(
                      value: 'At Home',
                      child: Text('Drop (At Home)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    const PopupMenuItem(
                      value: 'Absent',
                      child: Text('Mark Absent', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ];
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, String status) {
    Color chipColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'in van':
        chipColor = AppTheme.warningOrange.withValues(alpha: 0.15);
        textColor = AppTheme.warningOrange;
        label = 'IN VAN';
        break;
      case 'at school':
        chipColor = AppTheme.primaryGoldDark.withValues(alpha: 0.15);
        textColor = AppTheme.primaryGoldDark;
        label = 'AT SCHOOL';
        break;
      case 'at home':
        chipColor = AppTheme.successGreen.withValues(alpha: 0.15);
        textColor = AppTheme.successGreen;
        label = 'AT HOME';
        break;
      case 'absent':
        chipColor = AppTheme.errorRed.withValues(alpha: 0.15);
        textColor = AppTheme.errorRed;
        label = 'ABSENT';
        break;
      default:
        chipColor = AppTheme.border;
        textColor = AppTheme.textSecondary;
        label = status.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmptyRosterCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: const Center(
        child: Text(
          'NO STUDENTS ASSIGNED',
          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 64),
            const SizedBox(height: 16),
            const Text(
              'ERROR LOADING ROUTE',
              style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w900, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(error, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────
// DEDICATED EDIT SCREEN 
// ───────────────────────────────────────────────────────────────────────
class _EditTripScreen extends StatefulWidget {
  final TripModel trip;
  final List<Map<String, String>> initialRoster;

  const _EditTripScreen({required this.trip, required this.initialRoster});

  @override
  State<_EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<_EditTripScreen> {
  late final TextEditingController _nameController;
  final _searchController = TextEditingController();
  late List<Map<String, String>> _currentRoster;
  late String _tripType;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.tripName);
    _tripType = widget.trip.tripType.isNotEmpty ? widget.trip.tripType : 'Morning';
    _currentRoster = List.from(widget.initialRoster);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addStudent() async {
    final query = _searchController.text.trim().toUpperCase();
    if (query.isEmpty) return;
    
    if (_currentRoster.any((s) => s['id'] == query)) return;

    setState(() => _isSearching = true);
    
    try {
      final firestore = ProviderScope.containerOf(context).read(firestoreProvider);
      final doc = await firestore.collection('students').doc(query).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _currentRoster.add({
            'id': query,
            'name': data['name'] ?? '',
            'school_name': data['school_name'] ?? '',
          });
          _searchController.clear();
        });
      } 
    } catch (e) {
      debugPrint('Search Error: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty || _currentRoster.isEmpty) return;
    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'type': _tripType,
      'roster': _currentRoster.map((s) => s['id']!).toList(),
    });
  }

  Widget _buildTypeToggle(String title, IconData icon, String value) {
    final isSelected = _tripType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tripType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGold : AppTheme.border,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Edit Route Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- SECTION 1: Trip Details ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step 1: Route Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            labelText: 'Route Name',
                            prefixIcon: Icon(Icons.directions_bus_outlined, size: 28),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Text(
                          'Shift Type',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Expanded(child: _buildTypeToggle('Morning', Icons.wb_sunny_rounded, 'Morning')),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTypeToggle('Afternoon', Icons.nights_stay_rounded, 'Afternoon')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- SECTION 2: Student Roster ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Step 2: Edit Roster',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                'Count: ${_currentRoster.length}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                decoration: const InputDecoration(
                                  labelText: 'Student ID',
                                  hintText: 'SP1005',
                                  prefixIcon: Icon(Icons.badge_rounded, size: 24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 56,
                              width: 90, 
                              child: ElevatedButton(
                                onPressed: _isSearching ? null : _addStudent,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: AppTheme.textPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isSearching 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.person_add_rounded, size: 24),
                                        Text('ADD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),

                        if (_currentRoster.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.border),
                                const SizedBox(height: 12),
                                Text(
                                  'No students linked.\nEnter an ID above and press ADD.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _currentRoster.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final s = _currentRoster[index];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(color: AppTheme.primaryGoldDark, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            s['name'] ?? '', 
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
                                          ),
                                          Text(
                                            'ID: ${s['id']}',
                                            style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, size: 28),
                                      color: AppTheme.errorRed.withValues(alpha: 0.8),
                                      onPressed: () {
                                        setState(() {
                                          _currentRoster.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}