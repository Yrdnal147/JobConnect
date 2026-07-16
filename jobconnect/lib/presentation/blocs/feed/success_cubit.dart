import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'success_state.dart';


class SuccessCubit extends Cubit<SuccessState> {
  final SupabaseClient _client;

  SuccessCubit({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        super(const SuccessInitial());

  // ─── Charge les connexions réussies ──────────────────────────────────────

  Future<void> loadConnections() async {
    emit(const SuccessLoading());

    try {
      // Récupère toutes les connexions confirmées
      final connectionsRes = await _client
          .from('connections')
          .select('''
            id, position, confirmed_at,
            student_profiles!inner(
              full_name, photo_url, id
            ),
            companies!inner(
              name, logo_url
            )
          ''')
          .eq('confirmed_by_student', true)
          .eq('confirmed_by_company', true)
          .order('confirmed_at', ascending: false)
          .limit(20);

      final connectionsRaw = connectionsRes as List;

      if (connectionsRaw.isEmpty) {
        emit(const SuccessLoaded(connections: []));
        return;
      }

      final List<SuccessConnection> connections = [];

      for (final conn in connectionsRaw) {
        try {
          final student = conn['student_profiles'] as Map<String, dynamic>;
          final company = conn['companies'] as Map<String, dynamic>;
          final studentId = student['id'] as String;

          // Charge les compétences de l'étudiant
          List<String> skills = [];
          try {
            final skillsRes = await _client
                .from('skills')
                .select('name')
                .eq('student_id', studentId)
                .limit(5);

            skills = (skillsRes as List)
                .map((s) => s['name'] as String)
                .toList();
          } catch (_) {}

          connections.add(SuccessConnection(
            connectionId: conn['id'] as String,
            studentName: student['full_name'] as String? ?? 'Étudiant',
            studentPhotoUrl: student['photo_url'] as String?,
            companyName: company['name'] as String? ?? 'Entreprise',
            companyLogoUrl: company['logo_url'] as String?,
            position: conn['position'] as String? ?? 'Poste',
            confirmedAt: _formatDate(conn['confirmed_at'] as String?),
            studentSkills: skills,
          ));
        } catch (_) {
          continue;
        }
      }

      emit(SuccessLoaded(connections: connections));
    } catch (e) {
      emit(SuccessError(e.toString()));
    }
  }

  // ─── Refresh ──────────────────────────────────────────────────────────────

  Future<void> refresh() => loadConnections();

  // ─── Helper ───────────────────────────────────────────────────────────────

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      const months = [
        'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }
}