import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/listing_model.dart';
import '../../providers/listings_provider.dart';
import '../../theme/app_theme.dart';
import '../listings/listing_detail_screen.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});
  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  GoogleMapController? _mapCtrl;
  ListingModel? _selected;
  int _lastFittedCount = -1;

  static const _initial = CameraPosition(
    // Rwanda-wide default view.
    target: LatLng(-1.9403, 29.8739),
    zoom: 7.2,
  );

  bool _isInRwandaBounds(ListingModel l) {
    return l.latitude >= -2.9 &&
        l.latitude <= -1.0 &&
        l.longitude >= 28.8 &&
        l.longitude <= 30.95;
  }

  bool _hasValidCoordinates(ListingModel l) {
    return l.latitude >= -90 &&
        l.latitude <= 90 &&
        l.longitude >= -180 &&
        l.longitude <= 180;
  }

  List<ListingModel> _mapListings(List<ListingModel> listings) {
    return listings.where(_hasValidCoordinates).toList();
  }

  List<ListingModel> _focusListings(List<ListingModel> listings) {
    final rwanda = listings.where(_isInRwandaBounds).toList();
    return rwanda.isNotEmpty ? rwanda : listings;
  }

  Future<void> _recenterToUser() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Location permission is required to center map.')));
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      await _mapCtrl?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(pos.latitude, pos.longitude), zoom: 14)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Unable to access current location right now.')));
    }
  }

  Future<void> _fitToListings(List<ListingModel> listings) async {
    final ctrl = _mapCtrl;
    if (ctrl == null || listings.isEmpty) return;

    if (_lastFittedCount == listings.length) return;
    _lastFittedCount = listings.length;

    if (listings.length == 1) {
      final l = listings.first;
      await ctrl.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(l.latitude, l.longitude), zoom: 14),
        ),
      );
      return;
    }

    double minLat = listings.first.latitude;
    double maxLat = listings.first.latitude;
    double minLng = listings.first.longitude;
    double maxLng = listings.first.longitude;

    for (final l in listings.skip(1)) {
      if (l.latitude < minLat) minLat = l.latitude;
      if (l.latitude > maxLat) maxLat = l.latitude;
      if (l.longitude < minLng) minLng = l.longitude;
      if (l.longitude > maxLng) maxLng = l.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    await ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 64));
  }

  Set<Marker> _markers(List<ListingModel> listings) => listings
      .map(
        (l) => Marker(
          markerId: MarkerId(l.id),
          position: LatLng(l.latitude, l.longitude),
          infoWindow: InfoWindow(title: l.name, snippet: l.category),
          onTap: () => setState(() => _selected = l),
        ),
      )
      .toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map View'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_outlined),
            onPressed: _recenterToUser,
          ),
        ],
      ),
      body: Consumer<ListingsProvider>(
        builder: (_, provider, __) {
          final listings = _mapListings(provider.allListings);
          final focusListings = _focusListings(listings);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitToListings(focusListings);
          });

          return Stack(children: [
            GoogleMap(
              initialCameraPosition: _initial,
              markers: _markers(listings),
              onMapCreated: (c) {
                _mapCtrl = c;
                _fitToListings(focusListings);
              },
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              onTap: (_) => setState(() => _selected = null),
            ),

            // Count badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on,
                      color: AppTheme.accentGold, size: 16),
                  const SizedBox(width: 6),
                  Text('${listings.length} listings',
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),

            // Selected listing card
            if (_selected != null)
              Positioned(
                bottom: 32,
                left: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ListingDetailScreen(listing: _selected!))),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                      border: Border.all(
                          color: AppTheme.accentGold.withValues(alpha: 0.3)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: AppTheme.chipBackground,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                            child: Text(
                                AppConstants
                                        .categoryIcons[_selected!.category] ??
                                    '📍',
                                style: const TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selected!.name,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(_selected!.category,
                              style: const TextStyle(
                                  color: AppTheme.accentGold, fontSize: 12)),
                          Text(_selected!.address,
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      )),
                      Column(children: [
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: AppTheme.textSecondary, size: 18),
                          onPressed: () => setState(() => _selected = null),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 6),
                        const Icon(Icons.chevron_right,
                            color: AppTheme.accentGold, size: 20),
                      ]),
                    ]),
                  ),
                ),
              ),

            // Zoom buttons
            Positioned(
              right: 16,
              bottom: _selected != null ? 160 : 32,
              child: Column(children: [
                _ZoomBtn(Icons.add,
                    () => _mapCtrl?.animateCamera(CameraUpdate.zoomIn())),
                const SizedBox(height: 8),
                _ZoomBtn(Icons.remove,
                    () => _mapCtrl?.animateCamera(CameraUpdate.zoomOut())),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn(this.icon, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)
                ]),
            child: Icon(icon, color: AppTheme.textPrimary, size: 20)),
      );
}
