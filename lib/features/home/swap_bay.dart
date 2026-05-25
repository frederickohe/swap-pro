import 'package:swappro/barrel.dart';

enum SwapBayTab { sent, received, accepted, readySwaps }

/// Swap requests inbox — Figma "Swap Bay" (node 1:656).
class SwapBayPage extends StatefulWidget {
  const SwapBayPage({super.key, this.initialTab});

  final SwapBayTab? initialTab;

  @override
  State<SwapBayPage> createState() => _SwapBayPageState();
}

class _SwapBayPageState extends State<SwapBayPage> {
  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBg = Color(0xFFF5F4F8);
  static const Color _divider = Color(0xFFF6F6F6);
  static const Color _subtitle = Color(0xFF787676);

  late SwapBayTab _tab;

  late final Map<SwapBayTab, List<_SwapRequestRow>> _requestsByTab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab ?? SwapBayTab.received;
    _requestsByTab = {
      SwapBayTab.sent: [
        const _SwapRequestRow(
          title: 'BMW Forza 2020',
          subtitle: 'Dress modern',
          price: '\$520,000.99',
        ),
        const _SwapRequestRow(
          title: '3 Bedroom Apartment',
          subtitle: 'Apartment',
          price: '\$230,000',
        ),
        const _SwapRequestRow(
          title: 'Hanjing C Ship',
          subtitle: 'Apartment',
          price: '\$150 M',
        ),
      ],
      SwapBayTab.received: [
        const _SwapRequestRow(
          title: 'BMW Forza 2020',
          subtitle: 'Dress modern',
          price: '\$520,000.99',
        ),
        const _SwapRequestRow(
          title: '3 Bedroom Apartment',
          subtitle: 'Apartment',
          price: '\$230,000',
        ),
        const _SwapRequestRow(
          title: 'Hanjing C Ship',
          subtitle: 'Apartment',
          price: '\$150 M',
        ),
      ],
      SwapBayTab.accepted: [
        const _SwapRequestRow(
          title: 'BMW Forza 2020',
          subtitle: 'Dress modern',
          price: '\$520,000.99',
          otherSwapperCommitmentPaid: true,
        ),
        const _SwapRequestRow(
          title: '3 Bedroom Apartment',
          subtitle: 'Apartment',
          price: '\$230,000',
        ),
        const _SwapRequestRow(
          title: 'Hanjing C Ship',
          subtitle: 'Apartment',
          price: '\$150 M',
        ),
      ],
      SwapBayTab.readySwaps: [
        const _SwapRequestRow(
          title: 'BMW Forza 2020',
          subtitle: 'Dress modern',
          price: '\$520,000.99',
        ),
        const _SwapRequestRow(
          title: '3 Bedroom Apartment',
          subtitle: 'Apartment',
          price: '\$230,000',
        ),
        const _SwapRequestRow(
          title: 'Hanjing C Ship',
          subtitle: 'Apartment',
          price: '\$150 M',
        ),
      ],
    };
  }

  List<_SwapRequestRow> get _visibleItems => _requestsByTab[_tab] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 8, 20, 0),
              child: _buildTopBar(context),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 21),
              child: _buildTabBar(),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 65,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _buildBackButton(context),
          ),
          Text(
            'Swap Bay',
            style: AppTypography.style(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 29 / 20,
            ),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: UserAvatar(size: 65, onLightBackground: true),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: _backBg,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: _gold,
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TabChip(
            label: 'Sent',
            selected: _tab == SwapBayTab.sent,
            onTap: () => setState(() => _tab = SwapBayTab.sent),
          ),
          const SizedBox(width: 20),
          _TabChip(
            label: 'Received',
            selected: _tab == SwapBayTab.received,
            onTap: () => setState(() => _tab = SwapBayTab.received),
          ),
          const SizedBox(width: 20),
          _TabChip(
            label: 'Accepted',
            selected: _tab == SwapBayTab.accepted,
            onTap: () => setState(() => _tab = SwapBayTab.accepted),
          ),
          const SizedBox(width: 20),
          _TabChip(
            label: 'Ready Swap',
            selected: _tab == SwapBayTab.readySwaps,
            selectedBackgroundColor: const Color(0xFF1A8118),
            onTap: () => setState(() => _tab = SwapBayTab.readySwaps),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final items = _visibleItems;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No ${_tabLabel(_tab).toLowerCase()} swap requests yet.',
          style: AppTypography.style(fontSize: 15, color: _subtitle),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 13.5),
        child: Divider(color: _divider, height: 1, thickness: 1),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        if (_tab == SwapBayTab.received) {
          return _SwapRequestReceivedTile(
            item: item,
            onAccept: () => _acceptOffer(item),
            onCancelOffer: () => _cancelOffer(item),
            onMore: () => _showActions(item),
          );
        }
        if (_tab == SwapBayTab.accepted) {
          return _SwapRequestAcceptedTile(
            item: item,
            onPayCommitment: () => _payCommitment(item),
            onMore: () => _showActions(item),
          );
        }
        if (_tab == SwapBayTab.readySwaps) {
          return _SwapRequestReadySwapTile(
            item: item,
            onGoForSwap: () => _goForSwap(item),
            onMore: () => _showActions(item),
          );
        }
        return _SwapRequestSentTile(
          item: item,
          onTap: () => _openCommitment(item),
          onCancel: () => _cancelRequest(item),
          onMore: () => _showActions(item),
        );
      },
    );
  }

  void _removeItem(_SwapRequestRow item) {
    setState(() {
      _requestsByTab[_tab]?.remove(item);
    });
  }

  void _cancelRequest(_SwapRequestRow item) {
    _removeItem(item);
    context.showAppSnackBar('Request for ${item.title} cancelled');
  }

  void _acceptOffer(_SwapRequestRow item) {
    _removeItem(item);
    context.showAppSnackBar('Accepted swap offer for ${item.title}');
  }

  void _cancelOffer(_SwapRequestRow item) {
    _removeItem(item);
    context.showAppSnackBar('Cancelled offer for ${item.title}');
  }

  void _openCommitment(_SwapRequestRow item) {
    Navigator.of(context)
        .push<SwapBayTab>(
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 300),
        child: SwapCommitmentPage(
          propertyTitle: item.title,
          propertySubtitle: item.subtitle,
        ),
      ),
    )
        .then((result) {
      if (!mounted) return;
      if (result == SwapBayTab.sent) {
        setState(() => _tab = SwapBayTab.sent);
      }
    });
  }

  void _goForSwap(_SwapRequestRow item) {
    Navigator.of(context).push(
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 300),
        child: GoForSwapPage(propertyTitle: item.title),
      ),
    );
  }

  void _payCommitment(_SwapRequestRow item) {
    if (item.yourCommitmentPaid) {
      context.showAppSnackBar('Commitment already paid for ${item.title}');
      return;
    }
    setState(() {
      final list = _requestsByTab[SwapBayTab.accepted];
      if (list == null) return;
      final i = list.indexWhere((r) => r.title == item.title);
      if (i < 0) return;
      final r = list[i];
      list[i] = _SwapRequestRow(
        title: r.title,
        subtitle: r.subtitle,
        price: r.price,
        otherSwapperCommitmentPaid: r.otherSwapperCommitmentPaid,
        yourCommitmentPaid: true,
      );
    });
    context.showAppSnackBar('Commitment payment started for ${item.title}');
  }

  void _showActions(_SwapRequestRow item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('View details'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.showAppSnackBar('Details for ${item.title} coming soon');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static String _tabLabel(SwapBayTab tab) {
    return switch (tab) {
      SwapBayTab.sent => 'Sent',
      SwapBayTab.received => 'Received',
      SwapBayTab.accepted => 'Accepted',
      SwapBayTab.readySwaps => 'Ready Swap',
    };
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedBackgroundColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedBackgroundColor;

  static const Color _ink = Color(0xFF111111);
  static const Color _chipInactive = Color(0xFFF5F4F8);

  @override
  Widget build(BuildContext context) {
    final activeColor = selectedBackgroundColor ?? _ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? activeColor : _chipInactive,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.style(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.black.withValues(alpha: 0.5),
            height: 22 / 14,
          ),
        ),
      ),
    );
  }
}

class _SwapRequestRow {
  const _SwapRequestRow({
    required this.title,
    required this.subtitle,
    required this.price,
    this.otherSwapperCommitmentPaid = false,
    this.yourCommitmentPaid = false,
  });

  final String title;
  final String subtitle;
  final String price;
  final bool otherSwapperCommitmentPaid;
  final bool yourCommitmentPaid;
}

/// Sent tab row — Figma "Swap Bay" with Cancel Request (node 1:656).
class _SwapRequestSentTile extends StatelessWidget {
  const _SwapRequestSentTile({
    required this.item,
    required this.onTap,
    required this.onCancel,
    required this.onMore,
  });

  final _SwapRequestRow item;
  final VoidCallback onTap;
  final VoidCallback onCancel;
  final VoidCallback onMore;

  static const Color _inkTitle = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _cancelRed = Color(0xFFC30000);

  @override
  Widget build(BuildContext context) {
    const thumb = 70.0;
    return SizedBox(
      height: 71,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                width: thumb,
                height: thumb,
                child: _thumbPlaceholder(),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.style(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _inkTitle,
                            height: 18 / 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: AppTypography.style(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _subtitle,
                            height: 13 / 12,
                          ),
                        ),
                        const Spacer(),
                        if (item.price.isNotEmpty)
                          Text(
                            item.price,
                            style: AppTypography.style(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _price,
                              height: 18 / 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onMore,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.more_horiz,
                          size: 24,
                          color: _price,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        width: 109,
                        height: 27,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _cancelRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Cancel Request',
                          style: AppTypography.style(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 17 / 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: const Color(0xFFF5F5F8),
      child: const Icon(Icons.image_outlined, color: _subtitle),
    );
  }
}

/// Ready Swap tab row — Figma "Swap 13" (node 200:83) with Go For Swap.
class _SwapRequestReadySwapTile extends StatelessWidget {
  const _SwapRequestReadySwapTile({
    required this.item,
    required this.onGoForSwap,
    required this.onMore,
  });

  final _SwapRequestRow item;
  final VoidCallback onGoForSwap;
  final VoidCallback onMore;

  static const Color _inkTitle = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _actionGreen = Color(0xFF1A8118);

  @override
  Widget build(BuildContext context) {
    const thumb = 70.0;
    return SizedBox(
      height: 71,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              width: thumb,
              height: thumb,
              child: _thumbPlaceholder(),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.style(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _inkTitle,
                            height: 18 / 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: AppTypography.style(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _subtitle,
                            height: 13 / 12,
                          ),
                        ),
                        const Spacer(),
                        if (item.price.isNotEmpty)
                          Text(
                            item.price,
                            style: AppTypography.style(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _price,
                              height: 18 / 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 93,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: onMore,
                        behavior: HitTestBehavior.opaque,
                        child: const Icon(
                          Icons.more_horiz,
                          size: 24,
                          color: _price,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: onGoForSwap,
                        child: Container(
                          width: 93,
                          height: 27,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _actionGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Go For Swap',
                            style: AppTypography.style(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              height: 17 / 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: const Color(0xFFF5F5F8),
      child: const Icon(Icons.image_outlined, color: _subtitle),
    );
  }
}

/// Received tab row — Figma "Swap 9" (node 1:697) with Accept / Cancel Offer.
class _SwapRequestReceivedTile extends StatelessWidget {
  const _SwapRequestReceivedTile({
    required this.item,
    required this.onAccept,
    required this.onCancelOffer,
    required this.onMore,
  });

  final _SwapRequestRow item;
  final VoidCallback onAccept;
  final VoidCallback onCancelOffer;
  final VoidCallback onMore;

  static const Color _ink = Color(0xFF111111);
  static const Color _inkTitle = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _cancelRed = Color(0xFFC30000);

  @override
  Widget build(BuildContext context) {
    const thumb = 70.0;
    return SizedBox(
      height: 118,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              width: thumb,
              height: thumb,
              child: _thumbPlaceholder(),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.style(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _inkTitle,
                            height: 18 / 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: AppTypography.style(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _subtitle,
                            height: 13 / 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (item.price.isNotEmpty)
                          Text(
                            item.price,
                            style: AppTypography.style(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _price,
                              height: 18 / 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: onMore,
                        behavior: HitTestBehavior.opaque,
                        child: const Icon(
                          Icons.more_horiz,
                          size: 24,
                          color: _price,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: onAccept,
                        child: Container(
                          width: 55,
                          height: 27,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _ink,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Accept',
                            style: AppTypography.style(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              height: 17 / 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: onCancelOffer,
                        child: Container(
                          width: 90,
                          height: 27,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _cancelRed,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Cancel Offer',
                            style: AppTypography.style(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              height: 17 / 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: const Color(0xFFF5F5F8),
      child: const Icon(Icons.image_outlined, color: _subtitle),
    );
  }
}

/// Accepted tab row — Figma "Swap 10" (node 1:718) with Pay Commitment + progress.
class _SwapRequestAcceptedTile extends StatelessWidget {
  const _SwapRequestAcceptedTile({
    required this.item,
    required this.onPayCommitment,
    required this.onMore,
  });

  final _SwapRequestRow item;
  final VoidCallback onPayCommitment;
  final VoidCallback onMore;

  static const Color _inkTitle = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _commitmentGreen = Color(0xFF1A8118);

  @override
  Widget build(BuildContext context) {
    const thumb = 70.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 71,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  width: thumb,
                  height: thumb,
                  child: _thumbPlaceholder(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.style(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _inkTitle,
                                height: 18 / 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              style: AppTypography.style(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: _subtitle,
                                height: 13 / 12,
                              ),
                            ),
                            const Spacer(),
                            if (item.price.isNotEmpty)
                              Text(
                                item.price,
                                style: AppTypography.style(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _price,
                                  height: 18 / 14,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 123,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: onMore,
                            behavior: HitTestBehavior.opaque,
                            child: const Icon(
                              Icons.more_horiz,
                              size: 24,
                              color: _price,
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: onPayCommitment,
                            child: Container(
                              width: 123,
                              height: 27,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _commitmentGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Pay Commitment',
                                style: AppTypography.style(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  height: 17 / 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _CommitmentProgress(
          otherSwapperPaid: item.otherSwapperCommitmentPaid,
          yourPaid: item.yourCommitmentPaid,
        ),
      ],
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: const Color(0xFFF5F5F8),
      child: const Icon(Icons.image_outlined, color: _subtitle),
    );
  }
}

class _CommitmentProgress extends StatelessWidget {
  const _CommitmentProgress({
    required this.otherSwapperPaid,
    required this.yourPaid,
  });

  final bool otherSwapperPaid;
  final bool yourPaid;

  static const Color _commitmentGreen = Color(0xFF1A8118);
  static const Color _commitmentGray = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Other Swapper Commitment',
                style: AppTypography.style(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 17 / 12,
                ),
              ),
            ),
            Text(
              'Your Commitment',
              style: AppTypography.style(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 17 / 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 10,
          child: Row(
            children: [
              Expanded(
                child: ColoredBox(
                  color: otherSwapperPaid ? _commitmentGreen : _commitmentGray,
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: yourPaid ? _commitmentGreen : _commitmentGray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
