import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:swappro/barrel.dart';
import 'package:swappro/utils/phone_utils.dart';
import 'package:url_launcher/url_launcher.dart';

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
  var _completing = false;
  Map<String, dynamic>? _details;

  bool get _isCompleted {
    final status = (_details?['swap_status'] ?? '').toString().trim();
    return status == 'COMPLETED';
  }

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
      });
      _fitMapToMarkers();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      await ApiErrorHandler.handle(context, e, onRetry: _load);
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

  Future<void> _callReceiver(String phone) async {
    final normalized = normalizePhone(phone);
    if (normalized.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: normalized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!mounted) return;
    context.showAppSnackBar('Could not start a phone call');
  }

  Future<void> _completeSwap() async {
    if (_completing || _isCompleted) return;
    setState(() => _completing = true);
    try {
      await context
          .read<ApiService>()
          .completeSwapRequest(widget.swapRequestId);
      if (!mounted) return;
      context.showAppSnackBar(
        'Swap marked as completed.',
        variant: AppSnackBarVariant.success,
      );
      Navigator.of(context).pop(SwapBayTab.history);
    } catch (e) {
      if (!mounted) return;
      setState(() => _completing = false);
      if (ApiErrorHandler.isSessionExpired(e)) {
        context.read<AuthBloc>().add(const SessionExpiredEvent());
        return;
      }
      context.showAppSnackBar('Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
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
                      : _buildDetailsSection(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Expanded(child: _buildMapSection()),
          if (!_loading && _details != null) _buildCompleteButton(),
        ],
      ),
    );
  }

  Widget _buildCompleteButton() {
    final completed = _isCompleted;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: completed || _completing ? null : _completeSwap,
            style: FilledButton.styleFrom(
              backgroundColor: _accentGreen,
              disabledBackgroundColor: _accentGreen.withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _completing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    completed ? 'Swap Completed' : 'Mark Swap Complete',
                    style: AppTypography.style(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
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
        if (name.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.style(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 20 / 16,
                  ),
                ),
              ),
            ],
          ),
        if (phone.isNotEmpty) ...[
          SizedBox(height: name.isNotEmpty ? 10 : 0),
          _detailRow(
            label: 'Phone',
            value: phone,
            prominent: true,
            trailing: _callButton(phone),
          ),
        ],
        if (email.isNotEmpty) ...[
          const SizedBox(height: 8),
          _detailRow(label: 'Email', value: email, prominent: true),
        ],
        if (counterListing != null) ...[
          const SizedBox(height: 12),
          _detailRow(
            label: 'Their item',
            value: (counterListing['title'] ?? widget.propertyTitle ?? 'Listing')
                .toString(),
          ),
        ],
        if (yourListing != null) ...[
          const SizedBox(height: 8),
          _detailRow(
            label: 'Your item',
            value: (yourListing['title'] ?? 'Your listing').toString(),
          ),
        ],
        if (hubName.isNotEmpty) ...[
          const SizedBox(height: 12),
          _detailRow(label: 'Swap hub', value: hubName),
        ],
      ],
    );
  }

  Widget _callButton(String phone) {
    const side = 34.0;
    return Material(
      color: _gold.withValues(alpha: 0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _callReceiver(phone),
        child: Padding(
          padding: const EdgeInsets.all((side - 18) / 2),
          child: const Icon(Icons.call, size: 18, color: _accentGreen),
        ),
      ),
    );
  }

  Widget _detailRow({
    required String label,
    required String value,
    bool prominent = false,
    Widget? trailing,
  }) {
    final labelSize = prominent ? 13.0 : 12.5;
    final valueSize = prominent ? 13.0 : 12.5;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: AppTypography.style(
              fontSize: labelSize,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
              height: 16 / labelSize,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.style(
              fontSize: valueSize,
              fontWeight: FontWeight.w500,
              color: _accentGreen,
              height: 16 / valueSize,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing,
        ],
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
            userAgentPackageName: 'com.swappro.app',
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
