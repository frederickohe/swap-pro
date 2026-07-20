import 'dart:io';

import 'package:swappro/barrel.dart';
import 'package:swappro/common_design/widgets/success_reveal_route.dart';

/// Add belonging flow — step 5 optional add-on services.
class AddBelongingAddonsPage extends StatefulWidget {
  final String itemCategory;
  final File specLabelImage;
  final String title;
  final String description;
  final String condition;
  final double estimatedValue;
  final String serialNumber;
  final String buildVersion;
  final bool ownershipDocumentsAvailable;
  final List<Map<String, dynamic>> wishlist;
  final double locationLat;
  final double locationLng;
  final String? locationArea;
  final List<File> photos;

  const AddBelongingAddonsPage({
    super.key,
    required this.itemCategory,
    required this.specLabelImage,
    required this.title,
    required this.description,
    required this.condition,
    required this.estimatedValue,
    this.serialNumber = '',
    this.buildVersion = '',
    this.ownershipDocumentsAvailable = false,
    this.wishlist = const [],
    required this.locationLat,
    required this.locationLng,
    this.locationArea,
    required this.photos,
  });

  @override
  State<AddBelongingAddonsPage> createState() => _AddBelongingAddonsPageState();
}

class _AddBelongingAddonsPageState extends State<AddBelongingAddonsPage> {
  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBtnBg = Color(0xFFF5F4F8);
  static const Color _ink = Color(0xFF111111);
  static const Color _muted = Color(0xFF6B6B6B);
  static const Color _divider = Color(0xFFF0EFF4);

  /// Display prices (GHS) — must stay in sync with backend config defaults.
  static const double _wishFindingFee = 5;
  static const double _budgetNegotiationFee = 5;
  static const double _collectionAssistanceFee = 10;

  static const double _figmaW = 428;

  bool _wishFinding = false;
  bool _budgetNegotiation = false;
  bool _collectionAssistance = false;
  final TextEditingController _budgetController = TextEditingController();
  final FocusNode _budgetFocus = FocusNode();
  bool _submitting = false;

  @override
  void dispose() {
    _budgetController.dispose();
    _budgetFocus.dispose();
    super.dispose();
  }

  double get _addonTotal {
    var total = 0.0;
    if (_wishFinding) total += _wishFindingFee;
    if (_budgetNegotiation) total += _budgetNegotiationFee;
    if (_collectionAssistance) total += _collectionAssistanceFee;
    return total;
  }

  double? _parseBudget(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  Future<void> _submit() async {
    if (_submitting) return;

    double? budgetAmount;
    if (_budgetNegotiation) {
      budgetAmount = _parseBudget(_budgetController.text.trim());
      if (budgetAmount == null || budgetAmount <= 0) {
        context.showAppSnackBar(
          'Enter your maximum budget for Budget Negotiation',
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      final api = context.read<ApiService>();
      final specLabelUrl = await api.uploadFile(
        file: widget.specLabelImage,
        storageFolder: ApiService.listingsStorageFolder,
      );

      final galleryUrls = <String>[];
      for (final file in widget.photos) {
        galleryUrls.add(
          await api.uploadFile(
            file: file,
            storageFolder: ApiService.listingsStorageFolder,
          ),
        );
      }

      final primaryUrl = galleryUrls.first;
      final imageUrls = <String>[
        ...galleryUrls.skip(1),
        specLabelUrl,
      ];

      var locationArea = widget.locationArea?.trim();
      if (locationArea == null || locationArea.isEmpty) {
        locationArea = await GeocodingService().reverseGeocodeArea(
          latitude: widget.locationLat,
          longitude: widget.locationLng,
        );
      }

      await api.createBelongingListing(
        title: widget.title,
        description: widget.description,
        category: widget.itemCategory,
        condition: widget.condition,
        primaryImageUrl: primaryUrl,
        imageUrls: imageUrls,
        estimatedValue: widget.estimatedValue,
        serialNumber: widget.serialNumber,
        buildVersion: widget.buildVersion,
        ownershipDocumentsAvailable: widget.ownershipDocumentsAvailable,
        wishlist: widget.wishlist,
        locationLat: widget.locationLat,
        locationLng: widget.locationLng,
        locationArea: locationArea,
        wishFinding: _wishFinding,
        budgetNegotiation: _budgetNegotiation,
        budgetAmount: budgetAmount,
        collectionAssistance: _collectionAssistance,
      );

      if (!mounted) return;
      context.read<SuccessBloc>().add(
            const ShowSuccessEvent(
              message: 'Belonging added successfully!',
              nextScreen: 'home',
            ),
          );
      Navigator.of(context).pushAndRemoveUntil(
        SuccessRevealRoute(
          child: const Success(delayEntrance: true),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      if (ApiErrorHandler.isSessionExpired(e)) {
        context.read<AuthBloc>().add(const SessionExpiredEvent());
        return;
      }
      context.showAppSnackBar('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wScale = MediaQuery.sizeOf(context).width / _figmaW;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                15 * wScale,
                8 * wScale,
                15 * wScale,
                0,
              ),
              child: _buildHeader(wScale),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  26 * wScale,
                  36 * wScale,
                  26 * wScale,
                  24 * wScale,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add-on services',
                      style: AppTypography.style(
                        fontSize: 28 * wScale,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 10 * wScale),
                    Text(
                      'Optional services that help close your swap. Selected fees are added to your transaction fee when a swap happens.',
                      style: AppTypography.style(
                        fontSize: 13 * wScale,
                        fontWeight: FontWeight.w400,
                        color: _muted,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 32 * wScale),
                    Text(
                      'Deal Assistance',
                      style: AppTypography.style(
                        fontSize: 16 * wScale,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: 6 * wScale),
                    Text(
                      'Select one or both options below.',
                      style: AppTypography.style(
                        fontSize: 12 * wScale,
                        fontWeight: FontWeight.w400,
                        color: _muted,
                      ),
                    ),
                    SizedBox(height: 14 * wScale),
                    _AddonOptionTile(
                      selected: _wishFinding,
                      title: 'Wish Finding',
                      subtitle:
                          'SwapPro finds matches for the wishlist on this listing.',
                      feeLabel: '+GHS ${_wishFindingFee.toStringAsFixed(0)}',
                      wScale: wScale,
                      onTap: () =>
                          setState(() => _wishFinding = !_wishFinding),
                    ),
                    SizedBox(height: 10 * wScale),
                    _AddonOptionTile(
                      selected: _budgetNegotiation,
                      title: 'Budget Negotiation',
                      subtitle:
                          'State the highest amount you can add for your wish or desired item.',
                      feeLabel:
                          '+GHS ${_budgetNegotiationFee.toStringAsFixed(0)}',
                      wScale: wScale,
                      onTap: () => setState(
                        () => _budgetNegotiation = !_budgetNegotiation,
                      ),
                    ),
                    if (_budgetNegotiation) ...[
                      SizedBox(height: 12 * wScale),
                      Text(
                        'Your maximum budget (GHS)',
                        style: AppTypography.style(
                          fontSize: 13 * wScale,
                          fontWeight: FontWeight.w500,
                          color: _ink,
                        ),
                      ),
                      SizedBox(height: 8 * wScale),
                      TextField(
                        controller: _budgetController,
                        focusNode: _budgetFocus,
                        enabled: !_submitting,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => setState(() {}),
                        style: AppTypography.style(
                          fontSize: 15 * wScale,
                          fontWeight: FontWeight.w500,
                          color: _ink,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 200',
                          hintStyle: AppTypography.style(
                            fontSize: 15 * wScale,
                            color: _muted,
                          ),
                          filled: true,
                          fillColor: _backBtnBg,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16 * wScale,
                            vertical: 16 * wScale,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10 * wScale),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 28 * wScale),
                    Container(height: 1, color: _divider),
                    SizedBox(height: 28 * wScale),
                    Text(
                      'Collection Assistance',
                      style: AppTypography.style(
                        fontSize: 16 * wScale,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: 6 * wScale),
                    Text(
                      'We deliver the item to your listed location.',
                      style: AppTypography.style(
                        fontSize: 12 * wScale,
                        fontWeight: FontWeight.w400,
                        color: _muted,
                      ),
                    ),
                    SizedBox(height: 14 * wScale),
                    _AddonOptionTile(
                      selected: _collectionAssistance,
                      title: 'Collection Assistance',
                      subtitle:
                          'SwapPro delivers to the location you set on this listing.',
                      feeLabel:
                          '+GHS ${_collectionAssistanceFee.toStringAsFixed(0)}',
                      wScale: wScale,
                      onTap: () => setState(
                        () =>
                            _collectionAssistance = !_collectionAssistance,
                      ),
                    ),
                    if (_addonTotal > 0) ...[
                      SizedBox(height: 28 * wScale),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16 * wScale),
                        decoration: BoxDecoration(
                          color: _backBtnBg,
                          borderRadius: BorderRadius.circular(12 * wScale),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Add-on total (on transaction fee)',
                                style: AppTypography.style(
                                  fontSize: 13 * wScale,
                                  fontWeight: FontWeight.w500,
                                  color: _ink,
                                ),
                              ),
                            ),
                            Text(
                              'GHS ${_addonTotal.toStringAsFixed(0)}',
                              style: AppTypography.style(
                                fontSize: 16 * wScale,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 12 * wScale),
                    Text(
                      'You can skip this step if you do not need any add-ons.',
                      style: AppTypography.style(
                        fontSize: 12 * wScale,
                        fontWeight: FontWeight.w400,
                        color: _muted,
                      ),
                    ),
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
              child: _buildSubmitButton(wScale),
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
              onTap: _submitting ? null : () => Navigator.of(context).maybePop(),
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

  Widget _buildSubmitButton(double wScale) {
    final label = _addonTotal > 0 ? 'List with add-ons' : 'List belonging';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _submitting ? null : _submit,
        borderRadius: BorderRadius.circular(15 * wScale),
        child: Ink(
          height: 48 * wScale,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _submitting ? _ink.withValues(alpha: 0.35) : _ink,
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
            child: _submitting
                ? SizedBox(
                    width: 22 * wScale,
                    height: 22 * wScale,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    label,
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

class _AddonOptionTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final String feeLabel;
  final double wScale;
  final VoidCallback onTap;

  const _AddonOptionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.feeLabel,
    required this.wScale,
    required this.onTap,
  });

  static const Color _ink = Color(0xFF111111);
  static const Color _muted = Color(0xFF6B6B6B);
  static const Color _gold = Color(0xFFC3B649);
  static const Color _tileBg = Color(0xFFF5F4F8);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12 * wScale),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.all(14 * wScale),
          decoration: BoxDecoration(
            color: _tileBg,
            borderRadius: BorderRadius.circular(12 * wScale),
            border: Border.all(
              color: selected ? _gold : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22 * wScale,
                height: 22 * wScale,
                margin: EdgeInsets.only(top: 2 * wScale),
                decoration: BoxDecoration(
                  color: selected ? _ink : Colors.white,
                  borderRadius: BorderRadius.circular(6 * wScale),
                  border: Border.all(
                    color: selected ? _ink : const Color(0xFFD0CFD6),
                    width: 1.5,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        size: 14 * wScale,
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: 12 * wScale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.style(
                              fontSize: 15 * wScale,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                        ),
                        Text(
                          feeLabel,
                          style: AppTypography.style(
                            fontSize: 13 * wScale,
                            fontWeight: FontWeight.w600,
                            color: _gold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4 * wScale),
                    Text(
                      subtitle,
                      style: AppTypography.style(
                        fontSize: 12 * wScale,
                        fontWeight: FontWeight.w400,
                        color: _muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
