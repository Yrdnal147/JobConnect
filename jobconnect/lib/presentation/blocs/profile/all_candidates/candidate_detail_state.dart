import 'package:equatable/equatable.dart';

class CandidateDetailData extends Equatable {
  final String applicationId;
  final String studentId;
  final String studentName;
  final String offerTitle;
  final String offerId;
  final String status;
  final int matchScore;
  final String? photoUrl;
  final String educationLevel;
  final String fieldOfStudy;
  final String? cvUrl;
  final String? cvFileName;
  final List<SkillDetail> skills;
  final String? matchExplanation;
  final String companyId;

  const CandidateDetailData({
    required this.applicationId,
    required this.studentId,
    required this.studentName,
    required this.offerTitle,
    required this.offerId,
    required this.status,
    required this.matchScore,
    this.photoUrl,
    this.educationLevel = '',
    this.fieldOfStudy = '',
    this.cvUrl,
    this.cvFileName,
    this.skills = const [],
    this.matchExplanation,
    required this.companyId,
  });

  CandidateDetailData copyWith({String? status}) {
    return CandidateDetailData(
      applicationId: applicationId,
      studentId: studentId,
      studentName: studentName,
      offerTitle: offerTitle,
      offerId: offerId,
      status: status ?? this.status,
      matchScore: matchScore,
      photoUrl: photoUrl,
      educationLevel: educationLevel,
      fieldOfStudy: fieldOfStudy,
      cvUrl: cvUrl,
      cvFileName: cvFileName,
      skills: skills,
      matchExplanation: matchExplanation,
      companyId: companyId,
    );
  }

  @override
  List<Object?> get props => [
        applicationId, studentId, studentName, offerTitle, offerId,
        status, matchScore, photoUrl, educationLevel, fieldOfStudy,
        cvUrl, cvFileName, skills, matchExplanation, companyId,
      ];
}

class SkillDetail extends Equatable {
  final String name;
  final String skillType;

  const SkillDetail({required this.name, required this.skillType});

  @override
  List<Object?> get props => [name, skillType];
}

// ─── États ────────────────────────────────────────────────────────────────────

abstract class CandidateDetailState extends Equatable {
  const CandidateDetailState();

  @override
  List<Object?> get props => [];
}

class CandidateDetailInitial extends CandidateDetailState {
  const CandidateDetailInitial();
}

class CandidateDetailLoading extends CandidateDetailState {
  const CandidateDetailLoading();
}

class CandidateDetailLoaded extends CandidateDetailState {
  final CandidateDetailData candidate;

  const CandidateDetailLoaded({required this.candidate});

  @override
  List<Object?> get props => [candidate];
}

class CandidateDetailActing extends CandidateDetailState {
  final CandidateDetailData candidate;
  final String action; // 'retaining' | 'refusing'

  const CandidateDetailActing({
    required this.candidate,
    required this.action,
  });

  @override
  List<Object?> get props => [candidate, action];
}

class CandidateRetained extends CandidateDetailState {
  final CandidateDetailData candidate;
  final String conversationId;

  const CandidateRetained({
    required this.candidate,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [candidate, conversationId];
}

class CandidateRefused extends CandidateDetailState {
  final CandidateDetailData candidate;

  const CandidateRefused({required this.candidate});

  @override
  List<Object?> get props => [candidate];
}

class CandidateDetailError extends CandidateDetailState {
  final String message;
  final CandidateDetailData? lastKnown;

  const CandidateDetailError({required this.message, this.lastKnown});

  @override
  List<Object?> get props => [message, lastKnown];
}