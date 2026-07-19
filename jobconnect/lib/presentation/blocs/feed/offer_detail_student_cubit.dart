import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/dio_client.dart';
import 'offer_detail_student_state.dart';

class OfferDetailStudentCubit extends Cubit<OfferDetailStudentState> {
  final SupabaseClient _client;

  OfferDetailStudentCubit({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      super(const OfferDetailStudentInitial());

  // ─── Charge les détails de l'offre ───────────────────────────────────────

  Future<void> loadOffer(String offerId) async {
    emit(const OfferDetailStudentLoading());

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(
          const OfferDetailStudentError(message: 'Utilisateur non connecté'),
        );
        return;
      }

      // Charge l'offre avec les infos entreprise
      final offerRes = await _client
          .from('offers')
          .select('''
            id, title, offer_type, location, description,
            required_skills, min_education, years_of_experience,
            salary_range, duration_months, created_at,
            companies!inner(id, name, is_verified, logo_url)
          ''')
          .eq('id', offerId)
          .maybeSingle();

      if (offerRes == null) {
        emit(const OfferDetailStudentError(message: 'Offre introuvable'));
        return;
      }

      final company = offerRes['companies'] as Map<String, dynamic>;
      final requiredSkills = List<String>.from(
        offerRes['required_skills'] as List? ?? [],
      );

      // Charge le profil étudiant pour comparer les compétences
      List<String> studentSkills = [];
      String? studentProfileId;
      int matchScore = 0;

      try {
        final profileRes = await _client
            .from('student_profiles')
            .select('id, profile_score')
            .eq('user_id', user.id)
            .maybeSingle();

        if (profileRes != null) {
          studentProfileId = profileRes['id'] as String;

          // Recherche du vrai matchScore dans le feed_cache
          try {
            final cacheRes = await _client
                .from('feed_cache')
                .select('cards')
                .eq('student_id', studentProfileId)
                .maybeSingle();

            if (cacheRes != null && cacheRes['cards'] != null) {
              final offersList = cacheRes['cards'] as List;
              for (final o in offersList) {
                if (o['offerId'] == offerId) {
                  matchScore = o['matchScore'] as int? ?? 0;
                  break;
                }
              }
            }
          } catch (_) {}

          // Charge les compétences de l'étudiant
          final skillsRes = await _client
              .from('skills')
              .select('name')
              .eq('student_id', studentProfileId);

          studentSkills = (skillsRes as List)
              .map((s) => s['name'] as String)
              .toList();
        }
      } catch (_) {}

      // Calcule les compétences matching et manquantes
      final matchingSkills = requiredSkills
          .where(
            (skill) => studentSkills.any(
              (s) => s.toLowerCase() == skill.toLowerCase(),
            ),
          )
          .toList();

      final missingSkills = requiredSkills
          .where(
            (skill) => !studentSkills.any(
              (s) => s.toLowerCase() == skill.toLowerCase(),
            ),
          )
          .toList();

      // Vérifie si l'étudiant a déjà postulé
      bool hasAlreadyApplied = false;
      if (studentProfileId != null) {
        try {
          final appRes = await _client
              .from('applications')
              .select('id')
              .eq('student_id', studentProfileId)
              .eq('offer_id', offerId)
              .maybeSingle();
          hasAlreadyApplied = appRes != null;
        } catch (_) {}
      }

      final offer = StudentOfferDetail(
        offerId: offerRes['id'] as String,
        title: offerRes['title'] as String,
        companyName: company['name'] as String? ?? 'Entreprise',
        companyId: company['id'] as String,
        isCompanyVerified: company['is_verified'] as bool? ?? false,
        companyLogo: company['logo_url'] as String?,
        offerType: offerRes['offer_type'] as String? ?? '',
        location: offerRes['location'] as String? ?? 'Douala',
        description: offerRes['description'] as String? ?? '',
        requiredSkills: requiredSkills,
        minEducation: offerRes['min_education'] as String? ?? '',
        yearsOfExperience: offerRes['years_of_experience'] as int? ?? 0,
        salaryRange: offerRes['salary_range'] as String?,
        durationMonths: offerRes['duration_months'] as int?,
        postedAt: _formatDate(offerRes['created_at'] as String?),
        matchScore: matchScore,
        matchingSkills: matchingSkills,
        missingSkills: missingSkills,
        hasAlreadyApplied: hasAlreadyApplied,
      );

      emit(OfferDetailStudentLoaded(offer: offer));
    } catch (e) {
      emit(OfferDetailStudentError(message: e.toString()));
    }
  }

  // ─── Coaching IA ──────────────────────────────────────────────────────────

  Future<void> fetchCoachingAdvice() async {
    final current = state;
    if (current is! OfferDetailStudentLoaded) return;

    // Si on a déjà le résultat ou si on est déjà en chargement, on ignore
    if (current.isCoachingLoading || current.coachResult != null) return;

    emit(current.copyWith(isCoachingLoading: true, coachError: null));

    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final dio = DioClient.instance;
      final response = await dio.post(
        '/api/agents/application-coach-agent/generate',
        data: {
          'input':
              'Fais un coaching pour l\'utilisateur ${user.id} sur l\'offre ${current.offer.offerId}',
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final result = response.data['response'];

        // La réponse de l'IA (text) est une string JSON, il faut parfois la parser
        Map<String, dynamic>? parsedResult;

        if (result is Map && result['text'] != null) {
          final textStr = result['text'] as String;
          try {
            // Cherche le début du JSON (parfois l'IA met du markdown ```json)
            final startIndex = textStr.indexOf('{');
            final endIndex = textStr.lastIndexOf('}') + 1;
            if (startIndex != -1 && endIndex != 0) {
              final jsonStr = textStr.substring(startIndex, endIndex);
              parsedResult = Map<String, dynamic>.from(
                // ignore: avoid_dynamic_calls
                const JsonDecoder().convert(jsonStr) as Map,
              );
            }
          } catch (e) {
            throw Exception('Impossible de lire la réponse du coach: $e');
          }
        }

        if (parsedResult != null) {
          emit(
            current.copyWith(
              isCoachingLoading: false,
              coachResult: parsedResult,
            ),
          );
        } else {
          throw Exception('Format de réponse invalide');
        }
      } else {
        throw Exception(response.data['error'] ?? 'Erreur serveur');
      }
    } catch (e) {
      emit(
        current.copyWith(
          isCoachingLoading: false,
          coachError: 'Impossible d\'obtenir les conseils IA : ${e.toString()}',
        ),
      );
    }
  }

  // ─── Toggle sauvegarde ────────────────────────────────────────────────────

  void toggleSave() {
    final current = state;
    if (current is OfferDetailStudentLoaded) {
      emit(current.copyWith(isSaved: !current.isSaved));
    }
  }

  // ─── Postuler ─────────────────────────────────────────────────────────────

  Future<void> applyToOffer() async {
    final current = state;
    if (current is! OfferDetailStudentLoaded) return;

    final offer = current.offer;

    if (offer.hasAlreadyApplied) {
      emit(
        OfferDetailStudentError(
          message: 'Vous avez déjà postulé à cette offre.',
          lastKnownOffer: offer,
        ),
      );
      _restoreLoaded(current);
      return;
    }

    emit(OfferDetailStudentApplying(offer: offer));

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(
          const OfferDetailStudentError(message: 'Utilisateur non connecté'),
        );
        return;
      }

      // Récupère le profil étudiant
      final profileRes = await _client
          .from('student_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profileRes == null) {
        emit(
          OfferDetailStudentError(
            message: 'Complétez votre profil avant de postuler.',
            lastKnownOffer: offer,
          ),
        );
        _restoreLoaded(current);
        return;
      }

      final studentId = profileRes['id'] as String;

      // Insère la candidature
      final appRes = await _client
          .from('applications')
          .insert({
            'student_id': studentId,
            'offer_id': offer.offerId,
            'company_id': offer.companyId,
            'status': 'pending',
            'match_score': offer.matchScore,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final applicationId = appRes['id'] as String;

      // Déclenche l'agent IA de statut en asynchrone (non bloquant)
      DioClient.instance
          .post(
            '/api/workflows/application-status-handler/start',
            data: {
              'input': {
                'applicationId': applicationId,
                'studentId': studentId,
                'offerId': offer.offerId,
                'status': 'pending',
              },
            },
          )
          .catchError((_) {}); // Erreurs ignorées pour ne pas bloquer l'UI

      // Met à jour l'offre pour marquer comme déjà postulé
      final updatedOffer = StudentOfferDetail(
        offerId: offer.offerId,
        title: offer.title,
        companyName: offer.companyName,
        companyId: offer.companyId,
        isCompanyVerified: offer.isCompanyVerified,
        offerType: offer.offerType,
        location: offer.location,
        description: offer.description,
        requiredSkills: offer.requiredSkills,
        minEducation: offer.minEducation,
        yearsOfExperience: offer.yearsOfExperience,
        salaryRange: offer.salaryRange,
        durationMonths: offer.durationMonths,
        postedAt: offer.postedAt,
        matchScore: offer.matchScore,
        matchingSkills: offer.matchingSkills,
        missingSkills: offer.missingSkills,
        hasAlreadyApplied: true,
      );

      emit(OfferDetailStudentApplied(offer: updatedOffer));

      // Retourne à l'état loaded après succès
      await Future.delayed(const Duration(seconds: 1));
      if (!isClosed) {
        emit(
          OfferDetailStudentLoaded(
            offer: updatedOffer,
            isSaved: current.isSaved,
          ),
        );
      }
    } catch (e) {
      emit(
        OfferDetailStudentError(
          message: 'Impossible de postuler : ${e.toString()}',
          lastKnownOffer: offer,
        ),
      );
      _restoreLoaded(current);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _restoreLoaded(OfferDetailStudentLoaded state) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) emit(state);
    });
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) return 'Aujourd\'hui';
      if (diff.inDays == 1) return 'Hier';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
      if (diff.inDays < 30) {
        return 'Il y a ${(diff.inDays / 7).round()} semaine${(diff.inDays / 7).round() > 1 ? 's' : ''}';
      }
      return 'Il y a ${(diff.inDays / 30).round()} mois';
    } catch (_) {
      return '';
    }
  }
}
