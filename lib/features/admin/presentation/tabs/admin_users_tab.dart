import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/admin_service.dart';
import '../../../auth/data/user_model.dart';
import '../../../../core/theme/app_theme.dart';

class AdminUsersTab extends ConsumerStatefulWidget {
  const AdminUsersTab({super.key});

  @override
  ConsumerState<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends ConsumerState<AdminUsersTab> {
  final ScrollController _scrollController = ScrollController();
  final List<UserModel> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  String _selectedRole = 'All';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchUsers();
      }
    });
  }

  Future<void> _fetchUsers({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;

    if (refresh) {
      setState(() {
        _users.clear();
        _lastDoc = null;
        _hasMore = true;
      });
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(adminServiceProvider);
      // We do a raw firestore query here to get the DocumentSnapshot for cursor pagination
      final firestore = FirebaseFirestore.instance;
      Query query = firestore.collection('users').orderBy('created_at', descending: true);
      
      if (_selectedRole != 'All') {
        query = firestore.collection('users')
            .where('role', isEqualTo: _selectedRole.toLowerCase())
            .orderBy('created_at', descending: true);
      }

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snap = await query.limit(20).get();
      
      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last;
        final newUsers = snap.docs.map((d) => UserModel.fromJson(d.data() as Map<String, dynamic>)).toList();
        setState(() {
          _users.addAll(newUsers);
          if (newUsers.length < 20) _hasMore = false;
        });
      } else {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching users: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showUserDetails(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: const Color(0xFF1A237E).withOpacity(0.1), child: Icon(Icons.person_rounded, color: const Color(0xFF1A237E))),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(user.role.toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 13, letterSpacing: 1)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailRow(icon: Icons.email_rounded, label: 'Email UID', value: user.uid), // In a real app we might fetch email from auth or store it in user doc
            _DetailRow(icon: Icons.phone_rounded, label: 'Phone', value: user.phone),
            _DetailRow(icon: Icons.calendar_today_rounded, label: 'Joined', value: user.createdAt.toString().split(' ')[0]),
            if (user.role == 'driver' && user.vehicleNumber != null)
              _DetailRow(icon: Icons.directions_car_rounded, label: 'Vehicle', value: user.vehicleNumber!),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF1A237E))),
                child: const Text('Close', style: TextStyle(color: Color(0xFF1A237E))),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: ['All', 'Parents', 'Drivers', 'Admins'].map((role) {
              final isSelected = _selectedRole == role;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(role),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedRole = role);
                      _fetchUsers(refresh: true);
                    }
                  },
                  backgroundColor: Colors.white,
                  selectedColor: const Color(0xFF1A237E).withOpacity(0.1),
                  checkmarkColor: const Color(0xFF1A237E),
                  labelStyle: TextStyle(color: isSelected ? const Color(0xFF1A237E) : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? const Color(0xFF1A237E) : AppTheme.border)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetchUsers(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _users.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _users.length) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                }
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.border.withOpacity(0.5))),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: user.role == 'driver' ? Colors.teal.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      child: Icon(user.role == 'driver' ? Icons.directions_car_rounded : Icons.person_rounded, 
                        color: user.role == 'driver' ? Colors.teal : Colors.blue),
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(user.phone.isEmpty ? 'No phone' : user.phone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () => _showUserDetails(user),
                  ),
                );
              },
            ),
          ),
        ),
      ],
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
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }
}
