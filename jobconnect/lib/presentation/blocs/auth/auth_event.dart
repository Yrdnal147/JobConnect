import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final UserRole role;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
  });

  @override
  List<Object?> get props => [email, password, fullName, role];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  const AuthChangePasswordRequested(this.oldPassword, this.newPassword);

  @override
  List<Object?> get props => [oldPassword, newPassword];
}