import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../domain/entities/user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.email,
    super.fullName,
    required super.role,
  });

  factory UserModel.fromSupabaseUser(supa.User user) {
    final metadata = user.userMetadata;
    final roleString = metadata?['role'] as String? ?? 'student';

    return UserModel(
      id: user.id,
      email: user.email ?? '',
      fullName: metadata?['full_name'] as String?,
      role: roleString == 'company' ? UserRole.company : UserRole.student,
    );
  }
}