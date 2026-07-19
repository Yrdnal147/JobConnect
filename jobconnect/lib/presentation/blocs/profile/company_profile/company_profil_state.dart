import 'package:equatable/equatable.dart';

enum CompanyVerificationStatus { none, pending, verified, rejected }

class CompanyProfileData extends Equatable {
  final String name;
  final String email;
  final String sector;
  final String size;
  final String description;
  final String ceoName;
  final String website;
  final String location;
  final String? logoUrl;
  final CompanyVerificationStatus verificationStatus;
  final bool isVerified;

  const CompanyProfileData({
    required this.name,
    required this.email,
    this.sector = '',
    this.size = '',
    this.description = '',
    this.ceoName = '',
    this.website = '',
    this.location = 'Douala',
    this.logoUrl,
    this.verificationStatus = CompanyVerificationStatus.none,
    this.isVerified = false,
  });

  CompanyProfileData copyWith({
    String? name,
    String? email,
    String? sector,
    String? size,
    String? description,
    String? ceoName,
    String? website,
    String? location,
    String? logoUrl,
    CompanyVerificationStatus? verificationStatus,
    bool? isVerified,
  }) {
    return CompanyProfileData(
      name: name ?? this.name,
      email: email ?? this.email,
      sector: sector ?? this.sector,
      size: size ?? this.size,
      description: description ?? this.description,
      ceoName: ceoName ?? this.ceoName,
      website: website ?? this.website,
      location: location ?? this.location,
      logoUrl: logoUrl ?? this.logoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  List<Object?> get props => [
    name,
    email,
    sector,
    size,
    description,
    ceoName,
    website,
    location,
    logoUrl,
    verificationStatus,
    isVerified,
  ];
}

abstract class CompanyProfileState extends Equatable {
  const CompanyProfileState();

  @override
  List<Object?> get props => [];
}

class CompanyProfileInitial extends CompanyProfileState {
  const CompanyProfileInitial();
}

class CompanyProfileLoading extends CompanyProfileState {
  const CompanyProfileLoading();
}

class CompanyProfileLoaded extends CompanyProfileState {
  final CompanyProfileData profile;
  final bool isDirty;

  const CompanyProfileLoaded({required this.profile, this.isDirty = false});

  CompanyProfileLoaded copyWith({CompanyProfileData? profile, bool? isDirty}) {
    return CompanyProfileLoaded(
      profile: profile ?? this.profile,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props => [profile, isDirty];
}

class CompanyProfileSaving extends CompanyProfileState {
  final CompanyProfileData profile;
  const CompanyProfileSaving({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class CompanyProfileSaved extends CompanyProfileState {
  final CompanyProfileData profile;
  const CompanyProfileSaved({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class CompanyLogoUploading extends CompanyProfileState {
  final CompanyProfileData profile;
  const CompanyLogoUploading({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class CompanyProfileError extends CompanyProfileState {
  final String message;
  final CompanyProfileData? lastKnownProfile;

  const CompanyProfileError({required this.message, this.lastKnownProfile});

  @override
  List<Object?> get props => [message, lastKnownProfile];
}
