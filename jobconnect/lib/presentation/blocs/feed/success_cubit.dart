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
      // Récupère toutes les candidatures acceptées
      final connectionsRes = await _client
          .from('applications')
          .select('''
            id, updated_at, match_score,
            student_profiles!inner(
              full_name, photo_url, id
            ),
            companies!inner(
              name, logo_url
            ),
            offers!inner(
              title
            )
          ''')
          .eq('status', 'retained')
          .order('updated_at', ascending: false)
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
          final offer = conn['offers'] as Map<String, dynamic>;
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

          connections.add(
            SuccessConnection(
              connectionId: conn['id'] as String,
              studentName: student['full_name'] as String? ?? 'Étudiant',
              studentPhotoUrl: student['photo_url'] as String?,
              companyName: company['name'] as String? ?? 'Entreprise',
              companyLogoUrl: company['logo_url'] as String?,
              position: offer['title'] as String? ?? 'Poste',
              confirmedAt: _formatDate(conn['updated_at'] as String?),
              studentSkills: skills,
              matchScore: conn['match_score'] as int? ?? 0,
            ),
          );
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
        'Jan',
        'Fév',
        'Mar',
        'Avr',
        'Mai',
        'Jun',
        'Jul',
        'Aoû',
        'Sep',
        'Oct',
        'Nov',
        'Déc',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }
}
