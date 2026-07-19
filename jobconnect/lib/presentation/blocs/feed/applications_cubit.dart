import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'applications_state.dart';

class ApplicationsCubit extends Cubit<ApplicationsState> {
  final SupabaseClient _client;

  ApplicationsCubit({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      super(const ApplicationsInitial());

  // ─── Charge toutes les candidatures ──────────────────────────────────────

  Future<void> loadApplications() async {
    emit(const ApplicationsLoading());

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const ApplicationsError('Utilisateur non connecté'));
        return;
      }

      // Récupère le profil étudiant
      final profileRes = await _client
          .from('student_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profileRes == null) {
        emit(const ApplicationsLoaded(applications: []));
        return;
      }

      final studentId = profileRes['id'] as String;

      // Récupère les scores à jour depuis le cache de l'IA
      Map<String, int> latestScores = {};
      try {
        final cacheRes = await _client
            .from('feed_cache')
            .select('cards')
            .eq('student_id', studentId)
            .maybeSingle();

        if (cacheRes != null && cacheRes['cards'] != null) {
          for (final c in cacheRes['cards'] as List) {
            if (c['offerId'] != null && c['matchScore'] != null) {
              latestScores[c['offerId'] as String] = c['matchScore'] as int;
            }
          }
        }
      } catch (_) {}

      // Récupère les candidatures
      final appsRes = await _client
          .from('applications')
          .select('''
            id, status, match_score, created_at,
            offer_id, company_id,
            offers!inner(title, offer_type),
            companies!inner(name, logo_url)
          ''')
          .eq('student_id', studentId)
          .order('created_at', ascending: false);

      final appsRaw = appsRes as List;

      if (appsRaw.isEmpty) {
        emit(const ApplicationsLoaded(applications: []));
        return;
      }

      final List<ApplicationItem> applications = [];

      for (final app in appsRaw) {
        try {
          final offer = app['offers'] as Map<String, dynamic>;
          final company = app['companies'] as Map<String, dynamic>;

          // Vérifie si une conversation existe
          String? conversationId;
          try {
            final convRes = await _client
                .from('conversations')
                .select('id')
                .eq('application_id', app['id'] as String)
                .maybeSingle();
            conversationId = convRes?['id'] as String?;
          } catch (_) {}

          applications.add(
            ApplicationItem(
              applicationId: app['id'] as String,
              offerId: app['offer_id'] as String,
              offerTitle: offer['title'] as String,
              companyName: company['name'] as String? ?? 'Entreprise',
              companyLogoUrl: company['logo_url'] as String?,
              companyId: app['company_id'] as String,
              status: app['status'] as String? ?? 'pending',
              matchScore:
                  latestScores[app['offer_id'] as String] ??
                  (app['match_score'] as int? ?? 0),
              appliedAt: _formatDate(app['created_at'] as String?),
              conversationId: conversationId,
            ),
          );
        } catch (_) {
          continue;
        }
      }

      emit(ApplicationsLoaded(applications: applications));
    } catch (e) {
      emit(ApplicationsError(e.toString()));
    }
  }

  // ─── Filtre par statut ────────────────────────────────────────────────────

  void filterByStatus(String filter) {
    final current = state;
    if (current is ApplicationsLoaded) {
      emit(current.copyWith(activeFilter: filter));
    }
  }

  // ─── Charge le détail d'une candidature ──────────────────────────────────

  Future<void> loadApplicationDetail(String applicationId) async {
    emit(const ApplicationDetailLoading());

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const ApplicationDetailError('Utilisateur non connecté'));
        return;
      }

      // Récupère la candidature avec offre et entreprise
      final appRes = await _client
          .from('applications')
          .select('''
            id, status, match_score, created_at, status_explanation,
            offer_id, company_id, student_id,
            offers!inner(title, offer_type, required_skills),
            companies!inner(name, logo_url)
          ''')
          .eq('id', applicationId)
          .maybeSingle();

      if (appRes == null) {
        emit(const ApplicationDetailError('Candidature introuvable'));
        return;
      }

      final offer = appRes['offers'] as Map<String, dynamic>;
      final company = appRes['companies'] as Map<String, dynamic>;
      final status = appRes['status'] as String? ?? 'pending';

      // Récupère le score en temps réel
      int matchScore = appRes['match_score'] as int? ?? 0;
      try {
        final cacheRes = await _client
            .from('feed_cache')
            .select('cards')
            .eq('student_id', appRes['student_id'] as String)
            .maybeSingle();
        if (cacheRes != null && cacheRes['cards'] != null) {
          for (final c in cacheRes['cards'] as List) {
            if (c['offerId'] == appRes['offer_id']) {
              matchScore = c['matchScore'] as int;
              break;
            }
          }
        }
      } catch (_) {}

      // Compétences manquantes (si refusé)
      List<String> missingSkills = [];
      if (status == 'refused') {
        try {
          final requiredSkills = List<String>.from(
            offer['required_skills'] as List? ?? [],
          );

          final skillsRes = await _client
              .from('skills')
              .select('name')
              .eq('student_id', appRes['student_id'] as String);

          final studentSkills = (skillsRes as List)
              .map((s) => (s['name'] as String).toLowerCase())
              .toList();

          missingSkills = requiredSkills
              .where((s) => !studentSkills.contains(s.toLowerCase()))
              .toList();
        } catch (_) {}
      }

      // Offres similaires (si en attente)
      List<SimilarOffer> similarOffers = [];
      if (status == 'pending') {
        try {
          final similarRes = await _client
              .from('offers')
              .select('id, title, offer_type, companies!inner(name)')
              .eq('is_active', true)
              .eq('offer_type', offer['offer_type'] as String)
              .neq('id', appRes['offer_id'] as String)
              .limit(3);

          similarOffers = (similarRes as List).map((o) {
            final c = o['companies'] as Map<String, dynamic>;
            return SimilarOffer(
              offerId: o['id'] as String,
              title: o['title'] as String,
              companyName: c['name'] as String? ?? 'Entreprise',
              offerType: o['offer_type'] as String? ?? '',
            );
          }).toList();
        } catch (_) {}
      }

      // Conversation existante (si retenu)
      String? conversationId;
      if (status == 'retained') {
        try {
          final convRes = await _client
              .from('conversations')
              .select('id')
              .eq('application_id', appRes['id'] as String)
              .maybeSingle();
          conversationId = convRes?['id'] as String?;
        } catch (_) {}
      }

      String? explanationStr;
      if (appRes['status_explanation'] != null) {
        final val = appRes['status_explanation'];
        explanationStr = val is String ? val : jsonEncode(val);
      }

      emit(
        ApplicationDetailLoaded(
          detail: ApplicationDetail(
            applicationId: appRes['id'] as String,
            offerTitle: offer['title'] as String,
            offerType: offer['offer_type'] as String? ?? '',
            companyName: company['name'] as String? ?? 'Entreprise',
            companyLogoUrl: company['logo_url'] as String?,
            status: status,
            matchScore: matchScore,
            appliedAt: _formatDate(appRes['created_at'] as String?),
            conversationId: conversationId,
            missingSkills: missingSkills,
            similarOffers: similarOffers,
            statusExplanation: explanationStr,
          ),
        ),
      );
    } catch (e) {
      emit(ApplicationDetailError(e.toString()));
    }
  }

  // ─── Refresh ──────────────────────────────────────────────────────────────

  Future<void> refresh() => loadApplications();

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
