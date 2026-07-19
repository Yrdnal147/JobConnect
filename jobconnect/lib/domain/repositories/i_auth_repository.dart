import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class IAuthRepository {
  Future<Either<Failure, AppUser>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser>> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  });

  Future<Either<Failure, void>> changePassword(
    String oldPassword,
    String newPassword,
  );

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, AppUser?>> getCurrentUser();

  Stream<AppUser?> get authStateChanges;
}
