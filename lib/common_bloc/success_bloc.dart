import 'package:swappro/barrel.dart';

class SuccessBloc extends Bloc<SuccessEvent, SuccessState> {
  SuccessBloc() : super(const SuccessInitial()) {
    on<ShowSuccessEvent>(_onShowSuccess);
    on<ClearSuccessEvent>(_onClearSuccess);
  }

  Future<void> _onShowSuccess(
    ShowSuccessEvent event,
    Emitter<SuccessState> emit,
  ) async {
    emit(
      SuccessDisplaying(
        message: event.message,
        nextScreen: event.nextScreen,
        userEmail: event.userEmail,
      ),
    );
  }

  Future<void> _onClearSuccess(
    ClearSuccessEvent event,
    Emitter<SuccessState> emit,
  ) async {
    emit(const SuccessCleared());
    emit(const SuccessInitial());
  }
}
