import 'package:equatable/equatable.dart';

enum UserRole { student, company }

class AppUser extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
  });

  @override
  List<Object?> get props => [id, email, fullName, role];
}