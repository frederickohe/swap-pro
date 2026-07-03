import 'dart:math' as math;

import 'package:swappro/barrel.dart';

/// Figma "Filters" frame (node 162:2029) — search & filter properties.
class SearchFiltersPage extends StatefulWidget {
  const SearchFiltersPage({super.key});

  @override
  State<SearchFiltersPage> createState() => _SearchFiltersPageState();
}

class SearchFiltersResult {
  const SearchFiltersResult({
    this.condition,
    this.category,
    required this.minPrice,
    required this.maxPrice,
    required this.location,
    this.locationLat,
    this.locationLng,
    this.locationRadiusKm = 25,
  });

  /// `null` when "All" is selected.
  final String? condition;
  /// `null` when "All" is selected.
  final String? category;
  final double minPrice;
  final double maxPrice;
  final String location;
  final double? locationLat;
  final double? locationLng;
  final double locationRadiusKm;

  /// Client-side filter for a listing map (e.g. on "Your listings").
  bool matchesListing(
    Map<String, dynamic> listing, {
    String keyword = '',
  }) {
    final q = keyword.trim().toLowerCase();
    if (q.isNotEmpty) {
      final title = (listing['title'] ?? '').toString().toLowerCase();
      final categoryText = (listing['category'] ?? '').toString().toLowerCase();
      final conditionText = (listing['condition'] ?? '').toString().toLowerCase();
      final priceText = (listing['estimated_value']?.toString() ?? '').toLowerCase();
      if (!title.contains(q) &&
          !categoryText.contains(q) &&
          !conditionText.contains(q) &&
          !priceText.contains(q)) {
        return false;
      }
    }

    if (category != null) {
      final listingCategory = (listing['category'] ?? '').toString().trim();
      if (listingCategory != category) return false;
    }

    if (condition != null) {
      final listingCondition = (listing['condition'] ?? '').toString().trim();
      if (listingCondition != condition) return false;
    }

    if (minPrice > 0 || maxPrice > 0) {
      final value = listing['estimated_value'];
      double? price;
      if (value is num) {
        price = value.toDouble();
      } else if (value != null) {
        price = double.tryParse(
          value.toString().replaceAll(RegExp(r'[^0-9.]'), ''),
        );
      }
      if (price == null) return false;
      if (minPrice > 0 && price < minPrice) return false;
      if (maxPrice > 0 && price > maxPrice) return false;
    }

    final locationText = location.trim();
    if (locationText.isNotEmpty || (locationLat != null && locationLng != null)) {
      if (locationLat != null && locationLng != null) {
        final lat = listing['location_lat'];
        final lng = listing['location_lng'];
        if (lat is! num || lng is! num) return false;
        final dist = _haversineKm(
          locationLat!,
          locationLng!,
          lat.toDouble(),
          lng.toDouble(),
        );
        if (dist > locationRadiusKm) return false;
      } else if (!listingDisplayLocation(listing)
          .toLowerCase()
          .contains(locationText.toLowerCase())) {
        return false;
      }
    }

    return true;
  }
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _degToRad(lat2 - lat1);
  final dLon = _degToRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_degToRad(lat1)) *
          math.cos(_degToRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusKm * c;
}

double _degToRad(double deg) => deg * math.pi / 180;

class _SearchFiltersPageState extends State<SearchFiltersPage> {
  static const Color _ink = Color(0xFF111111);
  static const Color _gold = Color(0xFFC3B649);
  static const Color _chipInactive = Color(0xFFF5F4F8);
  static const Color _trackInactive = Color(0xFFEEEEEE);

  static const double _minPriceBound = 0;
  static const double _maxPriceBound = 5000000;

  static const _conditions = ['All', 'New', 'Like New', 'Good', 'Fair', 'Poor'];

  /// Matches [AddBelongingPage] item categories (add_belonging.dart).
  static const _categories = [
    'All',
    'Electronics',
    'Home & Kitchen',
    'kids',
    'Books',
    'Fashion',
    'Sports',
    'Tools',
    'Fitness',
    'Beauty Products',
    'Vehicles',
    'Vehicle Parts',
    'Personal Care',
    'Media',
    'Video Games',
  ];

  int _selectedConditionIndex = 0;
  int _selectedCategoryIndex = 0;
  RangeValues _priceRange = const RangeValues(0, 0);
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  bool _syncingPriceInputs = false;
  final TextEditingController _locationController = TextEditingController();
  final GeocodingService _geocoding = GeocodingService();
  Timer? _autocompleteDebounce;
  List<PlaceSuggestion> _suggestions = const [];
  bool _loadingSuggestions = false;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
      text: _priceRange.start.round().toString(),
    );
    _maxPriceController = TextEditingController(
      text: _priceRange.end.round().toString(),
    );
  }

  @override
  void dispose() {
    _autocompleteDebounce?.cancel();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _onLocationChanged(String value) {
    _selectedLat = null;
    _selectedLng = null;
    _autocompleteDebounce?.cancel();
    if (value.trim().length < 2 || !AppConfig.hasGeoapifyApiKey) {
      setState(() {
        _suggestions = const [];
        _loadingSuggestions = false;
      });
      return;
    }
    _autocompleteDebounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _loadingSuggestions = true);
      final results = await _geocoding.autocomplete(value);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loadingSuggestions = false;
      });
    });
  }

  void _selectSuggestion(PlaceSuggestion suggestion) {
    setState(() {
      _locationController.text = suggestion.label;
      _selectedLat = suggestion.latitude;
      _selectedLng = suggestion.longitude;
      _suggestions = const [];
    });
    FocusScope.of(context).unfocus();
  }

  TextStyle _textStyle({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _ink,
  }) {
    return AppTypography.style(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.2,
    );
  }

  double? _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  void _onMinPriceChanged(String value) {
    if (_syncingPriceInputs) return;
    final parsed = _parsePrice(value);
    if (parsed == null) return;
    final min = parsed.clamp(_minPriceBound, _maxPriceBound);
    var max = _priceRange.end;
    if (min > max) {
      max = min;
      _syncingPriceInputs = true;
      _maxPriceController.text = max.round().toString();
      _syncingPriceInputs = false;
    }
    setState(() => _priceRange = RangeValues(min, max));
  }

  void _onMaxPriceChanged(String value) {
    if (_syncingPriceInputs) return;
    final parsed = _parsePrice(value);
    if (parsed == null) return;
    final max = parsed.clamp(_minPriceBound, _maxPriceBound);
    var min = _priceRange.start;
    if (max < min) {
      min = max;
      _syncingPriceInputs = true;
      _minPriceController.text = min.round().toString();
      _syncingPriceInputs = false;
    }
    setState(() => _priceRange = RangeValues(min, max));
  }

  RangeValues _committedPriceRange() {
    final minParsed =
        _parsePrice(_minPriceController.text) ?? _priceRange.start;
    final maxParsed =
        _parsePrice(_maxPriceController.text) ?? _priceRange.end;
    final min = minParsed.clamp(_minPriceBound, _maxPriceBound);
    final max = maxParsed.clamp(_minPriceBound, _maxPriceBound);
    return RangeValues(min <= max ? min : max, min <= max ? max : min);
  }

  void _apply() {
    final range = _committedPriceRange();
    Navigator.pop(
      context,
      SearchFiltersResult(
        condition: _selectedConditionIndex == 0
            ? null
            : _conditions[_selectedConditionIndex],
        category: _selectedCategoryIndex == 0
            ? null
            : _categories[_selectedCategoryIndex],
        minPrice: range.start,
        maxPrice: range.end,
        location: _locationController.text.trim(),
        locationLat: _selectedLat,
        locationLng: _selectedLng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: _ink,
                  ),
                ),
              ),
            ),
            Text(
              'Search Properties',
              textAlign: TextAlign.center,
              style: _textStyle(size: 22, weight: FontWeight.w400),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildConditionSection(),
                    const SizedBox(height: 40),
                    _buildCategorySection(),
                    const SizedBox(height: 60),
                    _buildPriceSection(),
                    const SizedBox(height: 66),
                    _buildLocationSection(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(76, 0, 76, 36),
              child: _buildApplyButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipSection({
    required String title,
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _textStyle(size: 18, weight: FontWeight.w600)),
        const SizedBox(height: 26),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                _CategoryChip(
                  label: options[i],
                  selected: selectedIndex == i,
                  onTap: () => onSelected(i),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConditionSection() {
    return _buildChipSection(
      title: 'Condition',
      options: _conditions,
      selectedIndex: _selectedConditionIndex,
      onSelected: (i) => setState(() => _selectedConditionIndex = i),
    );
  }

  Widget _buildCategorySection() {
    return _buildChipSection(
      title: 'Category',
      options: _categories,
      selectedIndex: _selectedCategoryIndex,
      onSelected: (i) => setState(() => _selectedCategoryIndex = i),
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Price', style: _textStyle(size: 18, weight: FontWeight.w600)),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PriceBoundField(
              label: 'Minimum',
              controller: _minPriceController,
              onChanged: _onMinPriceChanged,
            ),
            const SizedBox(width: 12),
            _PriceBoundField(
              label: 'Maximum',
              controller: _maxPriceController,
              onChanged: _onMaxPriceChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: _textStyle(size: 18, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Search any city or neighbourhood worldwide',
          style: _textStyle(size: 12, color: _ink.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 20),
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: _chipInactive,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 24, color: _gold),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _locationController,
                  onChanged: _onLocationChanged,
                  style: _textStyle(size: 14, weight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'City, suburb, or area',
                    hintStyle: _textStyle(
                      size: 14,
                      weight: FontWeight.w500,
                      color: _ink.withValues(alpha: 0.6),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_loadingSuggestions)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _trackInactive),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _suggestions.length; i++)
                  InkWell(
                    onTap: () => _selectSuggestion(_suggestions[i]),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: i < _suggestions.length - 1
                            ? Border(
                                bottom: BorderSide(color: _trackInactive),
                              )
                            : null,
                      ),
                      child: Text(
                        _suggestions[i].label,
                        style: _textStyle(size: 13),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildApplyButton() {
    return SizedBox(
      height: 62,
      child: ElevatedButton(
        onPressed: _apply,
        style: ElevatedButton.styleFrom(
          backgroundColor: _ink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'View',
          style: _textStyle(
            size: 18,
            weight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _PriceBoundField extends StatelessWidget {
  static const _pricePrefix = 'GH₵ ';

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _PriceBoundField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  static const Color _ink = Color(0xFF111111);
  static const Color _chipInactive = Color(0xFFF5F4F8);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.style(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _ink.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: _chipInactive,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: AppTypography.style(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
              decoration: InputDecoration(
                prefixText: _pricePrefix,
                prefixStyle: AppTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
                hintText: '0',
                hintStyle: AppTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _ink.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color _ink = Color(0xFF111111);
  static const Color _gold = Color(0xFFC3B649);
  static const Color _chipInactive = Color(0xFFF5F4F8);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _gold : _chipInactive,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.style(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : _ink,
          ),
        ),
      ),
    );
  }
}
