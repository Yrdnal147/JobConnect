import 'package:equatable/equatable.dart';

enum StudentVerificationStatus { none, pending, verified, rejected }

class SkillItem extends Equatable {
  final String id;
  final String name;
  final String skillType;

  const SkillItem({
    required this.id,
    required this.name,
    required this.skillType,
  });

  @override
  List<Object?> get props => [id, name, skillType];
}

class StudentProfileData extends Equatable {
  final String fullName;
  final String email;
  final int profileScore;
  final String completionLabel;
  final String? photoUrl;
  final String? cvUrl;
  final String? cvFileName;
  final String educationLevel;
  final String fieldOfStudy;
  final String targetOpportunity;
  final String location;
  final String? linkedinUrl;
  final String? portfolioUrl;
  final List<SkillItem> skills;
  final StudentVerificationStatus verificationStatus;
  final bool isVerified;

  const StudentProfileData({
    required this.fullName,
    required this.email,
    this.profileScore = 0,
    this.completionLabel = '',
    this.photoUrl,
    this.cvUrl,
    this.cvFileName,
    this.educationLevel = '',
    this.fieldOfStudy = '',
    this.targetOpportunity = '',
    this.location = 'Douala',
    this.linkedinUrl,
    this.portfolioUrl,
    this.skills = const [],
    this.verificationStatus = StudentVerificationStatus.none,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [
    fullName,
    email,
    profileScore,
    completionLabel,
    photoUrl,
    cvUrl,
    cvFileName,
    educationLevel,
    fieldOfStudy,
    targetOpportunity,
    location,
    linkedinUrl,
    portfolioUrl,
    skills,
    verificationStatus,
    isVerified,
  ];
}

abstract class StudentProfileState extends Equatable {
  const StudentProfileState();

  @override
  List<Object?> get props => [];
}

class StudentProfileInitial extends StudentProfileState {
  const StudentProfileInitial();
}

class StudentProfileLoading extends StudentProfileState {
  const StudentProfileLoading();
}

class StudentProfileLoaded extends StudentProfileState {
  final StudentProfileData profile;

  const StudentProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class StudentProfileSaving extends StudentProfileState {
  final StudentProfileData profile;
  const StudentProfileSaving({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class StudentProfileSaved extends StudentProfileState {
  final StudentProfileData profile;
  const StudentProfileSaved({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class StudentPhotoUploading extends StudentProfileState {
  final StudentProfileData profile;
  const StudentPhotoUploading({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class StudentCvUploading extends StudentProfileState {
  final StudentProfileData profile;
  const StudentCvUploading({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class StudentCvAnalyzing extends StudentProfileState {
  final StudentProfileData profile;
  const StudentCvAnalyzing({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class StudentProfileError extends StudentProfileState {
  final String message;
  final StudentProfileData? lastKnownProfile;

  const StudentProfileError({required this.message, this.lastKnownProfile});

  @override
  List<Object?> get props => [message, lastKnownProfile];
}
