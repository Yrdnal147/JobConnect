import 'package:equatable/equatable.dart';

class FeedOffer extends Equatable {
  final String offerId;
  final String title;
  final String companyName;
  final String? companyLogo;
  final String offerType;
  final String location;
  final int matchScore;
  final String postedAt;
  final bool isHighMatch;

  const FeedOffer({
    required this.offerId,
    required this.title,
    required this.companyName,
    this.companyLogo,
    required this.offerType,
    required this.location,
    required this.matchScore,
    required this.postedAt,
    this.isHighMatch = false,
  });

  @override
  List<Object?> get props => [
        offerId, title, companyName, companyLogo,
        offerType, location, matchScore, postedAt, isHighMatch,
      ];
}

abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedLoaded extends FeedState {
  final List<FeedOffer> offers;
  final String activeFilter;
  final bool hasProfile;
  final String userName;
  final String? photoUrl; // ← ajouté
  final int profileScore;

  const FeedLoaded({
    required this.offers,
    required this.userName,
    this.photoUrl,
    this.activeFilter = 'Tous',
    this.hasProfile = false,
    this.profileScore = 0,
  });

  List<FeedOffer> get filteredOffers {
    if (activeFilter == 'Tous') return offers;
    return offers.where((o) {
      switch (activeFilter) {
        case 'CDI':
          return o.offerType == 'cdi';
        case 'CDD':
          return o.offerType == 'cdd';
        case 'Stage':
          return o.offerType == 'stage_academique' ||
              o.offerType == 'stage_professionnel';
        default:
          return true;
      }
    }).toList();
  }

  FeedLoaded copyWith({
    List<FeedOffer>? offers,
    String? activeFilter,
    bool? hasProfile,
    String? userName,
    String? photoUrl,
    int? profileScore,
  }) {
    return FeedLoaded(
      offers: offers ?? this.offers,
      activeFilter: activeFilter ?? this.activeFilter,
      hasProfile: hasProfile ?? this.hasProfile,
      userName: userName ?? this.userName,
      photoUrl: photoUrl ?? this.photoUrl,
      profileScore: profileScore ?? this.profileScore,
    );
  }

  @override
  List<Object?> get props => [
        offers, activeFilter, hasProfile, userName, photoUrl, profileScore,
      ];
}

class FeedError extends FeedState {
  final String message;
  const FeedError(this.message);

  @override
  List<Object?> get props => [message];
}