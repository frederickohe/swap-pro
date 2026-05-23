import 'package:swappro/barrel.dart';

abstract class SuccessEvent extends Equatable {
  const SuccessEvent();

  @override
  List<Object?> get props => [];
}

class ShowSuccessEvent extends SuccessEvent {
  final String message;
  final String nextScreen;
  final String userEmail;

  const ShowSuccessEvent({
    required this.message,
    required this.nextScreen,
    this.userEmail = '',
  });
}

class ClearSuccessEvent extends SuccessEvent {
  const ClearSuccessEvent();
}
