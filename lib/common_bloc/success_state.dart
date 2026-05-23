import 'package:swappro/barrel.dart';

abstract class SuccessState extends Equatable {
  const SuccessState();

  @override
  List<Object?> get props => [];
}

class SuccessInitial extends SuccessState {
  const SuccessInitial();
}

class SuccessDisplaying extends SuccessState {
  final String message;
  final String nextScreen;
  final String userEmail;

  const SuccessDisplaying({
    required this.message,
    required this.nextScreen,
    this.userEmail = '',
  });
}

class SuccessCleared extends SuccessState {
  const SuccessCleared();
}
