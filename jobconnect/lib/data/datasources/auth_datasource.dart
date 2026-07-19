import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../core/errors/exceptions.dart' as app_exceptions;
import '../models/user_model.dart';

abstract class IAuthDataSource {
  Future<UserModel> login({required String email, required String password});

  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  });

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<void> logout();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;
}

class AuthDataSourceImpl implements IAuthDataSource {
  final supa.SupabaseClient client;
  const AuthDataSourceImpl(this.client);

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const app_exceptions.AuthException(
          'Connexion impossible. Vérifiez vos identifiants.',
        );
      }

      return UserModel.fromSupabaseUser(response.user!);
    } on supa.AuthException catch (e) {
      throw app_exceptions.AuthException(e.message);
    } catch (e) {
      throw app_exceptions.ServerException(
        'Une erreur est survenue. Réessayez.',
      );
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'role': role},
      );

      if (response.user == null) {
        throw const app_exceptions.AuthException(
          'Inscription impossible. Réessayez.',
        );
      }

      return UserModel.fromSupabaseUser(response.user!);
    } on supa.AuthException catch (e) {
      throw app_exceptions.AuthException(e.message);
    } catch (e) {
      throw app_exceptions.ServerException(
        'Une erreur est survenue. Réessayez.',
      );
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null || user.email == null) {
        throw const app_exceptions.AuthException('Utilisateur non connecté.');
      }

      // 1. Vérifier l'ancien mot de passe en tentant une reconnexion
      await client.auth.signInWithPassword(
        email: user.email!,
        password: oldPassword,
      );

      // 2. Si succès, mettre à jour le mot de passe
      final response = await client.auth.updateUser(
        supa.UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw const app_exceptions.AuthException(
          'Impossible de modifier le mot de passe.',
        );
      }
    } on supa.AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        throw const app_exceptions.AuthException(
          'L\'ancien mot de passe est incorrect.',
        );
      }
      throw app_exceptions.AuthException(e.message);
    } catch (e) {
      throw app_exceptions.ServerException(
        'Une erreur est survenue lors du changement de mot de passe.',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw app_exceptions.ServerException('Erreur lors de la déconnexion.');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    return UserModel.fromSupabaseUser(user);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user;
      if (user == null) return null;
      return UserModel.fromSupabaseUser(user);
    });
  }
}
