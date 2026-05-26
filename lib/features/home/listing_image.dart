/// Cover image for listing cards (property photo, not spec label when possible).
String? listingDisplayImageUrl(Map<String, dynamic> listing) {
  final primary = (listing['primary_image_url'] ?? '').toString().trim();
  final extras = listing['image_urls'];
  final galleryUrls = <String>[];
  if (extras is List) {
    for (final url in extras) {
      final s = url.toString().trim();
      if (s.isNotEmpty) galleryUrls.add(s);
    }
  }

  // Legacy listings stored the spec label as primary and photos in image_urls.
  if (galleryUrls.isNotEmpty &&
      primary.isNotEmpty &&
      primary != galleryUrls.first &&
      !galleryUrls.contains(primary)) {
    return galleryUrls.first;
  }

  if (primary.isNotEmpty) return primary;
  if (galleryUrls.isNotEmpty) return galleryUrls.first;
  return null;
}

/// Gallery images first; spec/primary appended when it is not already included.
List<String> listingGalleryImageUrls(Map<String, dynamic> listing) {
  final urls = <String>[];
  final extras = listing['image_urls'];
  if (extras is List) {
    for (final url in extras) {
      final s = url.toString().trim();
      if (s.isNotEmpty && !urls.contains(s)) urls.add(s);
    }
  }
  final primary = (listing['primary_image_url'] ?? '').toString().trim();
  if (primary.isNotEmpty && !urls.contains(primary)) {
    urls.insert(0, primary);
  } else if (primary.isNotEmpty && urls.isNotEmpty && urls.first != primary) {
    urls.insert(0, primary);
  } else if (primary.isNotEmpty && urls.isEmpty) {
    urls.add(primary);
  }
  return urls;
}
