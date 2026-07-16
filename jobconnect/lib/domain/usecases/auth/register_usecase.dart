import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/i_auth_repository.dart';

class RegisterUseCase {
  final IAuthRepository repository;
  const RegisterUseCase(this.repository);

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) {
    return repository.register(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
    );
  }
}