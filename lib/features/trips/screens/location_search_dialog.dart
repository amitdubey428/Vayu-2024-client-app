import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vayu_flutter_app/core/di/service_locator.dart';
import 'package:vayu_flutter_app/services/trip_service.dart';
import 'dart:developer' as developer;

import 'package:vayu_flutter_app/shared/widgets/snackbar_util.dart';

class LocationSearchDialog extends StatefulWidget {
  final String? initialQuery;
  final LatLng? initialLocation;

  const LocationSearchDialog(
      {super.key, this.initialQuery, this.initialLocation});

  @override
  State<LocationSearchDialog> createState() => _LocationSearchDialogState();
}

class _LocationSearchDialogState extends State<LocationSearchDialog> {
  final TripService _tripService = getIt<TripService>();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  Timer? _debounce;
  bool _hasSearchText = false;
  Map<String, dynamic>? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery ?? '';
    _selectedLocation = widget.initialLocation;
    if (widget.initialQuery != null) {
      _searchPlaces(widget.initialQuery!);
    }
    if (_selectedLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedLocation!,
      ));
    }
    _getUserLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition();
      _updateMapLocation(LatLng(position.latitude, position.longitude));
    } catch (e) {
      developer.log('Error getting user location: $e', error: e);
      // Fallback to a default location (e.g., New Delhi, India)
      _updateMapLocation(const LatLng(28.6139, 77.2090));
    }
  }

  void _updateMapLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedLocation!,
      ));
    });
    _mapController
        ?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15));
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      setState(() => _hasSearchText = true);
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 1000), () {
        _searchPlaces(_searchController.text);
      });
    } else {
      setState(() => _hasSearchText = false);
    }
  }

  void _searchPlaces(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
    });
    try {
      _searchResults = await _tripService.searchLocations(query);
      if (_searchResults.isNotEmpty) {
        _selectLocation(_searchResults.first);
      }
    } catch (e) {
      developer.log('Error searching for locations: $e', error: e);
      SnackbarUtil.showSnackbar('Error searching for locations',
          type: SnackbarType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectLocation(Map<String, dynamic> place) {
    setState(() {
      _selectedLocation = LatLng(
        place['geometry']['location']['lat'],
        place['geometry']['location']['lng'],
      );
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedLocation!,
      ));
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(_selectedLocation!, 15));

      // Store all necessary data
      _selectedPlace = {
        'name': place['name'],
        'formatted_address': place['formatted_address'],
        'place_id': place['place_id'],
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final mapHeight = screenHeight * 0.6;
    return AlertDialog(
      title: const Text('Search Location'),
      content: SizedBox(
        width: double.maxFinite,
        height: mapHeight,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a place',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search,
                      color: _hasSearchText
                          ? Theme.of(context).primaryColor
                          : Colors.grey),
                  onPressed: () => _searchPlaces(_searchController.text),
                ),
              ),
              onSubmitted: _searchPlaces,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation ??
                          const LatLng(28.6139,
                              77.2090), // Default to New Delhi if no location
                      zoom: 15,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: _markers,
                    onTap: (LatLng location) {
                      _updateMapLocation(location);
                    },
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_searchResults.isNotEmpty)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.white,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final place = _searchResults[index];
                            return ListTile(
                              title: Text(place['name']),
                              subtitle: Text(place['formatted_address']),
                              onTap: () {
                                _selectLocation(place);
                                _searchController.text = place['name'];
                              },
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          onPressed: _selectedPlace == null
              ? null
              : () {
                  Navigator.of(context).pop(_selectedPlace);
                },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
