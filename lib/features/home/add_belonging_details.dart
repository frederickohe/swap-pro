import 'dart:io';

import 'package:swappro/barrel.dart';

/// Add belonging flow — step 3 item details (Figma "Add 3", node 194:424).
class AddBelongingDetailsPage extends StatefulWidget {
  final String itemCategory;
  final String? incomingCategory;
  final File specLabelImage;

  const AddBelongingDetailsPage({
    super.key,
    required this.itemCategory,
    this.incomingCategory,
    required this.specLabelImage,
  });

  @override
  State<AddBelongingDetailsPage> createState() => _AddBelongingDetailsPageState();
}

class _AddBelongingDetailsPageState extends State<AddBelongingDetailsPage> {
  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBtnBg = Color(0xFFF5F4F8);
  static const Color _ink = Color(0xFF111111);
  static const double _figmaW = 428;

  static const List<String> _conditionOptions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor',
  ];

  /// ISO 4217 codes, alphabetical.
  static const List<String> _currencyOptions = [
    'AED',
    'AFN',
    'ALL',
    'AMD',
    'ANG',
    'AOA',
    'ARS',
    'AUD',
    'AWG',
    'AZN',
    'BAM',
    'BBD',
    'BDT',
    'BGN',
    'BHD',
    'BIF',
    'BMD',
    'BND',
    'BOB',
    'BRL',
    'BSD',
    'BTN',
    'BWP',
    'BYN',
    'BZD',
    'CAD',
    'CDF',
    'CHF',
    'CLP',
    'CNY',
    'COP',
    'CRC',
    'CUP',
    'CVE',
    'CZK',
    'DJF',
    'DKK',
    'DOP',
    'DZD',
    'EGP',
    'ERN',
    'ETB',
    'EUR',
    'FJD',
    'FKP',
    'GBP',
    'GEL',
    'GHS',
    'GIP',
    'GMD',
    'GNF',
    'GTQ',
    'GYD',
    'HKD',
    'HNL',
    'HTG',
    'HUF',
    'IDR',
    'ILS',
    'INR',
    'IQD',
    'IRR',
    'ISK',
    'JMD',
    'JOD',
    'JPY',
    'KES',
    'KGS',
    'KHR',
    'KMF',
    'KPW',
    'KRW',
    'KWD',
    'KYD',
    'KZT',
    'LAK',
    'LBP',
    'LKR',
    'LRD',
    'LSL',
    'LYD',
    'MAD',
    'MDL',
    'MGA',
    'MKD',
    'MMK',
    'MNT',
    'MOP',
    'MRU',
    'MUR',
    'MVR',
    'MWK',
    'MXN',
    'MYR',
    'MZN',
    'NAD',
    'NGN',
    'NIO',
    'NOK',
    'NPR',
    'NZD',
    'OMR',
    'PAB',
    'PEN',
    'PGK',
    'PHP',
    'PKR',
    'PLN',
    'PYG',
    'QAR',
    'RON',
    'RSD',
    'RUB',
    'RWF',
    'SAR',
    'SBD',
    'SCR',
    'SDG',
    'SEK',
    'SGD',
    'SHP',
    'SLE',
    'SOS',
    'SRD',
    'SSP',
    'STN',
    'SVC',
    'SYP',
    'SZL',
    'THB',
    'TJS',
    'TMT',
    'TND',
    'TOP',
    'TRY',
    'TTD',
    'TWD',
    'TZS',
    'UAH',
    'UGX',
    'USD',
    'UYU',
    'UZS',
    'VES',
    'VND',
    'VUV',
    'WST',
    'XAF',
    'XCD',
    'XOF',
    'XPF',
    'YER',
    'ZAR',
    'ZMW',
    'ZWG',
  ];

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _buildVersionController = TextEditingController();
  final _priceController = TextEditingController();

  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _serialNumberFocus = FocusNode();
  final _buildVersionFocus = FocusNode();
  final _priceFocus = FocusNode();

  String? _condition;
  String _currency = 'GHS';
  bool _ownershipDocumentsAvailable = false;
  double? _locationLat;
  double? _locationLng;
  String? _locationAreaLabel;
  final _geocoding = GeocodingService();
  final List<String> _extraWishDescriptions = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _serialNumberController.dispose();
    _buildVersionController.dispose();
    _priceController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _serialNumberFocus.dispose();
    _buildVersionFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  bool get _canProceed {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.length < 3) return false;
    if (description.length < 10) return false;
    if (_condition == null || _condition!.isEmpty) return false;
    if (_parsePrice(_priceController.text.trim()) == null) return false;
    if (_locationLat == null || _locationLng == null) return false;
    return true;
  }

  List<Map<String, dynamic>> _buildWishlistPayload() {
    final items = <Map<String, dynamic>>[];
    final incoming = widget.incomingCategory?.trim();
    if (incoming != null && incoming.isNotEmpty) {
      items.add({'category': incoming});
    }
    for (final wish in _extraWishDescriptions) {
      final trimmed = wish.trim();
      if (trimmed.isNotEmpty) {
        items.add({'description': trimmed});
      }
    }
    return items;
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<BelongingLocationPick>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBelongingLocationPickerPage(
          initialLatitude: _locationLat,
          initialLongitude: _locationLng,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _locationLat = result.latitude;
      _locationLng = result.longitude;
      _locationAreaLabel = null;
    });
    final area = await _geocoding.reverseGeocodeArea(
      latitude: result.latitude,
      longitude: result.longitude,
    );
    if (!mounted) return;
    setState(() => _locationAreaLabel = area);
  }

  Future<void> _addWish() async {
    final wish = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const AddWishPage()),
    );
    if (wish == null || wish.trim().isEmpty || !mounted) return;
    setState(() => _extraWishDescriptions.add(wish.trim()));
  }

  double? _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  void _goToPhotosStep() {
    if (!_canProceed) return;

    final price = _parsePrice(_priceController.text.trim());
    if (price == null || price <= 0) {
      context.showAppSnackBar('Enter a valid estimated value');
      return;
    }

    if (_locationLat == null || _locationLng == null) {
      context.showAppSnackBar('Pick a location on the map');
      return;
    }

    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        child: AddBelongingPhotosPage(
          itemCategory: widget.itemCategory,
          specLabelImage: widget.specLabelImage,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          condition: _condition!,
          estimatedValue: price,
          serialNumber: _serialNumberController.text.trim(),
          buildVersion: _buildVersionController.text.trim(),
          ownershipDocumentsAvailable: _ownershipDocumentsAvailable,
          wishlist: _buildWishlistPayload(),
          locationLat: _locationLat!,
          locationLng: _locationLng!,
          locationArea: _locationAreaLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wScale = MediaQuery.sizeOf(context).width / _figmaW;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(15 * wScale, 8 * wScale, 15 * wScale, 0),
              child: _buildHeader(wScale),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(26 * wScale, 48 * wScale, 26 * wScale, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Now describe the details of your belonging',
                      style: AppTypography.style(
                        fontSize: 28 * wScale,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 44 * wScale),
                    _BelongingFormField(
                      controller: _titleController,
                      focusNode: _titleFocus,
                      hint: 'Title',
                      height: 70 * wScale,
                      radius: 10 * wScale,
                      showBorder: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: 30 * wScale),
                    _BelongingFormField(
                      controller: _descriptionController,
                      focusNode: _descriptionFocus,
                      hint: 'Description',
                      height: 140 * wScale,
                      radius: 10 * wScale,
                      maxLines: 5,
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: 30 * wScale),
                    _BelongingFormField(
                      controller: _serialNumberController,
                      focusNode: _serialNumberFocus,
                      hint: 'Serial number (optional)',
                      height: 70 * wScale,
                      radius: 10 * wScale,
                    ),
                    SizedBox(height: 30 * wScale),
                    _BelongingFormField(
                      controller: _buildVersionController,
                      focusNode: _buildVersionFocus,
                      hint: 'Build version (optional)',
                      height: 70 * wScale,
                      radius: 10 * wScale,
                    ),
                    SizedBox(height: 30 * wScale),
                    _BelongingDropdownField(
                      hint: 'Condition',
                      value: _condition,
                      options: _conditionOptions,
                      height: 70 * wScale,
                      radius: 10 * wScale,
                      onChanged: (value) => setState(() => _condition = value),
                    ),
                    SizedBox(height: 30 * wScale),
                    _OwnershipDocumentsRow(
                      value: _ownershipDocumentsAvailable,
                      onChanged: (v) =>
                          setState(() => _ownershipDocumentsAvailable = v),
                    ),
                    SizedBox(height: 30 * wScale),
                    _LabeledField(
                      label: 'Estimated value',
                      child: _PriceWithCurrencyField(
                        controller: _priceController,
                        focusNode: _priceFocus,
                        currency: _currency,
                        currencies: _currencyOptions,
                        height: 70 * wScale,
                        radius: 10 * wScale,
                        onCurrencyChanged: (value) {
                          if (value != null) {
                            setState(() => _currency = value);
                          }
                        },
                        onAmountChanged: (_) => setState(() {}),
                      ),
                    ),
                    SizedBox(height: 30 * wScale),
                    _LabeledField(
                      label: 'Location',
                      child: _LocationPickerField(
                        hasLocation:
                            _locationLat != null && _locationLng != null,
                        areaLabel: _locationAreaLabel,
                        onTap: _pickLocation,
                      ),
                    ),
                    if (widget.incomingCategory != null &&
                        widget.incomingCategory!.isNotEmpty) ...[
                      SizedBox(height: 30 * wScale),
                      _LabeledField(
                        label: 'Swap wish (from earlier)',
                        child: _WishlistChipRow(
                          labels: [widget.incomingCategory!],
                        ),
                      ),
                    ],
                    if (_extraWishDescriptions.isNotEmpty) ...[
                      SizedBox(height: 20 * wScale),
                      _WishlistChipRow(
                        labels: _extraWishDescriptions,
                        onRemove: (index) => setState(
                          () => _extraWishDescriptions.removeAt(index),
                        ),
                      ),
                    ],
                    SizedBox(height: 16 * wScale),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _addWish,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add wishlist item'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF111111),
                        ),
                      ),
                    ),
                    SizedBox(height: 24 * wScale),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                39 * wScale,
                16 * wScale,
                39 * wScale,
                16 + bottomInset,
              ),
              child: _buildNextButton(wScale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double wScale) {
    return SizedBox(
      height: 50 * wScale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 50 * wScale,
                height: 50 * wScale,
                decoration: const BoxDecoration(
                  color: _backBtnBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18 * wScale,
                  color: _gold,
                ),
              ),
            ),
          ),
          Text(
            'Add Belonging',
            style: AppTypography.style(
              fontSize: 20 * wScale,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton(double wScale) {
    final enabled = _canProceed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? _goToPhotosStep : null,
        borderRadius: BorderRadius.circular(15 * wScale),
        child: Ink(
          height: 48 * wScale,
          width: double.infinity,
          decoration: BoxDecoration(
            color: enabled ? _ink : _ink.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(15 * wScale),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                offset: Offset(0, 4 * wScale),
                blurRadius: 4 * wScale,
              ),
            ],
          ),
          child: Center(
            child: Text(
              'Next',
              style: AppTypography.style(
                fontSize: 18 * wScale,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.style(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

class _BelongingFormField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final double height;
  final double radius;
  final bool showBorder;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const _BelongingFormField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.height,
    required this.radius,
    this.showBorder = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  });

  @override
  State<_BelongingFormField> createState() => _BelongingFormFieldState();
}

class _BelongingFormFieldState extends State<_BelongingFormField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    _focused = widget.focusNode.hasFocus;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    final focused = widget.focusNode.hasFocus;
    if (focused != _focused) setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    final showBorder = widget.showBorder || _focused;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F8),
        borderRadius: BorderRadius.circular(widget.radius),
        border: showBorder
            ? Border.all(color: const Color(0xFF111111), width: 0.8)
            : null,
      ),
      alignment: widget.maxLines > 1 ? Alignment.topLeft : Alignment.centerLeft,
      padding: EdgeInsets.fromLTRB(16, widget.maxLines > 1 ? 20 : 0, 16, 0),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        onChanged: widget.onChanged,
        style: AppTypography.style(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF111111),
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTypography.style(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF111111),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _PriceWithCurrencyField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String currency;
  final List<String> currencies;
  final double height;
  final double radius;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<String> onAmountChanged;

  const _PriceWithCurrencyField({
    required this.controller,
    required this.focusNode,
    required this.currency,
    required this.currencies,
    required this.height,
    required this.radius,
    required this.onCurrencyChanged,
    required this.onAmountChanged,
  });

  @override
  State<_PriceWithCurrencyField> createState() =>
      _PriceWithCurrencyFieldState();
}

class _PriceWithCurrencyFieldState extends State<_PriceWithCurrencyField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    _focused = widget.focusNode.hasFocus;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    final focused = widget.focusNode.hasFocus;
    if (focused != _focused) setState(() => _focused = focused);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F8),
        borderRadius: BorderRadius.circular(widget.radius),
        border: _focused
            ? Border.all(color: const Color(0xFF111111), width: 0.8)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.currency,
                isExpanded: true,
                padding: const EdgeInsets.only(left: 12, right: 4),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF111111),
                  size: 22,
                ),
                items: widget.currencies
                    .map(
                      (code) => DropdownMenuItem<String>(
                        value: code,
                        child: Text(
                          code,
                          style: AppTypography.style(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF111111),
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: widget.onCurrencyChanged,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFF111111).withValues(alpha: 0.15),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: widget.onAmountChanged,
                style: AppTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF111111),
                ),
                decoration: InputDecoration(
                  hintText: 'Enter estimated value',
                  hintStyle: AppTypography.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF111111),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnershipDocumentsRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OwnershipDocumentsRow({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F4F8),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ownership documents available',
                  style: AppTypography.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
              SettingsToggleSwitch(
                value: value,
                enabled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationPickerField extends StatelessWidget {
  final bool hasLocation;
  final String? areaLabel;
  final VoidCallback onTap;

  const _LocationPickerField({
    required this.hasLocation,
    required this.areaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = () {
      if (!hasLocation) return 'Tap to pick location on map';
      if (areaLabel != null && areaLabel!.trim().isNotEmpty) {
        return areaLabel!.trim();
      }
      return 'Location selected';
    }();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F4F8),
          borderRadius: BorderRadius.circular(10),
          border: hasLocation
              ? Border.all(color: const Color(0xFF111111), width: 0.8)
              : null,
        ),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, color: Color(0xFF111111)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF111111),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF111111)),
          ],
        ),
      ),
    );
  }
}

class _WishlistChipRow extends StatelessWidget {
  final List<String> labels;
  final void Function(int index)? onRemove;

  const _WishlistChipRow({required this.labels, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < labels.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  labels[i],
                  style: AppTypography.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                if (onRemove != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => onRemove!(i),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _BelongingDropdownField extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> options;
  final double height;
  final double radius;
  final ValueChanged<String?> onChanged;

  const _BelongingDropdownField({
    required this.hint,
    required this.value,
    required this.options,
    required this.height,
    required this.radius,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F8),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: AppTypography.style(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF111111),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF111111)),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    style: AppTypography.style(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF111111),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
