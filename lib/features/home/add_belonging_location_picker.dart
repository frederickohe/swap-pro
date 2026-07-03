import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:swappro/barrel.dart';

/// Result from [AddBelongingLocationPickerPage].
class BelongingLocationPick {
  const BelongingLocationPick({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Geoapify map — tap to place a pin for listing location.
class AddBelongingLocationPickerPage extends StatefulWidget {
  const AddBelongingLocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<AddBelongingLocationPickerPage> createState() =>
      _AddBelongingLocationPickerPageState();
}

class _AddBelongingLocationPickerPageState
    extends State<AddBelongingLocationPickerPage> {
  static const LatLng _defaultCenter = LatLng(5.6037, -0.1870);

  final _mapController = MapController();
  LatLng? _selected;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selected = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _initialCenter => _selected ?? _defaultCenter;

  Future<void> _useCurrentLocation() async {
    if (!AppConfig.hasGeoapifyApiKey) {
      context.showAppSnackBar('Add GEOAPIFY_API_KEY to .env to use the map.');
      return;
    }

    setState(() => _loadingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        context.showAppSnackBar('Location permission is required.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _selected = latLng);
      _mapController.move(latLng, 15);
    } catch (_) {
      if (mounted) {
        context.showAppSnackBar(
          'Could not get your location. Tap the map instead.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selected = point);
  }

  void _confirm() {
    if (_selected == null) {
      context.showAppSnackBar('Tap the map to set your location');
      return;
    }
    Navigator.pop(
      context,
      BelongingLocationPick(
        latitude: _selected!.latitude,
        longitude: _selected!.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.hasGeoapifyApiKey) {
      return AppScaffold(
        appBar: AppBar(
          title: const Text('Pick location'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Geoapify is not configured.',
                style: AppTypography.style(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Add GEOAPIFY_API_KEY to swap-pro/.env with your Geoapify API key.',
                style: AppTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF111111),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final apiKey = AppConfig.geoapifyApiKey;

    return AppScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  Expanded(
                    child: Text(
                      'Point your belonging on the map',
                      style: AppTypography.style(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _initialCenter,
                      initialZoom: 14,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://maps.geoapify.com/v1/tile/osm-carto/{z}/{x}/{y}.png?apiKey={apiKey}',
                        additionalOptions: {'apiKey': apiKey},
                        userAgentPackageName: 'com.swappro.app',
                        maxZoom: 20,
                      ),
                      if (_selected != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selected!,
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.location_pin,
                                size: 44,
                                color: Color(0xFFC3B649),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Column(
                      children: [
                        _MapZoomButton(
                          icon: Icons.add,
                          onPressed: () {
                            final z = _mapController.camera.zoom;
                            _mapController.move(
                              _mapController.camera.center,
                              (z + 1).clamp(1, 20),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _MapZoomButton(
                          icon: Icons.remove,
                          onPressed: () {
                            final z = _mapController.camera.zoom;
                            _mapController.move(
                              _mapController.camera.center,
                              (z - 1).clamp(1, 20),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    left: 8,
                    bottom: 8,
                    child: _GeoapifyAttribution(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selected != null)
                    Text(
                      'Lat ${_selected!.latitude.toStringAsFixed(5)}, '
                      'Lng ${_selected!.longitude.toStringAsFixed(5)}',
                      textAlign: TextAlign.center,
                      style: AppTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _loadingLocation ? null : _useCurrentLocation,
                    icon: _loadingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_outlined),
                    label: const Text('Use my location'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111111),
                      side: const BorderSide(color: Color(0xFF111111)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF111111),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirm location'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapZoomButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 22, color: const Color(0xFF111111)),
        ),
      ),
    );
  }
}

/// Required attribution for Geoapify free tier.
class _GeoapifyAttribution extends StatelessWidget {
  const _GeoapifyAttribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          '© OpenStreetMap · Powered by Geoapify',
          style: AppTypography.style(
            fontSize: 9,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF111111),
          ),
        ),
      ),
    );
  }
}
