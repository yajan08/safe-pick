import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../data/school_model.dart';
import '../data/school_service.dart';
import 'admin_dashboard_screen.dart' show kAdminNavy;
import 'admin_edit_school_screen.dart';

class AdminSchoolsScreen extends ConsumerStatefulWidget {
  const AdminSchoolsScreen({super.key});

  @override
  ConsumerState<AdminSchoolsScreen> createState() => _AdminSchoolsScreenState();
}

class _AdminSchoolsScreenState extends ConsumerState<AdminSchoolsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final schoolsAsync = ref.watch(allSchoolsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        foregroundColor: kAdminNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Manage Schools',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.5,
            color: kAdminNavy,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AdminEditSchoolScreen()),
          );
        },
        backgroundColor: kAdminNavy,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add School', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Search schools...',
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
          
          Expanded(
            child: schoolsAsync.when(
              data: (allSchools) {
                final schools = allSchools.where((s) => s.name.toLowerCase().contains(_searchQuery)).toList();
                
                if (schools.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.school_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No schools match your search.' : 'No schools added yet.',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 80), // Padding for FAB
                  itemCount: schools.length,
                  itemBuilder: (context, index) {
                    final school = schools[index];
                    return _SchoolCard(school: school)
                        .animate()
                        .fade(delay: Duration(milliseconds: 25 * index.clamp(0, 10)))
                        .slideX(begin: 0.02);
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
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  final SchoolModel school;
  
  const _SchoolCard({required this.school});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInactive = !school.isActive;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AdminEditSchoolScreen(school: school)),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isInactive ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kAdminNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: kAdminNavy, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${school.location.latitude.toStringAsFixed(4)}, ${school.location.longitude.toStringAsFixed(4)}',
                            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                          ),
                          if (isInactive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'INACTIVE',
                                style: TextStyle(color: AppTheme.errorRed, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
