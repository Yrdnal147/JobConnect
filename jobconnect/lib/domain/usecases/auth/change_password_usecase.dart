import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/i_auth_repository.dart';

class ChangePasswordUseCase {
  final IAuthRepository repository;

  ChangePasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String oldPassword, String newPassword) {
    return repository.changePassword(oldPassword, newPassword);
  }
}
