import 'package:swappro/barrel.dart';

enum SwapBayTab { sent, received, accepted, readySwaps, history }

/// Swap requests inbox — Figma "Swap Bay" (node 1:656).
class SwapBayPage extends StatelessWidget {
  const SwapBayPage({super.key, this.initialTab});

  final SwapBayTab? initialTab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SwapBayCubit(apiService: context.read<ApiService>())..load(),
      child: _SwapBayView(initialTab: initialTab),
    );
  }
}

class _SwapBayView extends StatefulWidget {
  const _SwapBayView({this.initialTab});

  final SwapBayTab? initialTab;

  @override
  State<_SwapBayView> createState() => _SwapBayViewState();
}

class _SwapBayViewState extends State<_SwapBayView> {
  static const Color _gold = Color(0xFFC3B649);
  static const Color _divider = Color(0xFFF6F6F6);
  static const Color _subtitle = Color(0xFF787676);

  late SwapBayTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab ?? SwapBayTab.received;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SwapBayCubit, SwapBayState>(
      listenWhen: (prev, next) =>
          prev.error != next.error && next.error != null,
      listener: (context, state) {
        final message = state.error;
        if (message != null && message.isNotEmpty) {
          context.showAppSnackBar(message);
        }
      },
      builder: (context, state) {
        final items = state.itemsForTab(_tab);
        final busy = state.loading || state.actionInProgress;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(15, 8, 15, 0),
                  child: AppScreenTopBar(title: 'Swap Bay'),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 21),
                  child: _buildTabBar(),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: state.loading && state.allRequests.isEmpty
                      ? const Center(child: SwapproLoadingIndicator())
                      : _buildList(items, busy: busy),
                ),
              ],
            ),
          ),
        );
      },
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
          const SizedBox(width: 20),
          _TabChip(
            label: 'History',
            selected: _tab == SwapBayTab.history,
            onTap: () => setState(() => _tab = SwapBayTab.history),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<SwapBayItem> items, {required bool busy}) {
    if (items.isEmpty) {
      return RefreshIndicator(
        color: _gold,
        onRefresh: () => context.read<SwapBayCubit>().refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.35,
              child: Center(
                child: Text(
                  'No ${_tabLabel(_tab).toLowerCase()} swap requests yet.',
                  style: AppTypography.style(fontSize: 15, color: _subtitle),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _gold,
      onRefresh: () => context.read<SwapBayCubit>().refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
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
              busy: busy,
              onAccept: () => _acceptOffer(item),
              onCancelOffer: () => _cancelOffer(item),
            );
          }
          if (_tab == SwapBayTab.accepted) {
            return _SwapRequestAcceptedTile(
              item: item,
              onPayTransaction: () => _payTransaction(item),
            );
          }
          if (_tab == SwapBayTab.readySwaps) {
            return _SwapRequestReadySwapTile(
              item: item,
              onGoForSwap: () => _goForSwap(item),
            );
          }
          if (_tab == SwapBayTab.history) {
            return _SwapRequestHistoryTile(item: item);
          }
          return _SwapRequestSentTile(
            item: item,
            onTap: () {},
            onCancel: () => _cancelRequest(item),
          );
        },
      ),
    );
  }

  Future<void> _cancelRequest(SwapBayItem item) async {
    final cubit = context.read<SwapBayCubit>();
    final ok = await cubit.cancelSentRequest(item.swapRequestId);
    if (!mounted) return;
    if (ok) {
      context.showAppSnackBar(
        'Swap request cancelled.',
        variant: AppSnackBarVariant.success,
      );
    }
  }

  Future<void> _acceptOffer(SwapBayItem item) async {
    final cubit = context.read<SwapBayCubit>();
    final ok = await cubit.approveOffer(item.swapRequestId);
    if (!mounted) return;
    if (ok) {
      context.showAppSnackBar(
        'Accepted swap offer for ${item.title}',
        variant: AppSnackBarVariant.success,
      );
      setState(() => _tab = SwapBayTab.accepted);
    }
  }

  Future<void> _cancelOffer(SwapBayItem item) async {
    final cubit = context.read<SwapBayCubit>();
    final ok = await cubit.rejectOffer(item.swapRequestId);
    if (!mounted) return;
    if (ok) {
      context.showAppSnackBar('Declined offer for ${item.title}');
    }
  }

  void _openPayTransaction(SwapBayItem item) {
    Navigator.of(context)
        .push<SwapBayTab>(
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 300),
        child: SwapCommitmentPage(
          swapRequestId: item.swapRequestId,
          propertyTitle: item.title,
          propertySubtitle: item.subtitle,
          feeAmount: item.feeAmount,
        ),
      ),
    )
        .then((result) {
      if (!mounted) return;
      if (result == SwapBayTab.readySwaps) {
        setState(() => _tab = SwapBayTab.readySwaps);
        context.read<SwapBayCubit>().refresh();
      }
    });
  }

  void _goForSwap(SwapBayItem item) {
    Navigator.of(context)
        .push<SwapBayTab>(
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 300),
        child: GoForSwapPage(
          swapRequestId: item.swapRequestId,
          propertyTitle: item.title,
        ),
      ),
    )
        .then((result) {
      if (!mounted) return;
      if (result == SwapBayTab.history) {
        setState(() => _tab = SwapBayTab.history);
        context.read<SwapBayCubit>().refresh();
      }
    });
  }

  void _payTransaction(SwapBayItem item) {
    if (item.yourCommitmentPaid) {
      context.showAppSnackBar(
        'Transaction fee already paid for ${item.title}',
        variant: AppSnackBarVariant.success,
      );
      return;
    }
    if (!item.isInitiator) {
      context.showAppSnackBar('Waiting for the initiator to pay the transaction fee.');
      return;
    }
    _openPayTransaction(item);
  }

  static String _tabLabel(SwapBayTab tab) {
    return switch (tab) {
      SwapBayTab.sent => 'Sent',
      SwapBayTab.received => 'Received',
      SwapBayTab.accepted => 'Accepted',
      SwapBayTab.readySwaps => 'Ready Swap',
      SwapBayTab.history => 'History',
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
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? activeColor : _chipInactive,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: AppTypography.style(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: selected
                ? Colors.white
                : Colors.black.withValues(alpha: 0.38),
            height: 16 / 12,
          ),
        ),
      ),
    );
  }
}

/// Sent tab row — Figma "Swap Bay" with Cancel Request (node 1:656).
class _SwapRequestSentTile extends StatelessWidget {
  const _SwapRequestSentTile({
    required this.item,
    required this.onTap,
    required this.onCancel,
  });

  final SwapBayItem item;
  final VoidCallback onTap;
  final VoidCallback onCancel;

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                width: thumb,
                height: thumb,
                child: _listingThumb(item.imageUrl),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onTap,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        if (item.price.isNotEmpty) ...[
                          const SizedBox(height: 4),
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
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    width: 100,
                    height: 24,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: _cancelRed,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Cancel Request',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.style(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// Ready Swap tab row — Figma "Swap 13" (node 200:83) with Go For Swap.
class _SwapRequestReadySwapTile extends StatelessWidget {
  const _SwapRequestReadySwapTile({
    required this.item,
    required this.onGoForSwap,
  });

  final SwapBayItem item;
  final VoidCallback onGoForSwap;

  static const Color _inkTitle = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _actionGreen = Color(0xFF1A8118);

  @override
  Widget build(BuildContext context) {
    const thumb = 70.0;
    return GestureDetector(
      onTap: onGoForSwap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 71,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: SizedBox(
                width: thumb,
                height: thumb,
                child: _listingThumb(item.imageUrl),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        if (item.price.isNotEmpty) ...[
                          const SizedBox(height: 4),
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
                      ],
                    ),
                  ),
                  Container(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// Received tab row — Figma "Swap 9" (node 1:697) with Accept / Cancel Offer.
class _SwapRequestReceivedTile extends StatelessWidget {
  const _SwapRequestReceivedTile({
    required this.item,
    required this.busy,
    required this.onAccept,
    required this.onCancelOffer,
  });

  final SwapBayItem item;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onCancelOffer;

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
              child: _listingThumb(item.imageUrl),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: busy ? null : onAccept,
                        child: Container(
                          width: 55,
                          height: 27,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: busy ? _ink.withValues(alpha: 0.5) : _ink,
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
                        onTap: busy ? null : onCancelOffer,
                        child: Container(
                          width: 90,
                          height: 27,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: busy
                                ? _cancelRed.withValues(alpha: 0.5)
                                : _cancelRed,
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

}

/// History tab row — completed swaps.
class _SwapRequestHistoryTile extends StatelessWidget {
  const _SwapRequestHistoryTile({required this.item});

  final SwapBayItem item;

  static const Color _inkTitle = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _completedGreen = Color(0xFF1A8118);

  @override
  Widget build(BuildContext context) {
    const thumb = 70.0;
    return SizedBox(
      height: 71,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              width: thumb,
              height: thumb,
              child: _listingThumb(item.imageUrl),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      if (item.price.isNotEmpty) ...[
                        const SizedBox(height: 4),
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
                    ],
                  ),
                ),
                Container(
                  width: 88,
                  height: 27,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _completedGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _completedGreen),
                  ),
                  child: Text(
                    'Completed',
                    style: AppTypography.style(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _completedGreen,
                      height: 17 / 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Accepted tab row — pay transaction fee before Ready Swap.
class _SwapRequestAcceptedTile extends StatelessWidget {
  const _SwapRequestAcceptedTile({
    required this.item,
    required this.onPayTransaction,
  });

  final SwapBayItem item;
  final VoidCallback onPayTransaction;

  static const Color _inkTitle = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _commitmentGreen = Color(0xFF1A8118);

  @override
  Widget build(BuildContext context) {
    const thumb = 70.0;
    final showPay = item.isInitiator && !item.yourCommitmentPaid;

    return SizedBox(
      height: 71,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              width: thumb,
              height: thumb,
              child: _listingThumb(item.imageUrl),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
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
                      if (item.price.isNotEmpty) ...[
                        const SizedBox(height: 4),
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
                    ],
                  ),
                ),
                if (showPay)
                  GestureDetector(
                    onTap: onPayTransaction,
                    child: Container(
                      width: 110,
                      height: 27,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: _commitmentGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Pay Transaction',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.style(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _listingThumb(String? imageUrl) {
  const placeholderColor = Color(0xFFF5F5F8);
  const subtitle = Color(0xFF787676);
  final url = imageUrl?.trim();
  if (url != null && url.isNotEmpty) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: placeholderColor,
        child: Icon(Icons.image_outlined, color: subtitle),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: placeholderColor,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: subtitle),
            ),
          ),
        );
      },
    );
  }
  return const ColoredBox(
    color: placeholderColor,
    child: Icon(Icons.image_outlined, color: subtitle),
  );
}

