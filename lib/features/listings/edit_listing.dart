import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:swappro/barrel.dart';

/// Edit an existing listing — pre-filled form with photo management.
class EditListingPage extends StatefulWidget {
  const EditListingPage({super.key, required this.listing});

  final Map<String, dynamic> listing;

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingImageSlot {
  const _EditListingImageSlot.url(this.url) : file = null;
  const _EditListingImageSlot.file(this.file) : url = null;

  final String? url;
  final File? file;

  bool get isUrl => url != null;
}

class _EditListingPageState extends State<EditListingPage> {
  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBtnBg = Color(0xFFF5F4F8);
  static const Color _ink = Color(0xFF111111);
  static const int _maxPhotos = 5;

  static const List<String> _conditionOptions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'Poor',
  ];

  late final String _listingId;
  late final String _category;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _buildVersionController = TextEditingController();
  final _priceController = TextEditingController();

  String? _condition;
  bool _ownershipDocumentsAvailable = false;
  double? _locationLat;
  double? _locationLng;
  String? _locationAreaLabel;
  final _geocoding = GeocodingService();
  final List<String> _extraWishDescriptions = [];
  final List<_EditListingImageSlot> _images = [];

  bool _pickingImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefillFromListing();
  }

  void _prefillFromListing() {
    final listing = widget.listing;
    _listingId = (listing['id'] ?? '').toString();
    _category = (listing['category'] ?? '').toString();

    _titleController.text = (listing['title'] ?? '').toString();
    _descriptionController.text = (listing['description'] ?? '').toString();
    _serialNumberController.text = (listing['serial_number'] ?? '').toString();
    _buildVersionController.text = (listing['build_version'] ?? '').toString();

    final value = listing['estimated_value'];
    if (value is num) {
      _priceController.text = value.toStringAsFixed(2);
    } else {
      _priceController.text = (value ?? '').toString();
    }

    final condition = (listing['condition'] ?? '').toString().trim();
    _condition = condition.isEmpty ? null : condition;
    _ownershipDocumentsAvailable =
        listing['ownership_documents_available'] == true;

    final lat = listing['location_lat'];
    final lng = listing['location_lng'];
    if (lat is num && lng is num) {
      _locationLat = lat.toDouble();
      _locationLng = lng.toDouble();
    }
    _locationAreaLabel = (listing['location_area'] ?? '').toString().trim();
    if (_locationAreaLabel?.isEmpty == true) _locationAreaLabel = null;

    final wishlist = listing['wishlist'];
    if (wishlist is List) {
      for (final item in wishlist) {
        if (item is! Map) continue;
        final desc = (item['description'] ?? '').toString().trim();
        if (desc.isNotEmpty) _extraWishDescriptions.add(desc);
      }
    }

    final primary = (listing['primary_image_url'] ?? '').toString().trim();
    if (primary.isNotEmpty) {
      _images.add(_EditListingImageSlot.url(primary));
    }
    final extras = listing['image_urls'];
    if (extras is List) {
      for (final raw in extras) {
        final url = raw.toString().trim();
        if (url.isNotEmpty) {
          _images.add(_EditListingImageSlot.url(url));
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _serialNumberController.dispose();
    _buildVersionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.length < 3) return false;
    if (description.length < 10) return false;
    if (_condition == null || _condition!.isEmpty) return false;
    if (_parsePrice(_priceController.text.trim()) == null) return false;
    if (_locationLat == null || _locationLng == null) return false;
    if (_images.isEmpty) return false;
    return !_saving;
  }

  double? _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  List<Map<String, dynamic>> _buildWishlistPayload() {
    return _extraWishDescriptions
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .map((w) => {'description': w})
        .toList();
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

  Future<void> _pickPhoto() async {
    if (_pickingImage || _images.length >= _maxPhotos) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _pickingImage = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1400,
      );
      if (picked == null || !mounted) return;
      setState(() => _images.add(_EditListingImageSlot.file(File(picked.path))));
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _removePhoto(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _save() async {
    if (!_canSave) return;

    final price = _parsePrice(_priceController.text.trim());
    if (price == null || price <= 0) {
      context.showAppSnackBar('Enter a valid estimated value');
      return;
    }

    if (_listingId.trim().isEmpty) {
      context.showAppSnackBar('This listing is missing an id.');
      return;
    }

    setState(() => _saving = true);
    try {
      final api = context.read<ApiService>();
      final resolvedUrls = <String>[];

      for (final slot in _images) {
        if (slot.isUrl) {
          resolvedUrls.add(slot.url!);
        } else if (slot.file != null) {
          resolvedUrls.add(
            await api.uploadFile(
              file: slot.file!,
              storageFolder: ApiService.listingsStorageFolder,
            ),
          );
        }
      }

      if (!mounted) return;
      if (resolvedUrls.isEmpty) {
        context.showAppSnackBar('Add at least one photo');
        return;
      }

      await api.updateBelongingListing(
        listingId: _listingId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        condition: _condition!,
        primaryImageUrl: resolvedUrls.first,
        imageUrls: resolvedUrls.length > 1 ? resolvedUrls.sublist(1) : const [],
        estimatedValue: price,
        serialNumber: _serialNumberController.text.trim(),
        buildVersion: _buildVersionController.text.trim(),
        ownershipDocumentsAvailable: _ownershipDocumentsAvailable,
        wishlist: _buildWishlistPayload(),
        locationLat: _locationLat,
        locationLng: _locationLng,
        locationArea: _locationAreaLabel,
      );

      if (!mounted) return;
      context.showAppSnackBar('Listing updated.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      if (message.contains('Session expired') ||
          message.toLowerCase().contains('invalid token')) {
        context.showAppSnackBar('Session expired. Please sign in again.');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Signin()),
          (route) => route.isFirst,
        );
        return;
      }
      context.showAppSnackBar(message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
              child: _buildHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit listing',
                      style: AppTypography.style(
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    if (_category.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Category: $_category',
                        style: AppTypography.style(
                          fontSize: 13,
                          color: const Color(0xFF787676),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    _buildPhotoSection(),
                    const SizedBox(height: 28),
                    _buildField(
                      controller: _titleController,
                      hint: 'Title',
                      maxLines: 1,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      controller: _descriptionController,
                      hint: 'Description',
                      maxLines: 5,
                      height: 140,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      controller: _serialNumberController,
                      hint: 'Serial number (optional)',
                    ),
                    const SizedBox(height: 20),
                    _buildField(
                      controller: _buildVersionController,
                      hint: 'Build version (optional)',
                    ),
                    const SizedBox(height: 20),
                    _buildConditionDropdown(),
                    const SizedBox(height: 20),
                    Material(
                      color: const Color(0xFFF5F4F8),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => setState(
                          () => _ownershipDocumentsAvailable =
                              !_ownershipDocumentsAvailable,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Ownership documents available',
                                  style: AppTypography.style(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: _ink,
                                  ),
                                ),
                              ),
                              SettingsToggleSwitch(
                                value: _ownershipDocumentsAvailable,
                                enabled: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Estimated value',
                      style: AppTypography.style(fontSize: 14, color: _ink),
                    ),
                    const SizedBox(height: 10),
                    _buildField(
                      controller: _priceController,
                      hint: 'Amount (GH₵)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Location',
                      style: AppTypography.style(fontSize: 14, color: _ink),
                    ),
                    const SizedBox(height: 10),
                    _buildLocationPicker(),
                    if (_extraWishDescriptions.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < _extraWishDescriptions.length; i++)
                            InputChip(
                              label: Text(_extraWishDescriptions[i]),
                              onDeleted: () => setState(
                                () => _extraWishDescriptions.removeAt(i),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _addWish,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add wishlist item'),
                      style: TextButton.styleFrom(foregroundColor: _ink),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(39, 16, 39, 16 + bottomInset),
              child: _buildSaveButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: _backBtnBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: _gold,
                ),
              ),
            ),
          ),
          Text(
            'Edit Listing',
            style: AppTypography.style(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos',
          style: AppTypography.style(fontSize: 14, color: _ink),
        ),
        const SizedBox(height: 10),
        Text(
          'First photo is the cover. Up to $_maxPhotos photos.',
          style: AppTypography.style(
            fontSize: 12,
            color: const Color(0xFF787676),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _images.length; i++)
              _PhotoThumb(
                slot: _images[i],
                onRemove: () => _removePhoto(i),
              ),
            if (_images.length < _maxPhotos)
              _AddPhotoButton(loading: _pickingImage, onTap: _pickPhoto),
          ],
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    double? height,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      height: height ?? (maxLines > 1 ? null : 70),
      constraints: height == null && maxLines > 1
          ? const BoxConstraints(minHeight: 70)
          : null,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F8),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: maxLines > 1 ? Alignment.topLeft : Alignment.centerLeft,
      padding: EdgeInsets.fromLTRB(16, maxLines > 1 ? 16 : 0, 16, 0),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        style: AppTypography.style(fontSize: 14, color: _ink),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.style(fontSize: 14, color: _ink),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildConditionDropdown() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F4F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _condition,
          isExpanded: true,
          hint: Text(
            'Condition',
            style: AppTypography.style(fontSize: 14, color: _ink),
          ),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _ink),
          items: _conditionOptions
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, style: AppTypography.style(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _condition = value),
        ),
      ),
    );
  }

  Widget _buildLocationPicker() {
    final hasLocation = _locationLat != null && _locationLng != null;
    final label = () {
      if (!hasLocation) return 'Tap to pick location on map';
      if (_locationAreaLabel != null && _locationAreaLabel!.trim().isNotEmpty) {
        return _locationAreaLabel!.trim();
      }
      return 'Location selected';
    }();

    return GestureDetector(
      onTap: _pickLocation,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F4F8),
          borderRadius: BorderRadius.circular(10),
          border: hasLocation
              ? Border.all(color: _ink, width: 0.8)
              : null,
        ),
        child: Row(
          children: [
            const Icon(Icons.map_outlined, color: _ink),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.style(fontSize: 14, color: _ink),
              ),
            ),
            const Icon(Icons.chevron_right, color: _ink),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final enabled = _canSave;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? _save : null,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: enabled ? _ink : _ink.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Save changes',
                    style: AppTypography.style(
                      fontSize: 18,
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

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.slot, required this.onRemove});

  final _EditListingImageSlot slot;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 100,
              height: 100,
              child: slot.isUrl
                  ? Image.network(
                      slot.url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => _placeholder(),
                    )
                  : Image.file(slot.file!, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF8BC83F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8E8E8),
      child: const Icon(Icons.image_outlined),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F4F8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.add, size: 24, color: Color(0xFF111111)),
      ),
    );
  }
}
