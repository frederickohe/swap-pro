import 'package:swappro/barrel.dart';

class SwapRequestState extends Equatable {
  const SwapRequestState({
    this.target,
    this.offer,
    this.submitting = false,
    this.error,
    this.createdSwapRequest,
  });

  final PropertyDetailData? target;
  final PropertyDetailData? offer;
  final bool submitting;
  final String? error;
  final Map<String, dynamic>? createdSwapRequest;

  SwapRequestState copyWith({
    PropertyDetailData? target,
    PropertyDetailData? offer,
    bool? submitting,
    String? error,
    Map<String, dynamic>? createdSwapRequest,
    bool clearError = false,
    bool clearCreated = false,
  }) {
    return SwapRequestState(
      target: target ?? this.target,
      offer: offer ?? this.offer,
      submitting: submitting ?? this.submitting,
      error: clearError ? null : (error ?? this.error),
      createdSwapRequest:
          clearCreated ? null : (createdSwapRequest ?? this.createdSwapRequest),
    );
  }

  @override
  List<Object?> get props => [
        target,
        offer,
        submitting,
        error,
        createdSwapRequest,
      ];
}

class SwapRequestCubit extends Cubit<SwapRequestState> {
  SwapRequestCubit({required ApiService apiService})
      : _apiService = apiService,
        super(const SwapRequestState());

  final ApiService _apiService;

  void start({required PropertyDetailData target}) {
    emit(
      SwapRequestState(
        target: target,
        offer: null,
        submitting: false,
        error: null,
        createdSwapRequest: null,
      ),
    );
  }

  void selectOffer(PropertyDetailData offer) {
    emit(state.copyWith(offer: offer, clearError: true, clearCreated: true));
  }

  void reset() {
    emit(const SwapRequestState());
  }

  bool get canSubmit {
    final targetId = state.target?.listingId?.trim();
    final offerId = state.offer?.listingId?.trim();
    return targetId != null &&
        targetId.isNotEmpty &&
        offerId != null &&
        offerId.isNotEmpty;
  }

  Future<Map<String, dynamic>?> submit() async {
    final target = state.target;
    final offer = state.offer;

    final targetId = target?.listingId?.trim();
    final offerId = offer?.listingId?.trim();

    if (target == null || targetId == null || targetId.isEmpty) {
      emit(state.copyWith(error: 'Missing target listing id.'));
      return null;
    }
    if (offer == null || offerId == null || offerId.isEmpty) {
      emit(state.copyWith(error: 'Please select a listing to offer.'));
      return null;
    }

    emit(state.copyWith(submitting: true, clearError: true));
    try {
      final created = await _apiService.createSwapRequest(
        targetListingId: targetId,
        offerListingId: offerId,
      );
      emit(
        state.copyWith(
          submitting: false,
          createdSwapRequest: created,
        ),
      );
      return created;
    } catch (e) {
      emit(state.copyWith(submitting: false, error: e.toString()));
      return null;
    }
  }
}

