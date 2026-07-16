import 'package:equatable/equatable.dart';

class SuccessConnection extends Equatable {
  final String connectionId;
  final String studentName;
  final String? studentPhotoUrl;
  final String companyName;
  final String? companyLogoUrl;
  final String position;
  final String confirmedAt;
  final List<String> studentSkills;

  const SuccessConnection({
    required this.connectionId,
    required this.studentName,
    this.studentPhotoUrl,
    required this.companyName,
    this.companyLogoUrl,
    required this.position,
    required this.confirmedAt,
    this.studentSkills = const [],
  });

  @override
  List<Object?> get props => [
        connectionId,
        studentName,
        studentPhotoUrl,
        companyName,
        companyLogoUrl,
        position,
        confirmedAt,
        studentSkills,
      ];
}

abstract class SuccessState extends Equatable {
  const SuccessState();

  @override
  List<Object?> get props => [];
}

class SuccessInitial extends SuccessState {
  const SuccessInitial();
}

class SuccessLoading extends SuccessState {
  const SuccessLoading();
}

class SuccessLoaded extends SuccessState {
  final List<SuccessConnection> connections;

  const SuccessLoaded({required this.connections});

  @override
  List<Object?> get props => [connections];
}

class SuccessError extends SuccessState {
  final String message;
  const SuccessError(this.message);

  @override
  List<Object?> get props => [message];
}