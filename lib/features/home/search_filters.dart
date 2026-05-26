import 'package:swappro/barrel.dart';

/// Figma "Filters" frame (node 162:2029) — search & filter properties.
class SearchFiltersPage extends StatefulWidget {
  const SearchFiltersPage({super.key});

  @override
  State<SearchFiltersPage> createState() => _SearchFiltersPageState();
}

class SearchFiltersResult {
  const SearchFiltersResult({
    required this.propertyType,
    required this.minPrice,
    required this.maxPrice,
    required this.currency,
    required this.location,
  });

  final String propertyType;
  final double minPrice;
  final double maxPrice;
  final String currency;
  final String location;
}

class _SearchFiltersPageState extends State<SearchFiltersPage> {
  static const Color _ink = Color(0xFF111111);
  static const Color _gold = Color(0xFFC3B649);
  static const Color _chipInactive = Color(0xFFF5F4F8);
  static const Color _trackInactive = Color(0xFFEEEEEE);

  static const double _minPriceBound = 0;
  static const double _maxPriceBound = 1000;

  static const _propertyTypes = ['All', 'New', 'Used', 'Swap'];
  static const _currencies = ['\$ USD', '₵ GHS', '€ EUR'];

  int _selectedTypeIndex = 0;
  RangeValues _priceRange = const RangeValues(120, 680);
  String _currency = _currencies.first;
  final TextEditingController _locationController = TextEditingController();

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
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

  String _formatPrice(double value) {
    return '\$${value.round()}';
  }

  void _apply() {
    Navigator.pop(
      context,
      SearchFiltersResult(
        propertyType: _propertyTypes[_selectedTypeIndex],
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
        currency: _currency,
        location: _locationController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    _buildPropertyTypeSection(),
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

  Widget _buildPropertyTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Property Type',
          style: _textStyle(size: 18, weight: FontWeight.w600),
        ),
        const SizedBox(height: 26),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < _propertyTypes.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                _CategoryChip(
                  label: _propertyTypes[i],
                  selected: _selectedTypeIndex == i,
                  onTap: () => setState(() => _selectedTypeIndex = i),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Price', style: _textStyle(size: 18, weight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${_formatPrice(_priceRange.start)} - ${_formatPrice(_priceRange.end)}',
              style: _textStyle(
                size: 16,
                weight: FontWeight.w500,
                color: _gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: _CurrencyPicker(
            value: _currency,
            options: _currencies,
            onChanged: (v) => setState(() => _currency = v),
          ),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 9,
              elevation: 0,
              pressedElevation: 0,
            ),
            overlayShape: SliderComponentShape.noOverlay,
            inactiveTrackColor: _trackInactive,
            activeTrackColor: _gold,
            thumbColor: Colors.white,
          ),
          child: RangeSlider(
            values: _priceRange,
            min: _minPriceBound,
            max: _maxPriceBound,
            onChanged: (values) => setState(() => _priceRange = values),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location', style: _textStyle(size: 18, weight: FontWeight.w600)),
        const SizedBox(height: 33),
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
                  style: _textStyle(size: 14, weight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'Location',
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
            ],
          ),
        ),
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

class _CurrencyPicker extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _CurrencyPicker({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  static const Color _ink = Color(0xFF111111);
  static const Color _currencyBg = Color(0xFFF5F4F8);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) => options
          .map(
            (c) => PopupMenuItem<String>(
              value: c,
              child: Text(
                c,
                style: AppTypography.style(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _currencyBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.keyboard_arrow_down, size: 16, color: _ink),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.style(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
