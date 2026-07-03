import 'package:swappro/barrel.dart';

/// Bottom sheet + dialogs for edit/delete on a user's listing.
class ListingActions {
  ListingActions._();

  static Future<void> showSheet({
    required BuildContext context,
    required Map<String, dynamic> listing,
    VoidCallback? onChanged,
  }) async {
    final title = (listing['title'] ?? 'Listing').toString().trim();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  title.isEmpty ? 'Listing options' : title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.style(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit listing'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditListingPage(listing: listing),
                    ),
                  );
                  if (updated == true) onChanged?.call();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red.shade700),
                title: Text(
                  'Delete listing',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final deleted = await confirmDelete(
                    context: context,
                    listingTitle: title,
                    listingId: (listing['id'] ?? '').toString(),
                  );
                  if (deleted) onChanged?.call();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static Future<bool> confirmDelete({
    required BuildContext context,
    required String listingTitle,
    required String listingId,
  }) async {
    if (listingId.trim().isEmpty) {
      context.showAppSnackBar('This listing is missing an id.');
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete listing?',
                  style: AppTypography.style(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  listingTitle.isEmpty
                      ? 'This listing will be removed from the marketplace.'
                      : '"$listingTitle" will be removed from the marketplace.',
                  textAlign: TextAlign.center,
                  style: AppTypography.style(
                    fontSize: 13.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !context.mounted) return false;

    try {
      await context.read<ApiService>().deleteListing(listingId);
      if (!context.mounted) return false;
      context.showAppSnackBar(
        'Listing deleted.',
        variant: AppSnackBarVariant.success,
      );
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      if (ApiErrorHandler.isSessionExpired(e)) {
        context.read<AuthBloc>().add(const SessionExpiredEvent());
        return false;
      }
      context.showAppSnackBar(
        'Something went wrong. Please try again.',
      );
      return false;
    }
  }
}

/// Three-dot menu button wired to [ListingActions.showSheet].
class ListingMoreMenuButton extends StatelessWidget {
  const ListingMoreMenuButton({
    super.key,
    required this.listing,
    this.onChanged,
    this.iconSize = 22,
  });

  final Map<String, dynamic> listing;
  final VoidCallback? onChanged;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => ListingActions.showSheet(
          context: context,
          listing: listing,
          onChanged: onChanged,
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.more_horiz_rounded,
            size: iconSize,
            color: const Color(0xFF292526),
          ),
        ),
      ),
    );
  }
}
