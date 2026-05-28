import 'package:swappro/barrel.dart';

/// One row in Swap Bay — backed by `GET /api/v1/swaps/requests`.
class SwapBayItem {
  const SwapBayItem({
    required this.swapRequestId,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isInitiator,
    required this.status,
    required this.initiatorFeePaid,
    required this.ownerFeePaid,
    this.imageUrl,
    this.hubId,
    this.meetingTime,
    this.feeAmount = 0,
  });

  final String swapRequestId;
  final String title;
  final String subtitle;
  final String price;
  final String? imageUrl;
  final bool isInitiator;
  final String status;
  final bool initiatorFeePaid;
  final bool ownerFeePaid;
  final String? hubId;
  final String? meetingTime;
  final double feeAmount;

  bool get yourCommitmentPaid =>
      isInitiator ? initiatorFeePaid : ownerFeePaid;

  bool get otherSwapperCommitmentPaid =>
      isInitiator ? ownerFeePaid : initiatorFeePaid;
}

class SwapBayState extends Equatable {
  const SwapBayState({
    this.loading = false,
    this.actionInProgress = false,
    this.error,
    this.currentUserId,
    this.allRequests = const [],
  });

  final bool loading;
  final bool actionInProgress;
  final String? error;
  final String? currentUserId;
  final List<Map<String, dynamic>> allRequests;

  List<SwapBayItem> itemsForTab(SwapBayTab tab) {
    final userId = currentUserId?.trim();
    if (userId == null || userId.isEmpty) return const [];

    return allRequests
        .where((req) => _matchesTab(req, tab, userId))
        .map((req) => SwapBayItemMapper.fromRequest(req, userId))
        .toList();
  }

  /// Status from API (`effective_status` on the backend). Do not remap here —
  /// the client does not receive `initiator_paystack_ref`, so local remapping
  /// incorrectly kept owner-approved swaps on the Received tab.
  static String _resolvedStatus(Map<String, dynamic> req) {
    return (req['status'] ?? '').toString();
  }

  static bool _matchesTab(
    Map<String, dynamic> req,
    SwapBayTab tab,
    String userId,
  ) {
    final status = _resolvedStatus(req);
    final ownerApproved = req['owner_approved'] == true;
    final initiatorId = (req['initiator_id'] ?? '').toString();
    final ownerId = (req['owner_id'] ?? '').toString();
    final isInitiator = initiatorId == userId;
    final isOwner = ownerId == userId;

    return switch (tab) {
      SwapBayTab.sent =>
        isInitiator &&
        status == 'PENDING_OWNER_APPROVAL' &&
        !ownerApproved,
      SwapBayTab.received =>
        isOwner && status == 'PENDING_OWNER_APPROVAL' && !ownerApproved,
      SwapBayTab.accepted =>
        status == 'PENDING_INITIATOR_FEE' &&
        req['initiator_fee_paid'] != true,
      SwapBayTab.readySwaps => status == 'PENDING_HUB_MEETING',
    };
  }

  SwapBayState copyWith({
    bool? loading,
    bool? actionInProgress,
    String? error,
    String? currentUserId,
    List<Map<String, dynamic>>? allRequests,
    bool clearError = false,
  }) {
    return SwapBayState(
      loading: loading ?? this.loading,
      actionInProgress: actionInProgress ?? this.actionInProgress,
      error: clearError ? null : (error ?? this.error),
      currentUserId: currentUserId ?? this.currentUserId,
      allRequests: allRequests ?? this.allRequests,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        actionInProgress,
        error,
        currentUserId,
        allRequests,
      ];
}

class SwapBayItemMapper {
  static SwapBayItem fromRequest(
    Map<String, dynamic> req,
    String userId,
  ) {
    final initiatorId = (req['initiator_id'] ?? '').toString();
    final isInitiator = initiatorId == userId;
    final displayListing = _displayListing(req, isInitiator);

    final title = (displayListing?['title'] ?? 'Swap request').toString().trim();
    final category = (displayListing?['category'] ?? '').toString().trim();
    final condition = (displayListing?['condition'] ?? '').toString().trim();
    var subtitle = category.isNotEmpty
        ? category
        : (condition.isNotEmpty ? condition : 'Listing');

    final price = _formatPrice(displayListing?['estimated_value']);
    String? imageUrl;
    if (displayListing != null) {
      imageUrl = listingDisplayImageUrl(displayListing);
    }

    return SwapBayItem(
      swapRequestId: (req['id'] ?? '').toString(),
      title: title.isEmpty ? 'Untitled listing' : title,
      subtitle: subtitle,
      price: price,
      imageUrl: imageUrl,
      isInitiator: isInitiator,
      status: SwapBayState._resolvedStatus(req),
      initiatorFeePaid: req['initiator_fee_paid'] == true,
      ownerFeePaid: req['owner_fee_paid'] == true,
      hubId: req['hub_id']?.toString(),
      meetingTime: req['meeting_time']?.toString(),
      feeAmount: _feeAmount(req, isInitiator),
    );
  }

  static Map<String, dynamic>? _displayListing(
    Map<String, dynamic> req,
    bool isInitiator,
  ) {
    final key = isInitiator ? 'owner_listing' : 'initiator_listing';
    final nested = req[key];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return null;
  }

  static double _feeAmount(Map<String, dynamic> req, bool isInitiator) {
    final key = isInitiator ? 'initiator_fee_amount' : 'owner_fee_amount';
    final value = req[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatPrice(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      return 'GH₵ ${value.toStringAsFixed(2)}';
    }
    final s = value.toString().trim();
    if (s.isEmpty) return '';
    return s.startsWith('GH') ? s : 'GH₵ $s';
  }
}

class SwapBayCubit extends Cubit<SwapBayState> {
  SwapBayCubit({required ApiService apiService})
      : _apiService = apiService,
        super(const SwapBayState());

  final ApiService _apiService;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final profile = await _apiService.getUserProfile();
      final userId = (profile['id'] ?? profile['user_id'] ?? '').toString();
      final requests = await _apiService.listSwapRequests(role: 'all');
      emit(
        state.copyWith(
          loading: false,
          currentUserId: userId,
          allRequests: requests,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() => load();

  Future<bool> approveOffer(String swapRequestId) async {
    emit(state.copyWith(actionInProgress: true, clearError: true));
    try {
      await _apiService.approveSwapRequest(swapRequestId);
      await load();
      emit(state.copyWith(actionInProgress: false, clearError: true));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          actionInProgress: false,
          error: _friendlyError(e),
        ),
      );
      return false;
    }
  }

  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.toLowerCase().contains('ip address')) {
      return 'Payment could not be started from the server. '
          'Try again when paying the commitment fee.';
    }
    return msg.replaceFirst('Exception: ', '');
  }

  Future<bool> rejectOffer(String swapRequestId) async {
    emit(state.copyWith(actionInProgress: true, clearError: true));
    try {
      await _apiService.rejectSwapRequest(swapRequestId);
      await load();
      emit(state.copyWith(actionInProgress: false));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          actionInProgress: false,
          error: e.toString(),
        ),
      );
      return false;
    }
  }
}
