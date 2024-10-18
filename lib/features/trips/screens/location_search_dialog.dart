import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vayu_flutter_app/blocs/location_search/location_search_bloc.dart';
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
  late LocationSearchBloc _locationSearchBloc;
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  final Set<Marker> _markers = {};
  Timer? _debounce;
  Map<String, dynamic>? _selectedPlace;

  @override
  void initState() {
    super.initState();
    _locationSearchBloc = LocationSearchBloc(getIt<TripService>());
    _searchController.text = widget.initialQuery ?? '';
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _markers.add(Marker(
        markerId: const MarkerId('selected_location'),
        position: _selectedLocation!,
      ));
    }
    _getUserLocation();
    _searchController.addListener(_onSearchChanged);
    if (widget.initialQuery != null) {
      _locationSearchBloc.add(SearchLocation(widget.initialQuery!));
    }
  }

  @override
  void dispose() {
    _locationSearchBloc.close();
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
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (_searchController.text.isNotEmpty) {
        _locationSearchBloc.add(SearchLocation(_searchController.text));
      }
    });
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
    return BlocProvider(
      create: (context) => _locationSearchBloc,
      child: AlertDialog(
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
                        color: _searchController.text.isNotEmpty
                            ? Theme.of(context).primaryColor
                            : Colors.grey),
                    onPressed: () => _locationSearchBloc
                        .add(SearchLocation(_searchController.text)),
                  ),
                ),
                onSubmitted: (value) =>
                    _locationSearchBloc.add(SearchLocation(value)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target:
                            _selectedLocation ?? const LatLng(28.6139, 77.2090),
                        zoom: 15,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      markers: _markers,
                      onTap: (LatLng location) {
                        _updateMapLocation(location);
                      },
                    ),
                    BlocBuilder<LocationSearchBloc, LocationSearchState>(
                      builder: (context, state) {
                        if (state is LocationSearchLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (state is LocationSearchLoaded) {
                          return Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              color: Colors.white,
                              constraints:
                                  BoxConstraints(maxHeight: mapHeight * 0.3),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: state.results.length,
                                itemBuilder: (context, index) {
                                  final place = state.results[index];
                                  return ListTile(
                                    leading: const Icon(Icons.location_on),
                                    title: Text(place['name'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    subtitle: Text(place['formatted_address'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    onTap: () {
                                      _selectLocation(place);
                                      _searchController.text = place['name'];
                                      _locationSearchBloc
                                          .add(ClearSearchResults());
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        } else if (state is LocationSearchError) {
                          SnackbarUtil.showSnackbar(state.message,
                              type: SnackbarType.error);
                        }
                        return const SizedBox.shrink();
                      },
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
                : () => Navigator.of(context).pop(_selectedPlace),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}
