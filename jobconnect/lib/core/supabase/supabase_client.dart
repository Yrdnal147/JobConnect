import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientHelper {
  SupabaseClientHelper._();

  static SupabaseClient get client => Supabase.instance.client;

  static String? get currentUserId => client.auth.currentUser?.id;

  static bool get isLoggedIn => client.auth.currentUser != null;

  static String? get userRole =>
      client.auth.currentUser?.userMetadata?['role'] as String?;

  static String? get userStatus =>
      client.auth.currentUser?.userMetadata?['status'] as String?;
}
