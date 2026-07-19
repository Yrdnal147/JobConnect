import 'package:equatable/equatable.dart';

class CandidateItem extends Equatable {
  final String applicationId;
  final String studentName;
  final String offerTitle;
  final String status;
  final int matchScore;
  final String? photoUrl;
  final String educationLevel;
  final String fieldOfStudy;

  const CandidateItem({
    required this.applicationId,
    required this.studentName,
    required this.offerTitle,
    required this.status,
    required this.matchScore,
    this.photoUrl,
    this.educationLevel = '',
    this.fieldOfStudy = '',
  });

  @override
  List<Object?> get props => [
    applicationId,
    studentName,
    offerTitle,
    status,
    matchScore,
    photoUrl,
    educationLevel,
    fieldOfStudy,
  ];
}

abstract class AllCandidatesState extends Equatable {
  const AllCandidatesState();

  @override
  List<Object?> get props => [];
}

class AllCandidatesInitial extends AllCandidatesState {
  const AllCandidatesInitial();
}

class AllCandidatesLoading extends AllCandidatesState {
  const AllCandidatesLoading();
}

class AllCandidatesLoaded extends AllCandidatesState {
  final List<CandidateItem> candidates;
  final String filterStatus; // 'all', 'pending', 'retained', 'refused'

  const AllCandidatesLoaded({
    required this.candidates,
    this.filterStatus = 'all',
  });

  // Retourne les candidats filtrés selon le statut sélectionné
  List<CandidateItem> get filteredCandidates {
    if (filterStatus == 'all') return candidates;
    return candidates.where((c) => c.status == filterStatus).toList();
  }

  AllCandidatesLoaded copyWith({
    List<CandidateItem>? candidates,
    String? filterStatus,
  }) {
    return AllCandidatesLoaded(
      candidates: candidates ?? this.candidates,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }

  @override
  List<Object?> get props => [candidates, filterStatus];
}

class AllCandidatesError extends AllCandidatesState {
  final String message;
  const AllCandidatesError(this.message);

  @override
  List<Object?> get props => [message];
}
