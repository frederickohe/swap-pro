import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:swappro/barrel.dart';

/// Add belonging flow — step 2 specification label upload (Figma "Add 2", node 194:339).
class AddBelongingSpecLabelPage extends StatefulWidget {
  final String itemCategory;
  final String? incomingCategory;

  const AddBelongingSpecLabelPage({
    super.key,
    required this.itemCategory,
    this.incomingCategory,
  });

  @override
  State<AddBelongingSpecLabelPage> createState() =>
      _AddBelongingSpecLabelPageState();
}

class _AddBelongingSpecLabelPageState extends State<AddBelongingSpecLabelPage> {
  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBtnBg = Color(0xFFF5F4F8);
  static const Color _uploadBg = Color(0xFFF5F4F8);
  static const Color _plusIcon = Color(0xFF252B5C);
  static const Color _ink = Color(0xFF111111);

  static const double _figmaW = 428;

  File? _pickedImage;
  bool _pickingImage = false;

  Future<void> _pickPhoto() async {
    if (_pickingImage) return;

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
      setState(() => _pickedImage = File(picked.path));
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
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
                      'Provide us the specification label',
                      style: AppTypography.style(
                        fontSize: 28 * wScale,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: 75 * wScale),
                    Center(child: _buildUploadButton(wScale)),
                    SizedBox(height: 17 * wScale),
                    Center(
                      child: Text(
                        'Click to upload photo',
                        style: AppTypography.style(
                          fontSize: 18 * wScale,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 84 * wScale),
                    Text(
                      'If specification label not available, add image of an identifying feature',
                      style: AppTypography.style(
                        fontSize: 28 * wScale,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        height: 1.25,
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

  Widget _buildUploadButton(double wScale) {
    final size = 78 * wScale;

    return GestureDetector(
      onTap: _pickPhoto,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _uploadBg,
          borderRadius: BorderRadius.circular(10 * wScale),
        ),
        clipBehavior: Clip.antiAlias,
        child: _pickingImage
            ? Center(
                child: SizedBox(
                  width: 24 * wScale,
                  height: 24 * wScale,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _plusIcon,
                  ),
                ),
              )
            : _pickedImage != null
                ? Image.file(_pickedImage!, fit: BoxFit.cover)
                : Icon(Icons.add, size: 20 * wScale, color: _plusIcon),
      ),
    );
  }

  Widget _buildNextButton(double wScale) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickedImage == null
            ? null
            : () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeftWithFade,
                    child: AddBelongingDetailsPage(
                      itemCategory: widget.itemCategory,
                      incomingCategory: widget.incomingCategory,
                      specLabelImage: _pickedImage!,
                    ),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(15 * wScale),
        child: Ink(
          height: 48 * wScale,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _pickedImage == null ? _ink.withValues(alpha: 0.35) : _ink,
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
