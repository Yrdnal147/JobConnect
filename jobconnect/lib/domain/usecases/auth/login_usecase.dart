import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/i_auth_repository.dart';

class LoginUseCase {
  final IAuthRepository repository;
  const LoginUseCase(this.repository);

  Future<Either<Failure, AppUser>> call({
    required String email,
    required String password,
  }) {
    return repository.login(email: email, password: password);
  }
}