import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';

class CompanyDataSource {
  final SupabaseClient _client;

  CompanyDataSource({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // ─── Read ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchCompanyProfile() async {
    try {
      final userId = _currentUserId;

      final response = await _client
          .from('companies')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ─── Create / Update ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> saveCompanyProfile({
    required String name,
    required String sector,
    required String size,
    required String description,
    required String ceoName,
    required String website,
    required String location,
    String? logoUrl,
  }) async {
    try {
      final userId = _currentUserId;

      final existing = await _client
          .from('companies')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      final payload = {
        'user_id': userId,
        'name': name,
        'sector': sector,
        'size': size.isEmpty ? null : size,
        'description': description,
        'ceo_name': ceoName,
        'website': website,
        'location': location.isEmpty ? 'Douala' : location,
        if (logoUrl != null) 'logo_url': logoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        final response = await _client
            .from('companies')
            .update(payload)
            .eq('user_id', userId)
            .select()
            .single();
        return response;
      } else {
        final response = await _client
            .from('companies')
            .insert(payload)
            .select()
            .single();
        return response;
      }
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ─── Logo upload ─────────────────────────────────────────────────────────

  Future<String> uploadCompanyLogo(File imageFile) async {
    try {
      final userId = _currentUserId;
      final ext = imageFile.path.split('.').last;
      final ts = DateTime.now().millisecondsSinceEpoch; // ← timestamp anti-cache
      final fileName = '$userId/logo_$ts.$ext';         // ← userId en premier segment

      await _client.storage.from('company-assets').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          _client.storage.from('company-assets').getPublicUrl(fileName);

      return publicUrl;
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ─── Verification ────────────────────────────────────────────────────────

  Future<void> submitRccmDocument(File document) async {
    try {
      final userId = _currentUserId;
      final ext = document.path.split('.').last;
      final fileName = '$userId/rccm.$ext'; // ← userId en premier segment

      await _client.storage.from('verification-docs').upload( // ← bon bucket
            fileName,
            document,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl =
          _client.storage.from('verification-docs').getPublicUrl(fileName);

      await _client.from('companies').update({
        'rccm_url': publicUrl,
        'verification_status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } on StorageException catch (e) {
      throw ServerException(e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ─── Helper ──────────────────────────────────────────────────────────────

  String get _currentUserId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const ServerException('Utilisateur non connecté');
    }
    return userId;
  }
}