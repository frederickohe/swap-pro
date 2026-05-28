import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:swappro/barrel.dart';

/// Ready Swap — receiver details and listing locations on a map.
class GoForSwapPage extends StatefulWidget {
  const GoForSwapPage({
    super.key,
    required this.swapRequestId,
    this.propertyTitle,
  });

  final String swapRequestId;
  final String? propertyTitle;

  @override
  State<GoForSwapPage> createState() => _GoForSwapPageState();
}

class _GoForSwapPageState extends State<GoForSwapPage> {
  static const Color _gold = Color(0xFFC3B649);
  static const Color _accentGreen = Color(0xFF176B02);
  static const LatLng _defaultCenter = LatLng(5.6037, -0.1870);

  final _mapController = MapController();
  var _loading = true;
  String? _error;
  Map<String, dynamic>? _details;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await context
          .read<ApiService>()
          .getSwapMeetupDetails(widget.swapRequestId);
      if (!mounted) return;
      setState(() {
        _details = data;
        _loading = false;
        _error = null;
      });
      _fitMapToMarkers();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _fitMapToMarkers() {
    final points = _markerPoints();
    if (points.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || points.length == 1) {
        if (points.length == 1) {
          _mapController.move(points.first, 14);
        }
        return;
      }
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
      );
    });
  }

  List<LatLng> _markerPoints() {
    final points = <LatLng>[];
    final counter = _listingMap('counterparty_listing');
    final yours = _listingMap('your_listing');
    _addPoint(points, counter);
    _addPoint(points, yours);
    return points;
  }

  Map<String, dynamic>? _listingMap(String key) {
    final raw = _details?[key];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  void _addPoint(List<LatLng> points, Map<String, dynamic>? listing) {
    if (listing == null) return;
    final lat = listing['location_lat'];
    final lng = listing['location_lng'];
    if (lat is num && lng is num) {
      points.add(LatLng(lat.toDouble(), lng.toDouble()));
    }
  }

  Map<String, dynamic>? get _counterparty {
    final raw = _details?['counterparty'];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(15, 8, 15, 0),
                  child: AppScreenTopBar(title: 'Go For Swap'),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _loading
                      ? const Center(child: SwapproLoadingIndicator())
                      : _error != null
                          ? Text(
                              _error!,
                              style: AppTypography.style(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            )
                          : _buildDetailsSection(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Expanded(child: _buildMapSection()),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    final party = _counterparty;
    final name = (party?['fullname'] ?? '').toString().trim();
    final phone = (party?['phone'] ?? '').toString().trim();
    final email = (party?['email'] ?? '').toString().trim();
    final counterListing = _listingMap('counterparty_listing');
    final yourListing = _listingMap('your_listing');
    final hubName = (_details?['hub_name'] ?? '').toString().trim();
    final meeting = (_details?['meeting_time'] ?? '').toString().trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Receiver details',
          style: AppTypography.style(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        if (name.isNotEmpty) _detailRow(label: 'Name', value: name),
        if (phone.isNotEmpty) ...[
          const SizedBox(height: 10),
          _detailRow(label: 'Phone', value: phone),
        ],
        if (email.isNotEmpty) ...[
          const SizedBox(height: 10),
          _detailRow(label: 'Email', value: email),
        ],
        if (counterListing != null) ...[
          const SizedBox(height: 16),
          _detailRow(
            label: 'Their item',
            value: (counterListing['title'] ?? widget.propertyTitle ?? 'Listing')
                .toString(),
          ),
        ],
        if (yourListing != null) ...[
          const SizedBox(height: 10),
          _detailRow(
            label: 'Your item',
            value: (yourListing['title'] ?? 'Your listing').toString(),
          ),
        ],
        if (hubName.isNotEmpty) ...[
          const SizedBox(height: 16),
          _detailRow(label: 'Swap hub', value: hubName),
        ],
        if (meeting.isNotEmpty) ...[
          const SizedBox(height: 10),
          _detailRow(label: 'Meeting', value: meeting),
        ],
      ],
    );
  }

  Widget _detailRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.style(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 20 / 15,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.style(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _accentGreen,
              height: 18 / 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    if (!AppConfig.hasGeoapifyApiKey) {
      return _mapPlaceholder(message: 'Add GEOAPIFY_API_KEY to show the map.');
    }

    final markers = <Marker>[];
    final counter = _listingMap('counterparty_listing');
    final yours = _listingMap('your_listing');

    void addMarker(Map<String, dynamic>? listing, Color color, String label) {
      if (listing == null) return;
      final lat = listing['location_lat'];
      final lng = listing['location_lng'];
      if (lat is! num || lng is! num) return;
      markers.add(
        Marker(
          point: LatLng(lat.toDouble(), lng.toDouble()),
          width: 48,
          height: 48,
          child: Tooltip(
            message: label,
            child: Icon(Icons.location_pin, size: 44, color: color),
          ),
        ),
      );
    }

    addMarker(
      counter,
      _gold,
      (counter?['title'] ?? 'Receiver item').toString(),
    );
    addMarker(
      yours,
      _accentGreen,
      (yours?['title'] ?? 'Your item').toString(),
    );

    final center = _markerPoints().isNotEmpty
        ? _markerPoints().first
        : _defaultCenter;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: center, initialZoom: 13),
        children: [
          TileLayer(
            urlTemplate:
                'https://maps.geoapify.com/v1/tile/osm-carto/{z}/{x}/{y}.png?apiKey={apiKey}',
            additionalOptions: {'apiKey': AppConfig.geoapifyApiKey},
            userAgentPackageName: 'com.lambdar.swappro',
            maxZoom: 20,
          ),
          if (markers.isNotEmpty) MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  Widget _mapPlaceholder({required String message}) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8F4E6),
            Color(0xFFD4E8CF),
            Color(0xFFB8D4B0),
          ],
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTypography.style(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: _accentGreen,
        ),
      ),
    );
  }
}
