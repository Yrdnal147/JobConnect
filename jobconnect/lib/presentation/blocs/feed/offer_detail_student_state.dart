import 'package:equatable/equatable.dart';

class StudentOfferDetail extends Equatable {
  final String offerId;
  final String title;
  final String companyName;
  final String companyId;
  final bool isCompanyVerified;
  final String? companyLogo;
  final String offerType;
  final String location;
  final String description;
  final List<String> requiredSkills;
  final String minEducation;
  final int yearsOfExperience;
  final String? salaryRange;
  final int? durationMonths;
  final String postedAt;
  final int matchScore;
  final List<String> matchingSkills;
  final List<String> missingSkills;
  final bool hasAlreadyApplied;

  const StudentOfferDetail({
    required this.offerId,
    required this.title,
    required this.companyName,
    required this.companyId,
    this.isCompanyVerified = false,
    this.companyLogo,
    required this.offerType,
    required this.location,
    required this.description,
    required this.requiredSkills,
    required this.minEducation,
    required this.yearsOfExperience,
    this.salaryRange,
    this.durationMonths,
    required this.postedAt,
    required this.matchScore,
    required this.matchingSkills,
    required this.missingSkills,
    this.hasAlreadyApplied = false,
  });

  @override
  List<Object?> get props => [
        offerId, title, companyName, companyId,
        isCompanyVerified, companyLogo, offerType, location,
        description, requiredSkills, minEducation,
        yearsOfExperience, salaryRange, durationMonths,
        postedAt, matchScore, matchingSkills,
        missingSkills, hasAlreadyApplied,
      ];
}

abstract class OfferDetailStudentState extends Equatable {
  const OfferDetailStudentState();

  @override
  List<Object?> get props => [];
}

class OfferDetailStudentInitial extends OfferDetailStudentState {
  const OfferDetailStudentInitial();
}

class OfferDetailStudentLoading extends OfferDetailStudentState {
  const OfferDetailStudentLoading();
}

class OfferDetailStudentLoaded extends OfferDetailStudentState {
  final StudentOfferDetail offer;
  final bool isSaved;
  final bool isCoachingLoading;
  final Map<String, dynamic>? coachResult;
  final String? coachError;

  const OfferDetailStudentLoaded({
    required this.offer,
    this.isSaved = false,
    this.isCoachingLoading = false,
    this.coachResult,
    this.coachError,
  });

  OfferDetailStudentLoaded copyWith({
    StudentOfferDetail? offer,
    bool? isSaved,
    bool? isCoachingLoading,
    Map<String, dynamic>? coachResult,
    String? coachError,
  }) {
    return OfferDetailStudentLoaded(
      offer: offer ?? this.offer,
      isSaved: isSaved ?? this.isSaved,
      isCoachingLoading: isCoachingLoading ?? this.isCoachingLoading,
      coachResult: coachResult ?? this.coachResult,
      coachError: coachError, // on n'utilise pas le coalescing pour permettre de remettre à null
    );
  }

  @override
  List<Object?> get props => [offer, isSaved, isCoachingLoading, coachResult, coachError];
}

class OfferDetailStudentApplying extends OfferDetailStudentState {
  final StudentOfferDetail offer;
  const OfferDetailStudentApplying({required this.offer});

  @override
  List<Object?> get props => [offer];
}

class OfferDetailStudentApplied extends OfferDetailStudentState {
  final StudentOfferDetail offer;
  const OfferDetailStudentApplied({required this.offer});

  @override
  List<Object?> get props => [offer];
}

class OfferDetailStudentError extends OfferDetailStudentState {
  final String message;
  final StudentOfferDetail? lastKnownOffer;

  const OfferDetailStudentError({
    required this.message,
    this.lastKnownOffer,
  });

  @override
  List<Object?> get props => [message, lastKnownOffer];
}