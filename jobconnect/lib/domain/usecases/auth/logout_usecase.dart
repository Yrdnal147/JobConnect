import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/i_auth_repository.dart';

class LogoutUseCase {
  final IAuthRepository repository;
  const LogoutUseCase(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.logout();
  }
}
