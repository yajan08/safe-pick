import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../data/trip_model.dart';
import '../data/trip_service.dart';
import '../data/trip_manifest_model.dart';
import '../data/daily_session_model.dart';
import 'qr_scanner_screen.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/services/auth_service.dart';

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

  Future<void> _handleStartTrip() async {
    setState(() => _isLoading = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.startDailySession(widget.tripId);
      ref.invalidate(tripDetailsProvider(widget.tripId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip session started!'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEndTrip(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('End Trip', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to end this trip?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.endDailySession(sessionId, widget.tripId);
      ref.invalidate(tripDetailsProvider(widget.tripId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip ended successfully.'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReopenTrip(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Reopen Trip', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Are you sure you want to reopen this trip? This will set it back to In Progress.', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.white),
            child: const Text('Reopen Trip'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final tripService = ref.read(tripServiceProvider);
      await tripService.reopenDailySession(sessionId, widget.tripId);
      ref.invalidate(tripDetailsProvider(widget.tripId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip reopened successfully.'),
            backgroundColor: AppTheme.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEditTrip(TripModel trip) async {
    final nameController = TextEditingController(text: trip.tripName);
    final searchController = TextEditingController();
    
    // Retrieve students initially attached to this trip manifest
    final manifestAsync = ref.read(tripManifestProvider(trip.tripId));
    final List<Map<String, String>> currentRoster = [];
    
    if (manifestAsync.hasValue) {
      for (var student in manifestAsync.value!) {
        currentRoster.add({
          'id': student.studentId,
          'name': student.name,
          'school_name': student.schoolName,
        });
      }
    }

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Edit Trip',
      pageBuilder: (context, anim1, anim2) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isSearching = false;

            Future<void> addStudent() async {
              final query = searchController.text.trim().toUpperCase();
              if (query.isEmpty) return;
              if (currentRoster.any((s) => s['id'] == query)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Student already in roster.')),
                );
                return;
              }

              setDialogState(() => isSearching = true);
              try {
                final firestore = ref.read(firestoreProvider);
                final doc = await firestore.collection('students').doc(query).get();
                if (doc.exists && doc.data() != null) {
                  final data = doc.data()!;
                  setDialogState(() {
                    currentRoster.add({
                      'id': query,
                      'name': data['name'] ?? '',
                      'school_name': data['school_name'] ?? '',
                    });
                    searchController.clear();
                  });
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Student ID not found.')),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error searching student: $e')),
                  );
                }
              } finally {
                setDialogState(() => isSearching = false);
              }
            }

            return Scaffold(
              backgroundColor: AppTheme.background,
              appBar: AppBar(
                title: const Text('Edit Trip Details'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a trip name.')),
                        );
                        return;
                      }
                      if (currentRoster.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please add at least one student.')),
                        );
                        return;
                      }
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Trip Name',
                        prefixIcon: Icon(Icons.directions_bus_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Add Student by ID',
                              prefixIcon: Icon(Icons.person_add_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isSearching ? null : addStudent,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(80, 56), // Override double.infinity to prevent layout crashes in Row
                            ),
                            child: isSearching
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'ROSTER (${currentRoster.length} Students)',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: currentRoster.isEmpty
                          ? const Center(child: Text('No students linked.', style: TextStyle(color: AppTheme.textSecondary)))
                          : ListView.builder(
                              itemCount: currentRoster.length,
                              itemBuilder: (context, index) {
                                final s = currentRoster[index];
                                return Card(
                                  color: AppTheme.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(color: AppTheme.border),
                                  ),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('ID: ${s['id']} • ${s['school_name'] ?? ''}'),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed),
                                      onPressed: () {
                                        setDialogState(() {
                                          currentRoster.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true) {
      setState(() => _isLoading = true);
      try {
        final newStudentIds = currentRoster.map((s) => s['id']!).toList();
        await ref.read(tripServiceProvider).updateTrip(trip.tripId, nameController.text.trim(), newStudentIds);
        ref.invalidate(tripDetailsProvider(widget.tripId));
        ref.invalidate(tripManifestProvider(widget.tripId));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip details updated successfully.'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) _showError(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleScannedStudent(String studentId, String sessionId) async {
    // 1. Get current manifest to validate if student is part of the trip
    final manifestAsync = ref.read(tripManifestProvider(widget.tripId));
    if (!manifestAsync.hasValue) {
      _showError("Roster manifest is still loading. Please try again.");
      return;
    }

    final manifest = manifestAsync.value!;
    final manifestStudent = manifest.where((s) => s.studentId == studentId).firstOrNull;

    if (manifestStudent == null) {
      // Student NOT in the active trip
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.background,
            title: const Text(
              'Error',
              style: TextStyle(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Error: Student $studentId is not part of this trip.',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // 2. Read the trip details to know the trip type (pickup vs dropoff/morning vs afternoon)
    final tripAsync = ref.read(tripDetailsProvider(widget.tripId));
    if (!tripAsync.hasValue) {
      _showError("Trip details are still loading. Please try again.");
      return;
    }
    final trip = tripAsync.value!;

    // 3. Read current status from attendance map
    final attendanceMap = ref.read(sessionAttendanceProvider(sessionId)).value ?? const {};
    final currentStatus = attendanceMap[studentId] ?? manifestStudent.status;

    // 4. State Machine check
    final isMorning = trip.tripType.toLowerCase() == 'pickup' || trip.tripType.toLowerCase() == 'morning';
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
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.background,
              title: const Text(
                'Scan Error',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Student ${manifestStudent.name} is already at school.',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
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
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.background,
              title: const Text(
                'Scan Error',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Student ${manifestStudent.name} is already at home.',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    // 5. Show clean, centered AlertDialog popup feedback immediately
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.background,
          title: const Text(
            'Status Updated',
            style: TextStyle(
              color: AppTheme.successGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Student ${manifestStudent.name} ($studentId) is now $nextStatus.',
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    // 6. Execute the Firebase update to commit this new status to the database
    try {
      await ref.read(tripServiceProvider).processQrScan(studentId, sessionId);
    } catch (e) {
      if (mounted) {
        _showError(e.toString());
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripAsync = ref.watch(tripDetailsProvider(widget.tripId));
    final sessionAsync = ref.watch(activeSessionProvider(widget.tripId));

    final session = sessionAsync.asData?.value;
    final isTripActive = session?.status == 'in_progress';

    return PopScope(
      canPop: !isTripActive,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isTripActive) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must end the active trip before leaving this screen.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(isTripActive ? 'Active Trip' : 'Trip Details'),
          leading: isTripActive
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
          automaticallyImplyLeading: !isTripActive,
        ),
        bottomNavigationBar: sessionAsync.when(
          data: (session) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 20),

                                  // 1. Trip Details & Action Buttons
                                  _buildTripDetailsCard(theme, trip, session),
                                  const SizedBox(height: 16),

                                  // 2. Map Placeholder
                                  _buildMapPlaceholder(theme),
                                  const SizedBox(height: 24),

                                  // 3. Target Schools Summary
                                  ref.watch(tripManifestProvider(widget.tripId)).when(
                                        data: (manifest) => _buildSchoolsSummary(theme, manifest),
                                        loading: () => const SizedBox.shrink(),
                                        error: (err, stack) => const SizedBox.shrink(),
                                      ),
                                  const SizedBox(height: 24),

                                  // 4. Roster Header
                                  _buildRosterHeader(theme, ref.watch(tripManifestProvider(widget.tripId))),
                                  const SizedBox(height: 16),

                                  // 5. Roster list
                                  ref.watch(tripManifestProvider(widget.tripId)).when(
                                        data: (manifest) {
                                          if (manifest.isEmpty) {
                                            return _buildEmptyRosterCard(theme);
                                          }

                                          final attendanceMap = session != null
                                              ? ref.watch(sessionAttendanceProvider(session.sessionId)).asData?.value ?? const {}
                                              : const <String, String>{};

                                          return Column(
                                            children: manifest.asMap().entries.map((entry) {
                                              return _buildStudentRow(theme, entry.value, entry.key, session, attendanceMap);
                                            }).toList(),
                                          );
                                        },
                                        loading: () => const ShimmerList(itemCount: 3, itemHeight: 80),
                                        error: (err, _) => _buildErrorState(theme, err.toString()),
                                      ),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
        floatingActionButton: sessionAsync.when(
          data: (session) {
            if (session != null && session.status == 'in_progress') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () async {
                    final scannedId = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (context) => QRScannerScreen(sessionId: session.sessionId),
                      ),
                    );
                    if (scannedId != null && scannedId.isNotEmpty) {
                      _handleScannedStudent(scannedId, session.sessionId);
                    }
                  },
                  child: const Icon(Icons.qr_code_scanner_rounded, size: 36),
                ),
              );
            }
            return null;
          },
          loading: () => null,
          error: (error, _) => null,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  // ─── 1. Trip Details Card ────────────────────────────
  Widget _buildTripDetailsCard(ThemeData theme, TripModel trip, DailySessionModel? session) {
    final showEdit = session == null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trip.tripName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showEdit)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryGold),
                    onPressed: () => _handleEditTrip(trip),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 12),
          _buildInfoRow(
            theme,
            trip.tripType.toLowerCase() == 'pickup' || trip.tripType.toLowerCase() == 'morning'
                ? Icons.login_rounded
                : Icons.logout_rounded,
            'Type',
            trip.tripType.toLowerCase() == 'pickup' || trip.tripType.toLowerCase() == 'morning'
                ? 'Morning Pick-Up'
                : 'Afternoon Drop-Off',
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms).slideY(begin: 0.03);
  }

  Widget _buildActionButtons(DailySessionModel? session) {
    if (session == null || session.status == 'not_started') {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleStartTrip,
          icon: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.play_arrow_rounded),
          label: const Text('START TRIP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGold,
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else if (session.status == 'in_progress') {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _handleEndTrip(session.sessionId),
          icon: const Icon(Icons.stop_rounded),
          label: const Text('END TRIP'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB71C1C), // Deep Red
            foregroundColor: Colors.white,
          ),
        ),
      );
    } else {
      // completed
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _handleReopenTrip(session.sessionId),
          icon: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.refresh_rounded),
          label: const Text('REDO TRIP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryGold,
            foregroundColor: Colors.white,
          ),
        ),
      );
    }
  }

  Widget _buildInfoRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryGold, size: 20),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // ─── 2. Map Placeholder ────────────────────────────────
  Widget _buildMapPlaceholder(ThemeData theme) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map View loading... (Coming Soon)'),
            backgroundColor: AppTheme.primaryGold,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border),
        ),
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _MapGridPainter(),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.map_rounded, color: AppTheme.primaryGold, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'View Live Map',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fade(delay: 200.ms).slideY(begin: 0.03);
  }

  // ─── 3. Target Schools Summary ─────────────────────────
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
        color: AppTheme.primaryGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school_rounded, color: AppTheme.primaryGold, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Destinations',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schoolNames.join(', '),
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 250.ms).slideY(begin: 0.03);
  }

  // ─── 4. Roster Header ─────────────────────────────────
  Widget _buildRosterHeader(ThemeData theme, AsyncValue<List<TripManifestModel>> manifestAsync) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Student Roster',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: manifestAsync.when(
            data: (manifest) => Text(
              '${manifest.length} Students',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppTheme.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            loading: () => const Text('...'),
            error: (error, _) => const Text('Error'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleManualOverride(String sessionId, String studentId, String status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: Text(
          status == 'In Van'
              ? 'Board Student'
              : status == 'At School'
                  ? 'Offboard Student (At School)'
                  : status == 'At Home'
                      ? 'Offboard Student (At Home)'
                      : 'Mark Student Absent',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to mark this student as '
          '${status == 'In Van' ? 'boarded (in the van)' : status == 'At School' ? 'offboarded (at school)' : status == 'At Home' ? 'offboarded (at home)' : 'absent'}?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: status == 'In Van'
                  ? AppTheme.primaryGold
                  : (status == 'At School' || status == 'At Home')
                      ? AppTheme.successGreen
                      : AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await ref.read(tripServiceProvider).manualAttendanceOverride(sessionId, studentId, status);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  // ─── 5. Student Roster Row ────────────────────────────
  Widget _buildStudentRow(ThemeData theme, TripManifestModel student, int index, DailySessionModel? session, Map<String, String> attendanceMap) {
    final status = attendanceMap[student.studentId] ?? student.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${student.stopOrder}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (student.schoolName.isNotEmpty)
                  Text(
                    student.schoolName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildStatusChip(theme, status),
          if (session != null && session.status == 'in_progress') ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textSecondary),
              color: AppTheme.surface,
              onSelected: (newStatus) {
                _handleManualOverride(session.sessionId, student.studentId, newStatus);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'At Home',
                  child: Text('At Home', style: TextStyle(color: AppTheme.textPrimary)),
                ),
                const PopupMenuItem(
                  value: 'In Van',
                  child: Text('In Van', style: TextStyle(color: AppTheme.textPrimary)),
                ),
                const PopupMenuItem(
                  value: 'At School',
                  child: Text('At School', style: TextStyle(color: AppTheme.textPrimary)),
                ),
                const PopupMenuItem(
                  value: 'Absent',
                  child: Text('Absent', style: TextStyle(color: AppTheme.textPrimary)),
                ),
              ],
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
        chipColor = AppTheme.primaryGold.withValues(alpha: 0.15);
        textColor = AppTheme.primaryGold;
        label = 'In Van';
        break;
      case 'at school':
        chipColor = AppTheme.successGreen.withValues(alpha: 0.15);
        textColor = AppTheme.successGreen;
        label = 'At School';
        break;
      case 'at home':
        chipColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue;
        label = 'At Home';
        break;
      case 'absent':
        chipColor = AppTheme.errorRed.withValues(alpha: 0.15);
        textColor = AppTheme.errorRed;
        label = 'Absent';
        break;
      default:
        chipColor = AppTheme.border;
        textColor = AppTheme.textSecondary;
        label = status;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyRosterCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Center(
        child: Text(
          'No students assigned to this trip yet.',
          style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
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
            const Icon(Icons.error_outline_rounded, color: AppTheme.errorRed, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading details',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.errorRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(error, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 0.5;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
