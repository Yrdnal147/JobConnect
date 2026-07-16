import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'all_candidates_state.dart';

class AllCandidatesCubit extends Cubit<AllCandidatesState> {
  final SupabaseClient _client;
  String? _currentOfferId;

  AllCandidatesCubit({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        super(const AllCandidatesInitial());

  // ─── Charge les candidatures (toutes ou filtrées par offre) ──────────────

  Future<void> loadCandidates({String? offerId}) async {
    _currentOfferId = offerId;
    emit(const AllCandidatesLoading());

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const AllCandidatesError('Utilisateur non connecté'));
        return;
      }

      // Récupère l'id de l'entreprise
      final companyRow = await _client
          .from('companies')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (companyRow == null) {
        emit(const AllCandidatesLoaded(candidates: []));
        return;
      }

      final companyId = companyRow['id'] as String;

      // Récupère les candidatures — filtrées par offre si offerId fourni
      var query = _client
          .from('applications')
          .select('id, match_score, status, student_id, offer_id')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      // Filtre par offre si spécifié
      final appsRes = offerId != null
          ? await _client
              .from('applications')
              .select('id, match_score, status, student_id, offer_id')
              .eq('company_id', companyId)
              .eq('offer_id', offerId)
              .order('created_at', ascending: false)
          : await query;

      final apps = appsRes as List;

      if (apps.isEmpty) {
        emit(const AllCandidatesLoaded(candidates: []));
        return;
      }

      // Récupère les infos de chaque candidat
      final List<CandidateItem> candidates = [];

      for (final app in apps) {
        try {
          final studentId = app['student_id'] as String;
          final appOfferId = app['offer_id'] as String;

          // Profil étudiant
          final profileRes = await _client
              .from('student_profiles')
              .select('full_name, field_of_study, education_level, photo_url')
              .eq('id', studentId)
              .maybeSingle();

          // Titre de l'offre
          final offerRes = await _client
              .from('offers')
              .select('title')
              .eq('id', appOfferId)
              .maybeSingle();

          if (profileRes != null) {
            candidates.add(CandidateItem(
              applicationId: app['id'] as String,
              studentName: profileRes['full_name'] as String? ?? 'Candidat',
              offerTitle: offerRes?['title'] as String? ?? 'Offre',
              status: app['status'] as String? ?? 'pending',
              matchScore: app['match_score'] as int? ?? 0,
              photoUrl: profileRes['photo_url'] as String?,
              educationLevel: profileRes['education_level'] as String? ?? '',
              fieldOfStudy: profileRes['field_of_study'] as String? ?? '',
            ));
          }
        } catch (_) {
          continue;
        }
      }

      emit(AllCandidatesLoaded(candidates: candidates));
    } catch (e) {
      emit(AllCandidatesError(e.toString()));
    }
  }

  // ─── Filtre par statut (sans appel réseau) ────────────────────────────────

  void filterByStatus(String status) {
    final current = state;
    if (current is AllCandidatesLoaded) {
      emit(current.copyWith(filterStatus: status));
    }
  }

  // ─── Refresh ──────────────────────────────────────────────────────────────

  Future<void> refresh() => loadCandidates(offerId: _currentOfferId);
}