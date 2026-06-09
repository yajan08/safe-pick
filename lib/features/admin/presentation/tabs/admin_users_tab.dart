import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/admin_service.dart';
import '../../data/audit_service.dart';
import '../../../auth/data/user_model.dart';
import '../../../trips/data/daily_session_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../admin_dashboard_screen.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  String _filterRole = 'All';
  String _searchQuery = '';

  List<UserModel> _applyFilters(List<UserModel> users) {
    var filtered = users;
    if (_filterRole == 'Drivers') {
      filtered = filtered.where((u) => u.role == 'driver').toList();
    } else if (_filterRole == 'Parents') {
      filtered = filtered.where((u) => u.role == 'parent').toList();
    } else if (_filterRole == 'Admins') {
      filtered = filtered.where((u) => u.role == 'admin').toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.phone.toLowerCase().contains(q) ||
          u.uid.toLowerCase().contains(q)).toList();
    }
    return filtered;
  }

  void _openUserDetail(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UserDetailSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Column(
      children: [
        // ── Search ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Search by name or phone…',
              hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6), fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textMuted.withValues(alpha: 0.7), size: 20),
              filled: true, 
              fillColor: AppTheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), 
                borderSide: const BorderSide(color: kAdminNavy, width: 1.2),
              ),
            ),
          ),
        ),

        // ── Filter chips ──────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: ['All', 'Parents', 'Drivers', 'Admins'].map((role) {
              final sel = _filterRole == role;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(role),
                  selected: sel,
                  onSelected: (_) => setState(() => _filterRole = role),
                  backgroundColor: AppTheme.surface,
                  selectedColor: kAdminNavy.withValues(alpha: 0.08),
                  checkmarkColor: kAdminNavy,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    color: sel ? kAdminNavy : AppTheme.textMuted,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.w500, 
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: sel ? kAdminNavy.withValues(alpha: 0.4) : AppTheme.border.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ── List ──────────────────────────────────────────────────────────
        Expanded(
          child: usersAsync.when(
            data: (allUsers) {
              final users = _applyFilters(allUsers);
              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      Icon(Icons.search_off_rounded, size: 44, color: AppTheme.textMuted.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty ? 'No users match your search.' : 'No users found.',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final user = users[i];
                  return _UserTile(user: user, onTap: () => _openUserDetail(user))
                      .animate().fade(delay: Duration(milliseconds: 25 * i.clamp(0, 10))).slideX(begin: 0.015);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: kAdminNavy, strokeWidth: 2.5)),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32), 
                child: Text('Error: $e', style: const TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w500)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// User tile
// ──────────────────────────────────────────────────────────────────────────────

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;
  const _UserTile({required this.user, required this.onTap});

  Color get _roleColor => user.role == 'driver' ? Colors.teal : user.role == 'admin' ? kAdminNavy : Colors.blueGrey;
  IconData get _roleIcon => user.role == 'driver' ? Icons.directions_car_rounded : user.role == 'admin' ? Icons.admin_panel_settings_rounded : Icons.person_rounded;

  @override
  Widget build(BuildContext context) {
    final isInactive = user.status == 'suspended' || user.status == 'inactive';
    return Opacity(
      opacity: isInactive ? 0.55 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015), 
              blurRadius: 8, 
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.25)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            radius: 18, 
            backgroundColor: _roleColor.withValues(alpha: 0.08), 
            child: Icon(_roleIcon, color: _roleColor, size: 18),
          ),
          title: Text(
            user.name, 
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, letterSpacing: -0.2),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Text(
                  user.phone.isNotEmpty ? user.phone : user.role.toUpperCase(), 
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w400),
                ),
                if (isInactive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withValues(alpha: 0.08), 
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'SUSPENDED', 
                      style: TextStyle(color: AppTheme.errorRed, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted.withValues(alpha: 0.5), size: 20),
          onTap: onTap,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// User detail sheet with CRUD
// ──────────────────────────────────────────────────────────────────────────────

class _UserDetailSheet extends ConsumerStatefulWidget {
  final UserModel user;
  const _UserDetailSheet({required this.user});

  @override
  ConsumerState<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends ConsumerState<_UserDetailSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _vehicleCtrl;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isTogglingStatus = false;
  List<DailySessionModel> _driverSessions = [];
  bool _isLoadingSessions = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone);
    _vehicleCtrl = TextEditingController(text: widget.user.vehicleNumbers.join(', '));
    if (widget.user.role == 'driver') _loadDriverSessions();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDriverSessions() async {
    setState(() => _isLoadingSessions = true);
    try {
      final audit = ref.read(auditServiceProvider);
      _driverSessions = await audit.getDriverSessions(widget.user.uid);
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSessions = false);
  }

  Future<void> _toggleStatus() async {
    setState(() => _isTogglingStatus = true);
    try {
      final audit = ref.read(auditServiceProvider);
      await audit.toggleUserStatus(widget.user.uid, widget.user.status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated.'), behavior: SnackBarBehavior.floating, backgroundColor: AppTheme.successGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    }
    if (mounted) setState(() => _isTogglingStatus = false);
  }

  Future<void> _saveEdits() async {
    setState(() => _isSaving = true);
    try {
      final updates = <String, dynamic>{};
      if (_nameCtrl.text.trim() != widget.user.name) updates['name'] = _nameCtrl.text.trim();
      if (_phoneCtrl.text.trim() != widget.user.phone) updates['phone'] = _phoneCtrl.text.trim();
      if (widget.user.role == 'driver') {
        final vehicles = _vehicleCtrl.text.split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
        updates['vehicle_numbers'] = vehicles;
        if (vehicles.isNotEmpty) updates['vehicle_number'] = vehicles.first;
      }
      if (updates.isNotEmpty) {
        final audit = ref.read(auditServiceProvider);
        await audit.updateUserDetails(widget.user.uid, updates);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Details saved.'), behavior: SnackBarBehavior.floating, backgroundColor: AppTheme.successGreen),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating));
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.user.status == 'active';

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, 
                height: 4, 
                decoration: BoxDecoration(color: AppTheme.border.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),

            // Avatar + role
            Row(
              children: [
                CircleAvatar(
                  radius: 24, 
                  backgroundColor: kAdminNavy.withValues(alpha: 0.08), 
                  child: const Icon(Icons.person_rounded, color: kAdminNavy, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      Text(
                        widget.user.name, 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.user.role.toUpperCase(), 
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 1.0, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: kAdminNavy, size: 20), 
                    onPressed: () => setState(() => _isEditing = true),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Status toggle ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.successGreen.withValues(alpha: 0.03) : AppTheme.errorRed.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isActive ? AppTheme.successGreen.withValues(alpha: 0.15) : AppTheme.errorRed.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(
                    isActive ? Icons.check_circle_outline_rounded : Icons.block_rounded, 
                    color: isActive ? AppTheme.successGreen : AppTheme.errorRed, 
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isActive ? 'Active Status' : 'Suspended Status', 
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: isActive ? AppTheme.successGreen : AppTheme.errorRed),
                    ),
                  ),
                  _isTogglingStatus
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : SizedBox(
                          height: 28,
                          child: Switch(
                            value: isActive,
                            activeTrackColor: AppTheme.successGreen.withValues(alpha: 0.2),
                            thumbColor: WidgetStateProperty.resolveWith((states) => 
                              states.contains(WidgetState.selected) ? AppTheme.successGreen : Colors.grey[400]),
                            onChanged: (_) => _toggleStatus(),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Editable / Read-only fields ───────────────────────────────
            if (_isEditing) ...[
              _EditField(label: 'Name', controller: _nameCtrl),
              const SizedBox(height: 12),
              _EditField(label: 'Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone),
              if (widget.user.role == 'driver') ...[
                const SizedBox(height: 12),
                _EditField(label: 'Vehicles (comma-separated)', controller: _vehicleCtrl),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.border.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveEdits,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAdminNavy, 
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _DetailRow(icon: Icons.fingerprint_rounded, label: 'UID', value: widget.user.uid),
              _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: widget.user.phone.isNotEmpty ? widget.user.phone : '—'),
              _DetailRow(icon: Icons.calendar_today_outlined, label: 'Joined', value: widget.user.createdAt.toString().split(' ')[0]),
              if (widget.user.role == 'driver' && widget.user.vehicleNumbers.isNotEmpty)
                _DetailRow(icon: Icons.directions_car_outlined, label: 'Vehicles', value: widget.user.vehicleNumbers.join(', ')),
            ],

            // ── Driver metrics ────────────────────────────────────────────
            if (widget.user.role == 'driver') ...[
              const SizedBox(height: 16),
              Divider(color: AppTheme.border.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              const Text('Trip History', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: kAdminNavy)),
              const SizedBox(height: 12),
              if (_isLoadingSessions)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: kAdminNavy, strokeWidth: 2)))
              else if (_driverSessions.isEmpty)
                Text('No trip sessions recorded.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500))
              else ...[
                _DriverMetricRow(label: 'Total Sessions', value: '${_driverSessions.length}'),
                _DriverMetricRow(
                  label: 'Completed',
                  value: '${_driverSessions.where((s) => s.status == 'completed').length}',
                ),
                _DriverMetricRow(label: 'Active Vehicles', value: widget.user.vehicleNumbers.isNotEmpty ? widget.user.vehicleNumbers.join(', ') : '—'),
              ],
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, 
              height: 46,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: kAdminNavy.withValues(alpha: 0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Close', style: TextStyle(color: kAdminNavy, fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Shared private widgets
// ──────────────────────────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  const _EditField({required this.label, required this.controller, this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kAdminNavy, width: 1.2)),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: AppTheme.textMuted.withValues(alpha: 0.6), size: 16),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis, textAlign: TextAlign.end)),
      ]),
    );
  }
}

class _DriverMetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _DriverMetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}