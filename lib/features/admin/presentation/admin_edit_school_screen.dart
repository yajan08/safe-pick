import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../data/school_model.dart';
import '../data/school_service.dart';
import 'admin_dashboard_screen.dart' show kAdminNavy;

class AdminEditSchoolScreen extends ConsumerStatefulWidget {
  final SchoolModel? school;

  const AdminEditSchoolScreen({super.key, this.school});

  @override
  ConsumerState<AdminEditSchoolScreen> createState() => _AdminEditSchoolScreenState();
}

class _AdminEditSchoolScreenState extends ConsumerState<AdminEditSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  
  bool _isActive = true;
  bool _isLoading = false;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  // Default to Pune, Maharashtra, India
  static const LatLng _defaultLocation = LatLng(18.5204, 73.8567);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.school?.name ?? '');
    _isActive = widget.school?.isActive ?? true;
    
    if (widget.school != null) {
      _selectedLocation = LatLng(
        widget.school!.location.latitude,
        widget.school!.location.longitude,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mapController?.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final client = HttpClient();
      final uri = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5');
      final request = await client.getUrl(uri);
      request.headers.add(HttpHeaders.userAgentHeader, 'SafePick/1.0 (contact@safepick.com)');
      
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = jsonDecode(responseBody);
        setState(() {
          _searchResults = data;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(dynamic result) {
    final double? lat = double.tryParse(result['lat'].toString());
    final double? lon = double.tryParse(result['lon'].toString());
    if (lat != null && lon != null) {
      final latLng = LatLng(lat, lon);
      setState(() {
        _selectedLocation = latLng;
        _searchResults = [];
      });
      _searchController.text = result['display_name'] ?? '';
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16.0));
    }
  }

  Future<void> _saveSchool() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map.'), backgroundColor: AppTheme.warningOrange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = ref.read(schoolServiceProvider);
      
      final school = SchoolModel(
        schoolId: widget.school?.schoolId ?? '', // Handled by service if empty
        name: _nameController.text.trim(),
        location: GeoPoint(_selectedLocation!.latitude, _selectedLocation!.longitude),
        isActive: _isActive,
      );

      if (widget.school == null) {
        await service.addSchool(school);
      } else {
        await service.updateSchool(school);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isEditing = widget.school != null;

    final initialCameraPosition = CameraPosition(
      target: _selectedLocation ?? _defaultLocation,
      zoom: 14.0,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        foregroundColor: kAdminNavy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          isEditing ? 'Edit School' : 'Add School',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.5,
            color: kAdminNavy,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kAdminNavy))
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Map Section
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: initialCameraPosition,
                          onMapCreated: (controller) => _mapController = controller,
                          onTap: _onMapTapped,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: false,
                          markers: _selectedLocation != null
                              ? {
                                  Marker(
                                    markerId: const MarkerId('school_location'),
                                    position: _selectedLocation!,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                                  ),
                                }
                              : {},
                        ),
                        
                        // Search bar at the top
                        Positioned(
                          top: 16, left: 16, right: 16,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: (val) {
                                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                                    _debounce = Timer(const Duration(milliseconds: 500), () {
                                      _searchLocation(val);
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Search school address or city...',
                                    hintStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.6), fontSize: 13),
                                    prefixIcon: const Icon(Icons.search_rounded, color: kAdminNavy, size: 20),
                                    suffixIcon: _isSearching
                                        ? const SizedBox(
                                            width: 20, height: 20,
                                            child: Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: CircularProgressIndicator(strokeWidth: 2, color: kAdminNavy),
                                            ),
                                          )
                                        : _searchController.text.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear_rounded, size: 18),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {
                                                    _searchResults = [];
                                                  });
                                                },
                                              )
                                            : null,
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                              if (_searchResults.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  constraints: const BoxConstraints(maxHeight: 200),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                                    ],
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _searchResults.length,
                                    separatorBuilder: (context, index) => Divider(color: AppTheme.border.withValues(alpha: 0.3), height: 1),
                                    itemBuilder: (context, index) {
                                      final result = _searchResults[index];
                                      return ListTile(
                                        title: Text(
                                          result['display_name'] ?? '',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        leading: const Icon(Icons.location_on_rounded, color: AppTheme.warningOrange, size: 18),
                                        onTap: () => _selectSearchResult(result),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Map overlay hint moved to bottom
                        Positioned(
                          bottom: 16, left: 16, right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.touch_app_rounded, color: kAdminNavy, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedLocation == null ? 'Tap anywhere on the map to place the school pin.' : 'Tap elsewhere to move the pin.',
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Section
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'School Name',
                                labelStyle: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                                prefixIcon: const Icon(Icons.school_outlined, color: kAdminNavy, size: 22),
                                filled: true,
                                fillColor: AppTheme.background,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.5))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.5))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAdminNavy, width: 1.5)),
                              ),
                              validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a school name' : null,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            SwitchListTile(
                              value: _isActive,
                              onChanged: (val) => setState(() => _isActive = val),
                              title: const Text('Active School', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              subtitle: const Text('Allow parents to select this school.', style: TextStyle(fontSize: 12)),
                              activeThumbColor: kAdminNavy,
                              contentPadding: EdgeInsets.zero,
                            ),
                            
                            const SizedBox(height: 32),
                            
                            ElevatedButton(
                              onPressed: _saveSchool,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAdminNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: Text(
                                isEditing ? 'Save Changes' : 'Create School',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
