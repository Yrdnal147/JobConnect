import 'package:equatable/equatable.dart';

class DashboardMetrics extends Equatable {
  final int activeOffers;
  final int totalApplications;
  final int retainedCandidates;
  final int unreadMessages;

  const DashboardMetrics({
    this.activeOffers = 0,
    this.totalApplications = 0,
    this.retainedCandidates = 0,
    this.unreadMessages = 0,
  });

  @override
  List<Object?> get props => [
        activeOffers,
        totalApplications,
        retainedCandidates,
        unreadMessages,
      ];
}

class RecentApplication extends Equatable {
  final String applicationId;
  final String studentName;
  final String fieldOfStudy;
  final String educationLevel;
  final int matchScore;
  final String? photoUrl;

  const RecentApplication({
    required this.applicationId,
    required this.studentName,
    required this.fieldOfStudy,
    required this.educationLevel,
    required this.matchScore,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [
        applicationId,
        studentName,
        fieldOfStudy,
        educationLevel,
        matchScore,
        photoUrl,
      ];
}

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final String companyName;
  final String? companyLogo;
  final DashboardMetrics metrics;
  final List<RecentApplication> recentApplications;

  const DashboardLoaded({
    required this.companyName,
    this.companyLogo,
    required this.metrics,
    required this.recentApplications,
  });

  @override
  List<Object?> get props => [companyName, companyLogo, metrics, recentApplications];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}