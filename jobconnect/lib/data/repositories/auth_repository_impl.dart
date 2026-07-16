import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart' as app_exceptions;
import '../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_datasource.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthDataSource dataSource;
  const AuthRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, AppUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await dataSource.login(email: email, password: password);
      return Right(user);
    } on app_exceptions.AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Une erreur inattendue est survenue.'));
    }
  }

  @override
  Future<Either<Failure, AppUser>> register({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final roleString = role == UserRole.company ? 'company' : 'student';
      final user = await dataSource.register(
        email: email,
        password: password,
        fullName: fullName,
        role: roleString,
      );
      return Right(user);
    } on app_exceptions.AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Une erreur inattendue est survenue.'));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(String oldPassword, String newPassword) async {
    try {
      await dataSource.changePassword(oldPassword: oldPassword, newPassword: newPassword);
      return const Right(null);
    } on app_exceptions.AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Une erreur inattendue est survenue.'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await dataSource.logout();
      return const Right(null);
    } on app_exceptions.ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Erreur lors de la déconnexion.'));
    }
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    try {
      final user = await dataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(ServerFailure('Impossible de récupérer l\'utilisateur.'));
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => dataSource.authStateChanges;
}