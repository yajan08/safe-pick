import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../features/trips/data/trip_service.dart';

/// Provider for SyncQueueService
final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  final tripService = ref.watch(tripServiceProvider);
  final service = SyncQueueService(tripService);
  service.init();
  return service;
});

/// Data model for an offline scan log
class SyncLog {
  final int? id;
  final String studentId;
  final String sessionId;
  final DateTime scannedAt;
  final double latitude;
  final double longitude;

  SyncLog({
    this.id,
    required this.studentId,
    required this.sessionId,
    required this.scannedAt,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'session_id': sessionId,
      'scanned_at': scannedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory SyncLog.fromMap(Map<String, dynamic> map) {
    return SyncLog(
      id: map['id'] as int?,
      studentId: map['student_id'] as String,
      sessionId: map['session_id'] as String,
      scannedAt: DateTime.parse(map['scanned_at'] as String),
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
    );
  }
}

/// Service that handles local SQLite storage and background network syncing
class SyncQueueService {
  final TripService _tripService;
  Database? _db;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isSyncing = false;

  SyncQueueService(this._tripService);

  Future<void> init() async {
    if (_db != null) return;
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sync_queue.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id TEXT NOT NULL,
            session_id TEXT NOT NULL,
            scanned_at TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL
          )
        ''');
      },
    );

    // Listen to network changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.contains(ConnectivityResult.mobile) || 
                       results.contains(ConnectivityResult.wifi) ||
                       results.contains(ConnectivityResult.ethernet);
      
      if (isOnline) {
        _triggerSync();
      }
    });

    // Initial check
    final initialStatus = await Connectivity().checkConnectivity();
    if (initialStatus.contains(ConnectivityResult.mobile) || 
        initialStatus.contains(ConnectivityResult.wifi) ||
        initialStatus.contains(ConnectivityResult.ethernet)) {
      _triggerSync();
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _db?.close();
  }

  Future<void> addToQueue(SyncLog log) async {
    if (_db == null) await init();
    await _db!.insert('sync_queue', log.toMap());
    
    // Attempt sync immediately in case we are online
    _triggerSync();
  }

  Future<List<SyncLog>> getPendingLogs() async {
    if (_db == null) await init();
    final maps = await _db!.query('sync_queue', orderBy: 'id ASC');
    return maps.map((map) => SyncLog.fromMap(map)).toList();
  }

  Future<void> deleteFromQueue(int id) async {
    if (_db == null) await init();
    await _db!.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _triggerSync() async {
    if (_isSyncing || _db == null) return;
    _isSyncing = true;

    try {
      final pendingLogs = await getPendingLogs();
      if (pendingLogs.isEmpty) {
        _isSyncing = false;
        return;
      }

      for (var log in pendingLogs) {
        try {
          // Process via Firestore Batch Write
          await _tripService.processQrScan(
            log.studentId,
            log.sessionId,
            overrideTimestamp: log.scannedAt,
          );
          // If successful, delete from local queue
          await deleteFromQueue(log.id!);
          debugPrint('Successfully synced offline scan for ${log.studentId}');
        } catch (e) {
          debugPrint('Failed to sync log ${log.id}: $e');
          // If a single write fails (e.g. network drops mid-sync, or Firestore error),
          // we stop the sync loop to prevent spamming errors and wait for the next trigger.
          break;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
