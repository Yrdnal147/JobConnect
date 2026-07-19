import 'package:equatable/equatable.dart';

class ApplicationItem extends Equatable {
  final String applicationId;
  final String offerId;
  final String offerTitle;
  final String companyName;
  final String? companyLogoUrl;
  final String companyId;
  final String status;
  final int matchScore;
  final String appliedAt;
  final String? conversationId;

  const ApplicationItem({
    required this.applicationId,
    required this.offerId,
    required this.offerTitle,
    required this.companyName,
    this.companyLogoUrl,
    required this.companyId,
    required this.status,
    required this.matchScore,
    required this.appliedAt,
    this.conversationId,
  });

  @override
  List<Object?> get props => [
    applicationId,
    offerId,
    offerTitle,
    companyName,
    companyLogoUrl,
    companyId,
    status,
    matchScore,
    appliedAt,
    conversationId,
  ];
}

class ApplicationDetail extends Equatable {
  final String applicationId;
  final String offerTitle;
  final String offerType;
  final String companyName;
  final String? companyLogoUrl;
  final String status;
  final int matchScore;
  final String appliedAt;
  final String? conversationId;
  final List<String> missingSkills;
  final List<SimilarOffer> similarOffers;
  final String? statusExplanation; // JSON stringifié provenant de l'IA

  const ApplicationDetail({
    required this.applicationId,
    required this.offerTitle,
    required this.offerType,
    required this.companyName,
    this.companyLogoUrl,
    required this.status,
    required this.matchScore,
    required this.appliedAt,
    this.conversationId,
    this.missingSkills = const [],
    this.similarOffers = const [],
    this.statusExplanation,
  });

  @override
  List<Object?> get props => [
    applicationId,
    offerTitle,
    offerType,
    companyName,
    companyLogoUrl,
    status,
    matchScore,
    appliedAt,
    conversationId,
    missingSkills,
    similarOffers,
    statusExplanation,
  ];
}

class SimilarOffer extends Equatable {
  final String offerId;
  final String title;
  final String companyName;
  final String offerType;

  const SimilarOffer({
    required this.offerId,
    required this.title,
    required this.companyName,
    required this.offerType,
  });

  @override
  List<Object?> get props => [offerId, title, companyName, offerType];
}

// ─── États liste ──────────────────────────────────────────────────────────────

abstract class ApplicationsState extends Equatable {
  const ApplicationsState();

  @override
  List<Object?> get props => [];
}

class ApplicationsInitial extends ApplicationsState {
  const ApplicationsInitial();
}

class ApplicationsLoading extends ApplicationsState {
  const ApplicationsLoading();
}

class ApplicationsLoaded extends ApplicationsState {
  final List<ApplicationItem> applications;
  final String activeFilter;

  const ApplicationsLoaded({
    required this.applications,
    this.activeFilter = 'Tous',
  });

  List<ApplicationItem> get filteredApplications {
    if (activeFilter == 'Tous') return applications;
    final map = {
      'En attente': 'pending',
      'Retenu': 'retained',
      'Refusé': 'refused',
    };
    return applications.where((a) => a.status == map[activeFilter]).toList();
  }

  int countByStatus(String status) =>
      applications.where((a) => a.status == status).length;

  ApplicationsLoaded copyWith({
    List<ApplicationItem>? applications,
    String? activeFilter,
  }) {
    return ApplicationsLoaded(
      applications: applications ?? this.applications,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  @override
  List<Object?> get props => [applications, activeFilter];
}

class ApplicationsError extends ApplicationsState {
  final String message;
  const ApplicationsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── États détail ─────────────────────────────────────────────────────────────

class ApplicationDetailLoading extends ApplicationsState {
  const ApplicationDetailLoading();
}

class ApplicationDetailLoaded extends ApplicationsState {
  final ApplicationDetail detail;
  const ApplicationDetailLoaded({required this.detail});

  @override
  List<Object?> get props => [detail];
}

class ApplicationDetailError extends ApplicationsState {
  final String message;
  const ApplicationDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
