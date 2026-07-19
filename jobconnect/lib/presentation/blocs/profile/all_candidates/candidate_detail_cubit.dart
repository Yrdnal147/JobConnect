import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/dio_client.dart';
import 'candidate_detail_state.dart';

class CandidateDetailCubit extends Cubit<CandidateDetailState> {
  final SupabaseClient _client;

  CandidateDetailCubit({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      super(const CandidateDetailInitial());

  // ─── Charge le détail d'une candidature ──────────────────────────────────

  Future<void> loadCandidate(String applicationId) async {
    emit(const CandidateDetailLoading());

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const CandidateDetailError(message: 'Utilisateur non connecté'));
        return;
      }

      final appRes = await _client
          .from('applications')
          .select('id, student_id, offer_id, company_id, status, match_score')
          .eq('id', applicationId)
          .maybeSingle();

      if (appRes == null) {
        emit(const CandidateDetailError(message: 'Candidature introuvable'));
        return;
      }

      final studentId = appRes['student_id'] as String;
      final offerId = appRes['offer_id'] as String;
      final companyId = appRes['company_id'] as String;

      final profileRes = await _client
          .from('student_profiles')
          .select(
            'id, full_name, field_of_study, education_level, photo_url, cv_url',
          )
          .eq('id', studentId)
          .maybeSingle();

      final offerRes = await _client
          .from('offers')
          .select('title')
          .eq('id', offerId)
          .maybeSingle();

      // Compétences
      List<SkillDetail> skills = [];
      try {
        final skillsRes = await _client
            .from('skills')
            .select('name, skill_type')
            .eq('student_id', studentId);

        skills = (skillsRes as List)
            .map(
              (s) => SkillDetail(
                name: s['name'] as String,
                skillType: s['skill_type'] as String? ?? 'technical',
              ),
            )
            .toList();
      } catch (_) {}

      // Explication du score
      String? matchExplanation;
      try {
        final matchRes = await _client
            .from('applications')
            .select('match_explanation')
            .eq('id', applicationId)
            .maybeSingle();
        matchExplanation = matchRes?['match_explanation'] as String?;
      } catch (_) {}

      // ── Signed URL pour le CV ────────────────────────────────────
      String? cvUrl = profileRes?['cv_url'] as String?;
      if (cvUrl != null) {
        try {
          // Extrait le storage path depuis l'URL signée stockée
          // Format stocké : https://.../cv-documents/{user_id}/cv.pdf?token=...
          final uri = Uri.parse(cvUrl);
          final segments = uri.pathSegments;
          final idx = segments.indexOf('cv-documents');
          if (idx != -1 && idx < segments.length - 1) {
            final storagePath = segments.sublist(idx + 1).join('/');
            cvUrl = await _client.storage
                .from('cv-documents')
                .createSignedUrl(storagePath, 60 * 60 * 24 * 7); // 7 jours
          }
        } catch (_) {
          // Garde l'URL stockée si la régénération échoue
        }
      }

      final fullName = profileRes?['full_name'] as String? ?? 'Candidat';
      final score = appRes['match_score'] as int? ?? 0;

      final candidate = CandidateDetailData(
        applicationId: applicationId,
        studentId: studentId,
        studentName: fullName,
        offerTitle: offerRes?['title'] as String? ?? 'Offre',
        offerId: offerId,
        companyId: companyId,
        status: appRes['status'] as String? ?? 'pending',
        matchScore: score,
        photoUrl: profileRes?['photo_url'] as String?,
        educationLevel: profileRes?['education_level'] as String? ?? '',
        fieldOfStudy: profileRes?['field_of_study'] as String? ?? '',
        cvUrl: cvUrl,
        skills: skills,
        matchExplanation:
            matchExplanation ??
            _buildDefaultExplanation(fullName, score, profileRes),
      );

      emit(CandidateDetailLoaded(candidate: candidate));
    } catch (e) {
      emit(CandidateDetailError(message: e.toString()));
    }
  }

  // ─── Retenir un candidat ──────────────────────────────────────────────────

  Future<void> retainCandidate() async {
    final current = state;
    if (current is! CandidateDetailLoaded) return;

    final candidate = current.candidate;
    emit(CandidateDetailActing(candidate: candidate, action: 'retaining'));

    try {
      await _client
          .from('applications')
          .update({
            'status': 'retained',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', candidate.applicationId);

      final existingConv = await _client
          .from('conversations')
          .select('id')
          .eq('application_id', candidate.applicationId)
          .limit(1)
          .maybeSingle();

      String conversationId;

      if (existingConv != null) {
        conversationId = existingConv['id'] as String;
      } else {
        final convRes = await _client
            .from('conversations')
            .insert({
              'id': const Uuid().v4(),
              'application_id': candidate.applicationId,
              'student_id': candidate.studentId,
              'company_id': candidate.companyId,
              'last_message': 'Conversation démarrée',
              'last_message_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .single();

        conversationId = convRes['id'] as String;
      }

      try {
        await _client.from('notifications').insert({
          'id': const Uuid().v4(),
          'user_id': candidate.studentId,
          'type': 'application_retained',
          'title': 'Candidature retenue 🎉',
          'body':
              'Votre candidature pour "${candidate.offerTitle}" a été retenue. La messagerie est maintenant débloquée.',
          'data': {
            'application_id': candidate.applicationId,
            'conversation_id': conversationId,
          },
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      try {
        DioClient.instance
            .post(
              '/api/workflows/application-status-handler/start',
              data: {
                'input': {
                  'applicationId': candidate.applicationId,
                  'studentId': candidate.studentId,
                  'offerId': candidate.offerId,
                  'status': 'retained',
                },
              },
            )
            .catchError((_) {});
      } catch (_) {}

      emit(
        CandidateRetained(
          candidate: candidate.copyWith(status: 'retained'),
          conversationId: conversationId,
        ),
      );
    } catch (e) {
      emit(
        CandidateDetailError(
          message: 'Erreur : ${e.toString()}',
          lastKnown: candidate,
        ),
      );
      _restoreLoaded(candidate);
    }
  }

  // ─── Refuser un candidat ──────────────────────────────────────────────────

  Future<void> refuseCandidate() async {
    final current = state;
    if (current is! CandidateDetailLoaded) return;

    final candidate = current.candidate;
    emit(CandidateDetailActing(candidate: candidate, action: 'refusing'));

    try {
      await _client
          .from('applications')
          .update({
            'status': 'refused',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', candidate.applicationId);

      try {
        await _client.from('notifications').insert({
          'id': const Uuid().v4(),
          'user_id': candidate.studentId,
          'type': 'application_refused',
          'title': 'Candidature non retenue',
          'body':
              'Votre candidature pour "${candidate.offerTitle}" n\'a pas été retenue cette fois.',
          'data': {'application_id': candidate.applicationId},
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      try {
        DioClient.instance
            .post(
              '/api/workflows/application-status-handler/start',
              data: {
                'input': {
                  'applicationId': candidate.applicationId,
                  'studentId': candidate.studentId,
                  'offerId': candidate.offerId,
                  'status': 'refused',
                },
              },
            )
            .catchError((_) {});
      } catch (_) {}

      emit(CandidateRefused(candidate: candidate.copyWith(status: 'refused')));
    } catch (e) {
      emit(
        CandidateDetailError(
          message: 'Erreur : ${e.toString()}',
          lastKnown: candidate,
        ),
      );
      _restoreLoaded(candidate);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _buildDefaultExplanation(
    String name,
    int score,
    Map<String, dynamic>? profile,
  ) {
    if (score == 0) return 'Aucun score de matching disponible.';
    final field = profile?['field_of_study'] as String? ?? '';
    final edu = profile?['education_level'] as String? ?? '';
    final parts = <String>[];
    if (field.isNotEmpty) parts.add('spécialisé(e) en $field');
    if (edu.isNotEmpty) parts.add('niveau $edu');
    final detail = parts.isNotEmpty ? ' — ${parts.join(', ')}' : '';
    return '$name correspond à $score% des critères de ce poste$detail.';
  }

  void _restoreLoaded(CandidateDetailData candidate) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) emit(CandidateDetailLoaded(candidate: candidate));
    });
  }
}
