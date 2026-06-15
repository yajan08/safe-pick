import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/user_model.dart';
import '../../trips/data/trip_model.dart';
import 'admin_dashboard_screen.dart' show kAdminNavy;
import 'admin_trip_history_screen.dart';

final driverTripsProvider = FutureProvider.family<List<TripModel>, String>((ref, driverUid) async {
  final firestore = FirebaseFirestore.instance;
  final snap = await firestore
      .collection('trips')
      .where('driver_uid', isEqualTo: driverUid)
      .get();
      
  return snap.docs.map((doc) => TripModel.fromJson(doc.data(), doc.id)).toList();
});

class AdminDriverDetailScreen extends ConsumerStatefulWidget {
  final UserModel driver;

  const AdminDriverDetailScreen({super.key, required this.driver});

  @override
  ConsumerState<AdminDriverDetailScreen> createState() => _AdminDriverDetailScreenState();
}

class _AdminDriverDetailScreenState extends ConsumerState<AdminDriverDetailScreen> {
  bool _isLoading = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.driver.status;
  }

  Future<void> _toggleStatus() async {
    final newStatus = (_currentStatus == 'suspended' || _currentStatus == 'inactive') 
        ? 'active' 
        : 'suspended';
    
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.driver.uid).update({
        'status': newStatus,
      });
      if (mounted) {
        setState(() {
          _currentStatus = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account ${newStatus == 'active' ? 'activated' : 'suspended'} successfully'),
            backgroundColor: newStatus == 'active' ? AppTheme.successGreen : AppTheme.warningOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRemove() async {
    final TextEditingController controller = TextEditingController();
    bool canDelete = false;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.background,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.3), width: 1),
              ),
              title: const Text(
                'Remove Driver',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to remove ${widget.driver.name}? This will permanently delete their active profile, but their trip history will remain intact.',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Type "Delete" to confirm:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Delete',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        canDelete = val == 'Delete';
                      });
                    },
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.all(16),
              actionsAlignment: MainAxisAlignment.end,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canDelete ? AppTheme.errorRed : AppTheme.errorRed.withValues(alpha: 0.3),
                    foregroundColor: AppTheme.background,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: canDelete ? () => Navigator.pop(context, true) : null,
                  child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            );
          }
        );
      },
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('users').doc(widget.driver.uid).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Driver removed successfully'),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove: $e'),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripsAsync = ref.watch(driverTripsProvider(widget.driver.uid));
    
    final formatter = DateFormat('MMM d, yyyy');
    final isInactive = _currentStatus == 'suspended' || _currentStatus == 'inactive';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        foregroundColor: kAdminNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Driver Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.5,
            color: kAdminNavy,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22, color: AppTheme.errorRed),
            tooltip: 'Remove Driver',
            onPressed: _isLoading ? null : () => _handleRemove(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Driver Profile Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    child: const Icon(Icons.directions_car_rounded, color: Colors.teal, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.driver.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _isLoading ? null : _toggleStatus,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isInactive ? AppTheme.errorRed.withValues(alpha: 0.1) : AppTheme.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isInactive ? AppTheme.errorRed.withValues(alpha: 0.5) : AppTheme.successGreen.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isInactive ? Icons.block_rounded : Icons.check_circle_outline_rounded, 
                               size: 16, 
                               color: isInactive ? AppTheme.errorRed : AppTheme.successGreen),
                          const SizedBox(width: 8),
                          Text(
                            isInactive ? 'SUSPENDED (Tap to Activate)' : 'ACTIVE (Tap to Suspend)',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isInactive ? AppTheme.errorRed : AppTheme.successGreen,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(theme, Icons.phone_rounded, 'Phone', widget.driver.phone.isNotEmpty ? widget.driver.phone : 'N/A'),
                  Divider(color: AppTheme.border.withValues(alpha: 0.3), height: 24),
                  _buildDetailRow(
                    theme, 
                    Icons.calendar_today_rounded, 
                    'Joined', 
                    formatter.format(widget.driver.createdAt)
                  ),
                  Divider(color: AppTheme.border.withValues(alpha: 0.3), height: 24),
                  _buildDetailRow(theme, Icons.badge_rounded, 'UID', widget.driver.uid),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            Text(
              'Assigned Trips',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: kAdminNavy,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),
            
            tripsAsync.when(
              data: (trips) {
                if (trips.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
                    ),
                    child: const Center(
                      child: Text('No trips assigned to this driver.'),
                    ),
                  );
                }
                
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trips.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final trip = trips[index];
                    return _buildTripCard(context, theme, trip);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: kAdminNavy)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTripCard(BuildContext context, ThemeData theme, TripModel trip) {
    final isMorning = trip.tripType.toLowerCase() == 'morning';
    
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AdminTripHistoryScreen(trip: trip),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMorning ? AppTheme.primaryGold.withValues(alpha: 0.1) : AppTheme.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
                color: isMorning ? AppTheme.primaryGold : AppTheme.successGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.tripName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${trip.studentIds.length} Students • ${trip.tripType}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
