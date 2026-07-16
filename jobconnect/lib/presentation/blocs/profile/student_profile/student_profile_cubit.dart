import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'student_profile_state.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../data/datasources/mastra_remote_datasource.dart';

class StudentProfileCubit extends Cubit<StudentProfileState> {
  final SupabaseClient _client;
  final IMastraRemoteDataSource? _mastraRemoteDataSource;

  StudentProfileCubit({SupabaseClient? client, IMastraRemoteDataSource? mastraRemoteDataSource})
      : _client = client ?? Supabase.instance.client,
        _mastraRemoteDataSource = mastraRemoteDataSource,
        super(const StudentProfileInitial());

  // ─── Charge le profil ─────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    emit(const StudentProfileLoading());

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const StudentProfileError(message: 'Utilisateur non connecté'));
        return;
      }

      final email    = user.email ?? '';
      final fullName = user.userMetadata?['full_name'] as String? ?? 'Candidat';

      final profileRes = await _client
          .from('student_profiles')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      List<SkillItem> skills = [];
      if (profileRes != null) {
        try {
          final skillsRes = await _client
              .from('skills')
              .select('id, name, skill_type')
              .eq('student_id', profileRes['id'] as String);

          skills = (skillsRes as List).map((s) {
            return SkillItem(
              id: s['id'] as String,
              name: s['name'] as String,
              skillType: s['skill_type'] as String? ?? 'technical',
            );
          }).toList();
        } catch (_) {}
      }

      if (profileRes == null) {
        emit(StudentProfileLoaded(
          profile: StudentProfileData(
            fullName: fullName,
            email: email,
          ),
        ));
        return;
      }

      final profile = StudentProfileData(
        fullName: profileRes['full_name'] as String? ?? fullName,
        email: email,
        profileScore: profileRes['profile_score'] as int? ?? 0,
        completionLabel: profileRes['completion_label'] as String? ?? '',
        photoUrl: profileRes['photo_url'] as String?,
        cvUrl: profileRes['cv_url'] as String?,
        educationLevel: profileRes['education_level'] as String? ?? '',
        fieldOfStudy: profileRes['field_of_study'] as String? ?? '',
        targetOpportunity: profileRes['target_opportunity'] as String? ?? '',
        location: profileRes['location'] as String? ?? 'Douala',
        linkedinUrl: profileRes['linkedin_url'] as String?,
        portfolioUrl: profileRes['portfolio_url'] as String?,
        skills: skills,
        verificationStatus: _parseVerificationStatus(
          profileRes['verification_status'] as String?,
        ),
        isVerified: profileRes['is_verified'] as bool? ?? false,
      );

      emit(StudentProfileLoaded(profile: profile));
    } catch (e) {
      emit(StudentProfileError(message: e.toString()));
    }
  }

  // ─── Upload photo ─────────────────────────────────────────────────────────

  Future<void> uploadPhoto(File imageFile) async {
    final current = state;
    if (current is! StudentProfileLoaded) return;

    final profile = current.profile;
    emit(StudentPhotoUploading(profile: profile));

    try {
      final user     = _client.auth.currentUser!;
      final ext      = imageFile.path.split('.').last;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.id}/avatar_$ts.$ext';

      await _client.storage.from('profile-photos').upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final photoUrl =
          _client.storage.from('profile-photos').getPublicUrl(fileName);

      await _ensureProfileExists(user.id, profile.fullName);
      await _client
          .from('student_profiles')
          .update({'photo_url': photoUrl})
          .eq('user_id', user.id);

      emit(StudentProfileLoaded(
        profile: StudentProfileData(
          fullName: profile.fullName,
          email: profile.email,
          profileScore: profile.profileScore,
          completionLabel: profile.completionLabel,
          photoUrl: photoUrl,
          cvUrl: profile.cvUrl,
          educationLevel: profile.educationLevel,
          fieldOfStudy: profile.fieldOfStudy,
          targetOpportunity: profile.targetOpportunity,
          location: profile.location,
          linkedinUrl: profile.linkedinUrl,
          portfolioUrl: profile.portfolioUrl,
          skills: profile.skills,
          verificationStatus: profile.verificationStatus,
          isVerified: profile.isVerified,
        ),
      ));
    } catch (e) {
      emit(StudentProfileError(
        message: 'Erreur upload photo : ${e.toString()}',
        lastKnownProfile: profile,
      ));
      _restoreLoaded(profile);
    }
  }

  // ─── Upload CV ────────────────────────────────────────────────────────────

  Future<void> uploadCv(File cvFile, String fileName) async {
    final current = state;
    if (current is! StudentProfileLoaded) return;

    final profile = current.profile;
    emit(StudentCvUploading(profile: profile));

    try {
      final user        = _client.auth.currentUser!;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '${user.id}/cv_$ts.pdf';

      await _client.storage.from('cv-documents').upload(
            storagePath,
            cvFile,
            fileOptions: const FileOptions(upsert: true),
          );

      final cvUrl = await _client.storage
    .from('cv-documents')
    .createSignedUrl(storagePath, 60 * 60 * 24 * 365);

      await _ensureProfileExists(user.id, profile.fullName);
      await _client
          .from('student_profiles')
          .update({'cv_url': cvUrl})
          .eq('user_id', user.id);

      if (_mastraRemoteDataSource != null) {
        emit(StudentCvAnalyzing(profile: profile.copyWithCv(cvUrl, fileName)));
        
       await _mastraRemoteDataSource.startWorkflow(
  ApiEndpoints.cvPipeline,
  {
    'cvUrl': cvUrl,
    'userId': user.id,
    'targetOpportunity': profile.targetOpportunity.isEmpty
        ? 'full-time'
        : profile.targetOpportunity,
  },
);
        // Recharge le profil depuis Supabase pour afficher les nouvelles données
        await loadProfile();
      } else {
        final newScore = _calculateScore(profile.copyWithCv(cvUrl, fileName));

        await _client.from('student_profiles').update({
          'profile_score': newScore,
          'completion_label': _getCompletionLabel(newScore),
        }).eq('user_id', user.id);

        emit(StudentProfileLoaded(
          profile: StudentProfileData(
            fullName: profile.fullName,
            email: profile.email,
            profileScore: newScore,
            completionLabel: _getCompletionLabel(newScore),
            photoUrl: profile.photoUrl,
            cvUrl: cvUrl,
            cvFileName: fileName,
            educationLevel: profile.educationLevel,
            fieldOfStudy: profile.fieldOfStudy,
            targetOpportunity: profile.targetOpportunity,
            location: profile.location,
            linkedinUrl: profile.linkedinUrl,
            portfolioUrl: profile.portfolioUrl,
            skills: profile.skills,
            verificationStatus: profile.verificationStatus,
            isVerified: profile.isVerified,
          ),
        ));
      }
    } catch (e) {
      emit(StudentProfileError(
        message: 'Erreur upload CV : ${e.toString()}',
        lastKnownProfile: profile,
      ));
      _restoreLoaded(profile);
    }
  }

  // ─── Ajouter compétence ───────────────────────────────────────────────────

  Future<void> addSkill(String skillName, String skillType) async {
    final current = state;
    if (current is! StudentProfileLoaded) return;

    if (skillName.trim().isEmpty) return;

    final profile = current.profile;

    if (profile.skills.any(
        (s) => s.name.toLowerCase() == skillName.trim().toLowerCase())) {
      return;
    }

    try {
      final user = _client.auth.currentUser!;

      final profileRow = await _ensureProfileExists(user.id, profile.fullName);
      final studentId  = profileRow['id'] as String;

      final skillRes = await _client.from('skills').insert({
        'id': const Uuid().v4(),
        'student_id': studentId,
        'name': skillName.trim(),
        'skill_type': skillType,
      }).select().single();

      final newSkill = SkillItem(
        id: skillRes['id'] as String,
        name: skillRes['name'] as String,
        skillType: skillRes['skill_type'] as String,
      );

      final updatedSkills = [...profile.skills, newSkill];
      final newScore      = _calculateScore(profile.copyWithSkills(updatedSkills));

      await _client.from('student_profiles').update({
        'profile_score': newScore,
        'completion_label': _getCompletionLabel(newScore),
      }).eq('user_id', user.id);

      emit(StudentProfileLoaded(
        profile: StudentProfileData(
          fullName: profile.fullName,
          email: profile.email,
          profileScore: newScore,
          completionLabel: _getCompletionLabel(newScore),
          photoUrl: profile.photoUrl,
          cvUrl: profile.cvUrl,
          cvFileName: profile.cvFileName,
          educationLevel: profile.educationLevel,
          fieldOfStudy: profile.fieldOfStudy,
          targetOpportunity: profile.targetOpportunity,
          location: profile.location,
          linkedinUrl: profile.linkedinUrl,
          portfolioUrl: profile.portfolioUrl,
          skills: updatedSkills,
          verificationStatus: profile.verificationStatus,
          isVerified: profile.isVerified,
        ),
      ));
    } catch (e) {
      emit(StudentProfileError(
        message: 'Erreur ajout compétence : ${e.toString()}',
        lastKnownProfile: profile,
      ));
      _restoreLoaded(profile);
    }
  }

  // ─── Supprimer compétence ─────────────────────────────────────────────────

  Future<void> removeSkill(String skillId) async {
    final current = state;
    if (current is! StudentProfileLoaded) return;

    final profile = current.profile;

    try {
      final user = _client.auth.currentUser!;

      await _client.from('skills').delete().eq('id', skillId);

      final updatedSkills = profile.skills.where((s) => s.id != skillId).toList();
      final newScore      = _calculateScore(profile.copyWithSkills(updatedSkills));

      await _client.from('student_profiles').update({
        'profile_score': newScore,
        'completion_label': _getCompletionLabel(newScore),
      }).eq('user_id', user.id);

      emit(StudentProfileLoaded(
        profile: StudentProfileData(
          fullName: profile.fullName,
          email: profile.email,
          profileScore: newScore,
          completionLabel: _getCompletionLabel(newScore),
          photoUrl: profile.photoUrl,
          cvUrl: profile.cvUrl,
          cvFileName: profile.cvFileName,
          educationLevel: profile.educationLevel,
          fieldOfStudy: profile.fieldOfStudy,
          targetOpportunity: profile.targetOpportunity,
          location: profile.location,
          linkedinUrl: profile.linkedinUrl,
          portfolioUrl: profile.portfolioUrl,
          skills: updatedSkills,
          verificationStatus: profile.verificationStatus,
          isVerified: profile.isVerified,
        ),
      ));
    } catch (e) {
      emit(StudentProfileError(
        message: 'Erreur suppression : ${e.toString()}',
        lastKnownProfile: profile,
      ));
      _restoreLoaded(profile);
    }
  }

  // ─── Mise à jour du nom ───────────────────────────────────────────────────

  Future<void> updateFullName(String newName) async {
    final current = state;
    if (current is! StudentProfileLoaded) return;
    
    final cleanName = newName.trim();
    if (cleanName.isEmpty) return;

    final profile = current.profile;
    
    try {
      final user = _client.auth.currentUser!;
      await _ensureProfileExists(user.id, profile.fullName);
      
      await _client
          .from('student_profiles')
          .update({'full_name': cleanName})
          .eq('user_id', user.id);
          
      // Mise à jour globale dans Supabase Auth (pour que le nom soit disponible instantanément sur les autres pages)
      await _client.auth.updateUser(UserAttributes(
        data: {'full_name': cleanName},
      ));

      emit(StudentProfileLoaded(
        profile: profile.copyWithFullName(cleanName),
      ));
    } catch (e) {
      emit(StudentProfileError(
        message: 'Erreur mise à jour du nom : ${e.toString()}',
        lastKnownProfile: profile,
      ));
      _restoreLoaded(profile);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _ensureProfileExists(
      String userId, String fullName) async {
    final existing = await _client
        .from('student_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) return existing;

    final created = await _client.from('student_profiles').insert({
      'user_id': userId,
      'full_name': fullName,
      'location': 'Douala',
      'profile_score': 0,
      'completion_label': 'Faible',
      'verification_status': 'none',
      'is_verified': false,
    }).select().single();

    return created;
  }

  int _calculateScore(StudentProfileData profile) {
    int score = 0;
    if (profile.cvUrl != null) score += 25;
    if (profile.skills.isNotEmpty) score += 25;
    if (profile.educationLevel.isNotEmpty) score += 20;
    if (profile.fieldOfStudy.isNotEmpty) score += 15;
    if (profile.photoUrl != null) score += 10;
    if (profile.linkedinUrl != null) score += 5;
    return score.clamp(0, 100);
  }

  String _getCompletionLabel(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Bon';
    if (score >= 40) return 'Moyen';
    return 'Faible';
  }

  StudentVerificationStatus _parseVerificationStatus(String? raw) {
    switch (raw) {
      case 'pending':  return StudentVerificationStatus.pending;
      case 'verified': return StudentVerificationStatus.verified;
      case 'rejected': return StudentVerificationStatus.rejected;
      default:         return StudentVerificationStatus.none;
    }
  }

  void _restoreLoaded(StudentProfileData profile) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) emit(StudentProfileLoaded(profile: profile));
    });
  }
}

// ─── Extensions ───────────────────────────────────────────────────────────────

extension StudentProfileDataX on StudentProfileData {
  StudentProfileData copyWithSkills(List<SkillItem> skills) {
    return StudentProfileData(
      fullName: fullName,
      email: email,
      profileScore: profileScore,
      completionLabel: completionLabel,
      photoUrl: photoUrl,
      cvUrl: cvUrl,
      cvFileName: cvFileName,
      educationLevel: educationLevel,
      fieldOfStudy: fieldOfStudy,
      targetOpportunity: targetOpportunity,
      location: location,
      linkedinUrl: linkedinUrl,
      portfolioUrl: portfolioUrl,
      skills: skills,
      verificationStatus: verificationStatus,
      isVerified: isVerified,
    );
  }

  StudentProfileData copyWithCv(String cvUrl, String cvFileName) {
    return StudentProfileData(
      fullName: fullName,
      email: email,
      profileScore: profileScore,
      completionLabel: completionLabel,
      photoUrl: photoUrl,
      cvUrl: cvUrl,
      cvFileName: cvFileName,
      educationLevel: educationLevel,
      fieldOfStudy: fieldOfStudy,
      targetOpportunity: targetOpportunity,
      location: location,
      linkedinUrl: linkedinUrl,
      portfolioUrl: portfolioUrl,
      skills: skills,
      verificationStatus: verificationStatus,
      isVerified: isVerified,
    );
  }

  StudentProfileData copyWithFullName(String newFullName) {
    return StudentProfileData(
      fullName: newFullName,
      email: email,
      profileScore: profileScore,
      completionLabel: completionLabel,
      photoUrl: photoUrl,
      cvUrl: cvUrl,
      cvFileName: cvFileName,
      educationLevel: educationLevel,
      fieldOfStudy: fieldOfStudy,
      targetOpportunity: targetOpportunity,
      location: location,
      linkedinUrl: linkedinUrl,
      portfolioUrl: portfolioUrl,
      skills: skills,
      verificationStatus: verificationStatus,
      isVerified: isVerified,
    );
  }
}