import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  final SupabaseClient _client;

  DashboardCubit({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      super(const DashboardInitial());

  Future<void> loadDashboard() async {
    emit(const DashboardLoading());

    try {
      final user = _client.auth.currentUser;
      final companyName =
          user?.userMetadata?['full_name'] as String? ?? 'Entreprise';

      // Récupère la ligne entreprise
      final companyRow = await _client
          .from('companies')
          .select('id, logo_url')
          .eq('user_id', user!.id)
          .maybeSingle();

      if (companyRow == null) {
        emit(
          DashboardLoaded(
            companyName: companyName,
            metrics: const DashboardMetrics(),
            recentApplications: [],
          ),
        );
        return;
      }

      final companyId = companyRow['id'] as String;
      final companyLogo = companyRow['logo_url'] as String?;

      // ── Requêtes séparées pour éviter les erreurs de jointure ─────────────

      // 1. Offres actives
      int activeOffers = 0;
      try {
        final res = await _client
            .from('offers')
            .select('id')
            .eq('company_id', companyId)
            .eq('is_active', true);
        activeOffers = (res as List).length;
      } catch (_) {}

      // 2. Total candidatures
      int totalApplications = 0;
      try {
        final res = await _client
            .from('applications')
            .select('id')
            .eq('company_id', companyId);
        totalApplications = (res as List).length;
      } catch (_) {}

      // 3. Candidats retenus
      int retainedCandidates = 0;
      try {
        final res = await _client
            .from('applications')
            .select('id')
            .eq('company_id', companyId)
            .eq('status', 'retained');
        retainedCandidates = (res as List).length;
      } catch (_) {}

      // 4. Messages non lus — requête simplifiée
      int unreadMessages = 0;
      try {
        final convRes = await _client
            .from('conversations')
            .select('id')
            .eq('company_id', companyId);

        if ((convRes as List).isNotEmpty) {
          final convIds = convRes.map((c) => c['id'] as String).toList();
          final msgRes = await _client
              .from('messages')
              .select('id')
              .inFilter('conversation_id', convIds)
              .eq('is_read', false)
              .neq('sender_id', user.id);
          unreadMessages = (msgRes as List).length;
        }
      } catch (_) {}

      // 5. Candidatures récentes — jointure simplifiée
      List<RecentApplication> recentApplications = [];
      try {
        final appsRes = await _client
            .from('applications')
            .select('id, match_score, student_id')
            .eq('company_id', companyId)
            .order('created_at', ascending: false)
            .limit(5);

        final apps = appsRes as List;

        for (final app in apps) {
          try {
            final studentId = app['student_id'] as String;
            final profileRes = await _client
                .from('student_profiles')
                .select('full_name, field_of_study, education_level, photo_url')
                .eq('id', studentId)
                .maybeSingle();

            if (profileRes != null) {
              recentApplications.add(
                RecentApplication(
                  applicationId: app['id'] as String,
                  studentName: profileRes['full_name'] as String? ?? 'Candidat',
                  fieldOfStudy:
                      profileRes['field_of_study'] as String? ??
                      'Non renseigné',
                  educationLevel:
                      profileRes['education_level'] as String? ?? '',
                  matchScore: app['match_score'] as int? ?? 0,
                  photoUrl: profileRes['photo_url'] as String?,
                ),
              );
            }
          } catch (_) {}
        }
      } catch (_) {}

      emit(
        DashboardLoaded(
          companyName: companyName,
          companyLogo: companyLogo,
          metrics: DashboardMetrics(
            activeOffers: activeOffers,
            totalApplications: totalApplications,
            retainedCandidates: retainedCandidates,
            unreadMessages: unreadMessages,
          ),
          recentApplications: recentApplications,
        ),
      );
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<void> refresh() => loadDashboard();
}
