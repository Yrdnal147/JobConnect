import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _authSubscription;

  FeedCubit({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        super(const FeedInitial()) {
    _authSubscription = _client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.userUpdated && state is FeedLoaded) {
        loadFeed();
      }
    });
  }

  // ─── Charge le feed ───────────────────────────────────────────────────────

  Future<void> loadFeed() async {
    emit(const FeedLoading());

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const FeedError('Utilisateur non connecté'));
        return;
      }

      final userName =
          user.userMetadata?['full_name'] as String? ?? 'Candidat';

      // Récupère le profil étudiant
      final profileRes = await _client
          .from('student_profiles')
          .select('id, profile_score, field_of_study, education_level, photo_url')
          .eq('user_id', user.id)
          .maybeSingle();

      final hasProfile = profileRes != null &&
          (profileRes['field_of_study'] != null ||
              profileRes['education_level'] != null);

      final profileScore     = profileRes?['profile_score'] as int? ?? 0;
      final photoUrl         = profileRes?['photo_url'] as String?;
      final studentProfileId = profileRes?['id'] as String?;

      // ── Lecture du feed_cache Mastra ──────────────────────────────────────
      // Si le pipeline cv-pipeline a déjà tourné, on lit les cards IA
      Map<String, int> mastraScores = {};
      if (studentProfileId != null) {
        try {
          final cacheRes = await _client
              .from('feed_cache')
              .select('cards, generated_at')
              .eq('student_id', studentProfileId)
              .maybeSingle();

          if (cacheRes != null && cacheRes['cards'] != null) {
            final cards = cacheRes['cards'] as List;
            for (final card in cards) {
              final offerId    = card['offerId'] as String?;
              final matchScore = card['matchScore'] as int?;
              if (offerId != null && matchScore != null) {
                mastraScores[offerId] = matchScore;
              }
            }
          }
        } catch (_) {}
      }

      // ── Récupère les offres actives ───────────────────────────────────────
      final offersRes = await _client
          .from('offers')
          .select('''
            id, title, offer_type, location, created_at,
            companies!inner(name, logo_url)
          ''')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(30);

      final offersRaw = offersRes as List;

      if (offersRaw.isEmpty) {
        emit(FeedLoaded(
          offers: [],
          userName: userName,
          photoUrl: photoUrl,
          hasProfile: hasProfile,
          profileScore: profileScore,
        ));
        return;
      }

      // ── Scores depuis les candidatures existantes (fallback 1) ────────────
      Map<String, int> applicationScores = {};
      if (hasProfile && studentProfileId != null) {
        try {
          final applicationsRes = await _client
              .from('applications')
              .select('offer_id, match_score')
              .eq('student_id', studentProfileId);

          for (final app in applicationsRes as List) {
            final offerId = app['offer_id'] as String;
            final score   = app['match_score'] as int? ?? 0;
            applicationScores[offerId] = score;
          }
        } catch (_) {}
      }

      // ── Construit la liste des offres avec priorité des scores ────────────
      // Priorité : 1. mastraScores (feed_cache IA) > 2. applicationScores > 3. simulé
      final List<FeedOffer> offers = offersRaw.map((offer) {
        final company = offer['companies'] as Map<String, dynamic>;
        final offerId = offer['id'] as String;
        final offerType = offer['offer_type'] as String? ?? '';

        final matchScore = mastraScores[offerId]       // Score IA Mastra
            ?? applicationScores[offerId]              // Score depuis candidature
            ?? _simulateScore(offerType, profileScore); // Simulé en fallback

        return FeedOffer(
          offerId: offerId,
          title: offer['title'] as String,
          companyName: company['name'] as String? ?? 'profile.default_name'.tr(),
          companyLogo: company['logo_url'] as String?,
          offerType: offerType,
          location: offer['location'] as String? ?? 'Douala',
          matchScore: matchScore,
          postedAt: _formatDate(offer['created_at'] as String?),
          isHighMatch: matchScore >= 75,
        );
      }).toList();

      // Trie par score si profil ou feed_cache disponible
      if (hasProfile || mastraScores.isNotEmpty) {
        offers.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      }

      // Filtrer les offres pour ne garder que celles qui sont au moins un minimum pertinentes (>= 30%)
      final relevantOffers = offers.where((o) => o.matchScore >= 30).toList();

      if (isClosed) return;
      emit(FeedLoaded(
        offers: relevantOffers,
        userName: userName,
        photoUrl: photoUrl,
        hasProfile: hasProfile || mastraScores.isNotEmpty,
        profileScore: profileScore,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(FeedError(e.toString()));
    }
  }

  // ─── Filtre par type ──────────────────────────────────────────────────────

  void filterOffers(String filter) {
    final current = state;
    if (current is FeedLoaded) {
      emit(current.copyWith(activeFilter: filter));
    }
  }

  // ─── Refresh ──────────────────────────────────────────────────────────────

  Future<void> refresh() => loadFeed();

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Fallback simulé quand ni Mastra ni les candidatures n'ont de score
  int _simulateScore(String offerType, int profileScore) {
    // Désactivé : on ne veut pas de scores artificiels pour les offres non-matchées.
    // L'IA Mastra donnera les vrais scores via pgvector.
    return 0;
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now  = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'time.today'.tr();
      if (diff.inDays == 1) return 'time.yesterday'.tr();
      if (diff.inDays < 7)  return 'time.days'.tr(args: [diff.inDays.toString()]);
      if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).round();
        return weeks > 1 
            ? 'time.weeks_plural'.tr(args: [weeks.toString()])
            : 'time.weeks_single'.tr(args: [weeks.toString()]);
      }
      return 'time.months'.tr(args: [(diff.inDays / 30).round().toString()]);
    } catch (_) {
      return '';
    }
  }
}