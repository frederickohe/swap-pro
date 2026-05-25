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

  static const List<String> _quantityOptions = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '10+',
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
  final _manufacturerController = TextEditingController();
  final _priceController = TextEditingController();

  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _manufacturerFocus = FocusNode();
  final _priceFocus = FocusNode();

  String? _condition;
  String? _quantity;
  String _currency = 'GHS';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _manufacturerController.dispose();
    _priceController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _manufacturerFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_titleController.text.trim().isEmpty) return false;
    if (_descriptionController.text.trim().isEmpty) return false;
    if (_condition == null || _condition!.isEmpty) return false;
    if (_quantity == null || _quantity!.isEmpty) return false;
    if (_priceController.text.trim().isEmpty) return false;
    return true;
  }

  double? _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  void _goToPhotosStep() {
    if (!_canProceed) return;

    final price = _parsePrice(_priceController.text.trim());
    if (price == null || price <= 0) {
      context.showAppSnackBar('Enter a valid price');
      return;
    }

    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        child: AddBelongingPhotosPage(
          itemCategory: widget.itemCategory,
          incomingCategory: widget.incomingCategory,
          specLabelImage: widget.specLabelImage,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          manufacturer: _manufacturerController.text.trim(),
          condition: _condition!,
          quantity: _quantity!,
          currency: _currency,
          priceText: _priceController.text.trim(),
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
                      controller: _manufacturerController,
                      focusNode: _manufacturerFocus,
                      hint: 'Manufacturer',
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
                    _LabeledField(
                      label: 'Number available for swap',
                      child: _BelongingDropdownField(
                        hint: 'Select quantity',
                        value: _quantity,
                        options: _quantityOptions,
                        height: 70 * wScale,
                        radius: 10 * wScale,
                        onChanged: (value) => setState(() => _quantity = value),
                      ),
                    ),
                    SizedBox(height: 30 * wScale),
                    _LabeledField(
                      label: 'Price',
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
                  hintText: 'Enter swap price',
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
