import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SupabaseClient _client;
  Timer? _debounce;

  static const _recentSearchesKey = 'recent_searches';
  static const _maxRecentSearches = 5;

  SearchCubit({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        super(const SearchInitial()) {
    _loadRecentSearches();
  }

  // ─── Recherches récentes (persistées localement) ──────────────────────────

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_recentSearchesKey) ?? [];
      emit(SearchInitial(recentSearches: saved));
    } catch (_) {
      emit(const SearchInitial());
    }
  }

  Future<void> _saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_recentSearchesKey) ?? [];

      current.remove(query); // évite les doublons
      current.insert(0, query);

      final trimmed = current.take(_maxRecentSearches).toList();
      await prefs.setStringList(_recentSearchesKey, trimmed);
    } catch (_) {}
  }

  Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
      emit(const SearchInitial(recentSearches: []));
    } catch (_) {}
  }

  // ─── Recherche avec debounce ────────────────────────────────────────────────

  void onQueryChanged(String query) {
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      _loadRecentSearches();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      search(query);
    });
  }

  // ─── Recherche immédiate (ex: tap sur tendance/récent) ────────────────────

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      _loadRecentSearches();
      return;
    }

    emit(const SearchLoading());

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const SearchError('Utilisateur non connecté'));
        return;
      }

      // Récupérer le profil étudiant pour le score de matching et le feed_cache
      String? profileId;
      Map<String, int> exactScores = {};
      try {
        final profileRes = await _client
            .from('student_profiles')
            .select('id, profile_score')
            .eq('user_id', user.id)
            .maybeSingle();
        profileId = profileRes?['id'] as String?;

        if (profileId != null) {
          final feedCacheRes = await _client
              .from('feed_cache')
              .select('cards')
              .eq('student_id', profileId)
              .maybeSingle();
          
          if (feedCacheRes != null && feedCacheRes['cards'] != null) {
            final cards = feedCacheRes['cards'] as List;
            for (var card in cards) {
              if (card['offerId'] != null && card['matchScore'] != null) {
                exactScores[card['offerId'] as String] = card['matchScore'] as int;
              }
            }
          }
        }
      } catch (_) {}

      // Recherche sur titre — Postgres full text simple via ilike
      final titleMatches = await _client
          .from('offers')
          .select('''
            id, title, offer_type, location, required_skills,
            companies!inner(name, logo_url)
          ''')
          .eq('is_active', true)
          .ilike('title', '%$trimmed%')
          .limit(20);

      // Recherche sur nom d'entreprise
      final companyMatches = await _client
          .from('offers')
          .select('''
            id, title, offer_type, location, required_skills,
            companies!inner(name, logo_url)
          ''')
          .eq('is_active', true)
          .filter('companies.name', 'ilike', '%$trimmed%')
          .limit(20);

      // Recherche sur compétences (array contains, insensible à la casse)
      final skillMatches = await _client
          .from('offers')
          .select('''
            id, title, offer_type, location, required_skills,
            companies!inner(name, logo_url)
          ''')
          .eq('is_active', true)
          .contains('required_skills', [trimmed])
          .limit(20);

      // Fusionne et déduplique par id
      final Map<String, Map<String, dynamic>> merged = {};
      for (final row in [
        ...(titleMatches as List),
        ...(companyMatches as List),
        ...(skillMatches as List),
      ]) {
        final id = row['id'] as String;
        merged[id] = row as Map<String, dynamic>;
      }

      final results = merged.values.map((offer) {
        final company = offer['companies'] as Map<String, dynamic>;
        final offerType = offer['offer_type'] as String? ?? '';
        final skills = List<String>.from(offer['required_skills'] as List? ?? []);

        return SearchOfferItem(
          offerId: offer['id'] as String,
          title: offer['title'] as String,
          companyName: company['name'] as String? ?? 'Entreprise',
          companyLogo: company['logo_url'] as String?,
          offerType: offerType,
          location: offer['location'] as String? ?? 'Douala',
          matchScore: exactScores[offer['id'] as String] ?? 0,
          requiredSkills: skills,
        );
      }).toList();

      // Trie par score décroissant
      results.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      await _saveRecentSearch(trimmed);

      emit(SearchLoaded(results: results, query: trimmed));
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  // ─── Filtre par type de contrat (sans appel réseau) ────────────────────────

  void filterByType(String filter) {
    final current = state;
    if (current is SearchLoaded) {
      emit(current.copyWith(activeFilter: filter));
    }
  }

  // ─── Helper score simulé (même logique que FeedCubit) ─────────────────────

  int _simulateScore(String offerType, int profileScore) {
    if (profileScore == 0) return 0;
    final base = (profileScore * 0.8).round();
    switch (offerType) {
      case 'stage_academique':
      case 'stage_professionnel':
        return (base + 10).clamp(0, 100);
      case 'cdi':
        return (base - 5).clamp(0, 100);
      default:
        return base.clamp(0, 100);
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}