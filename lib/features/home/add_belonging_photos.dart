import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:swappro/barrel.dart';

/// Add belonging flow — step 4 gallery photos (Figma "Add 4", node 194:467).
class AddBelongingPhotosPage extends StatefulWidget {
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

  const AddBelongingPhotosPage({
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
  });

  @override
  State<AddBelongingPhotosPage> createState() => _AddBelongingPhotosPageState();
}

class _AddBelongingPhotosPageState extends State<AddBelongingPhotosPage> {
  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBtnBg = Color(0xFFF5F4F8);
  static const Color _ink = Color(0xFF111111);

  static const double _figmaW = 428;
  static const int _maxPhotos = 5;

  final List<File> _photos = [];
  bool _pickingImage = false;
  bool _submitting = false;

  bool get _canProceed => _photos.isNotEmpty && !_submitting;

  Future<void> _pickPhoto() async {
    if (_pickingImage || _photos.length >= _maxPhotos) return;

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
      setState(() => _photos.add(File(picked.path)));
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_canProceed) return;

    setState(() => _submitting = true);
    try {
      final api = context.read<ApiService>();
      final primaryUrl = await api.uploadFile(
        file: widget.specLabelImage,
        storageFolder: ApiService.listingsStorageFolder,
      );

      final galleryUrls = <String>[];
      for (final file in _photos) {
        galleryUrls.add(
          await api.uploadFile(
            file: file,
            storageFolder: ApiService.listingsStorageFolder,
          ),
        );
      }

      await api.createBelongingListing(
        title: widget.title,
        description: widget.description,
        category: widget.itemCategory,
        condition: widget.condition,
        primaryImageUrl: primaryUrl,
        imageUrls: galleryUrls,
        estimatedValue: widget.estimatedValue,
        serialNumber: widget.serialNumber,
        buildVersion: widget.buildVersion,
        ownershipDocumentsAvailable: widget.ownershipDocumentsAvailable,
        wishlist: widget.wishlist,
        locationLat: widget.locationLat,
        locationLng: widget.locationLng,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 500),
          reverseDuration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          child: const AddBelongingCompletePage(),
        ),
        (route) => route.isFirst,
      );
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wScale = MediaQuery.sizeOf(context).width / _figmaW;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final tileW = 159 * wScale;
    final tileH = 161 * wScale;
    final addSize = 78 * wScale;
    final gap = 9 * wScale;

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
                      'Almost done, add vivid photos',
                      style: AppTypography.style(
                        fontSize: 28 * wScale,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 12 * wScale),
                    Text(
                      'Add up to $_maxPhotos gallery images (spec label is the main photo).',
                      style: AppTypography.style(
                        fontSize: 13 * wScale,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF111111),
                      ),
                    ),
                    SizedBox(height: 42 * wScale),
                    Center(
                      child: SizedBox(
                        width: tileW * 2 + gap,
                        child: _buildGalleryGrid(
                          wScale: wScale,
                          tileW: tileW,
                          tileH: tileH,
                          addSize: addSize,
                          gap: gap,
                        ),
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
              child: _buildNextButton(wScale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid({
    required double wScale,
    required double tileW,
    required double tileH,
    required double addSize,
    required double gap,
  }) {
    final slots = <Widget>[];
    for (var i = 0; i < _photos.length; i++) {
      slots.add(
        _PhotoTile(
          file: _photos[i],
          width: tileW,
          height: tileH,
          radius: 10 * wScale,
          onRemove: () => _removePhoto(i),
        ),
      );
    }

    if (_photos.length < _maxPhotos) {
      slots.add(
        _AddPhotoTile(
          size: addSize,
          radius: 10 * wScale,
          loading: _pickingImage,
          onTap: _pickPhoto,
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < slots.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: 10 * wScale));
      final left = slots[i];
      final right = i + 1 < slots.length ? slots[i + 1] : null;
      rows.add(
        Row(
          children: [
            left,
            if (right != null) ...[
              SizedBox(width: gap),
              right,
            ] else
              const Spacer(),
          ],
        ),
      );
    }

    return Column(children: rows);
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
        onTap: enabled ? _submit : null,
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

class _PhotoTile extends StatelessWidget {
  final File file;
  final double width;
  final double height;
  final double radius;
  final VoidCallback onRemove;

  const _PhotoTile({
    required this.file,
    required this.width,
    required this.height,
    required this.radius,
    required this.onRemove,
  });

  static const Color _border = Color(0xFFF5F4F8);
  static const Color _removeGreen = Color(0xFF8BC83F);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: _border, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(file, fit: BoxFit.cover),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _removeGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final double size;
  final double radius;
  final bool loading;
  final VoidCallback onTap;

  const _AddPhotoTile({
    required this.size,
    required this.radius,
    required this.loading,
    required this.onTap,
  });

  static const Color _tileBg = Color(0xFFF5F4F8);
  static const Color _plusIcon = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _tileBg,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _plusIcon,
                  ),
                ),
              )
            : const Icon(Icons.add, size: 20, color: _plusIcon),
      ),
    );
  }
}
