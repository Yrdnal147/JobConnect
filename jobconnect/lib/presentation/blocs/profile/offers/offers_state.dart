import 'package:equatable/equatable.dart';

class OfferItem extends Equatable {
  final String offerId;
  final String title;
  final String offerType;
  final String location;
  final int applicationsCount;
  final bool isActive;
  final String postedAt;
  final int? durationMonths;
  final String? salaryRange;

  // ── Champs détail ─────────────────────────────────────────────────────────
  final String description;
  final List<String> requiredSkills;
  final String minEducation;
  final int yearsOfExperience;

  const OfferItem({
    required this.offerId,
    required this.title,
    required this.offerType,
    required this.location,
    required this.applicationsCount,
    required this.isActive,
    required this.postedAt,
    this.durationMonths,
    this.salaryRange,
    this.description = '',
    this.requiredSkills = const [],
    this.minEducation = '',
    this.yearsOfExperience = 0,
  });

  OfferItem copyWith({
    bool? isActive,
    String? title,
    String? description,
    String? offerType,
    String? minEducation,
    String? location,
    List<String>? requiredSkills,
    int? yearsOfExperience,
    int? durationMonths,
    String? salaryRange,
    int? applicationsCount,
  }) {
    return OfferItem(
      offerId: offerId,
      title: title ?? this.title,
      offerType: offerType ?? this.offerType,
      location: location ?? this.location,
      applicationsCount: applicationsCount ?? this.applicationsCount,
      isActive: isActive ?? this.isActive,
      postedAt: postedAt,
      durationMonths: durationMonths ?? this.durationMonths,
      salaryRange: salaryRange ?? this.salaryRange,
      description: description ?? this.description,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      minEducation: minEducation ?? this.minEducation,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
    );
  }

  @override
  List<Object?> get props => [
        offerId,
        title,
        offerType,
        location,
        applicationsCount,
        isActive,
        postedAt,
        durationMonths,
        salaryRange,
        description,
        requiredSkills,
        minEducation,
        yearsOfExperience,
      ];
}

abstract class OffersState extends Equatable {
  const OffersState();

  @override
  List<Object?> get props => [];
}

class OffersInitial extends OffersState {
  const OffersInitial();
}

class OffersLoading extends OffersState {
  const OffersLoading();
}

class OffersLoaded extends OffersState {
  final List<OfferItem> offers;

  const OffersLoaded({required this.offers});

  List<OfferItem> get activeOffers =>
      offers.where((o) => o.isActive).toList();

  int get activeCount => activeOffers.length;

  // Pas de limite — toujours false
  bool get quotaReached => false;

  OffersLoaded copyWith({List<OfferItem>? offers}) {
    return OffersLoaded(offers: offers ?? this.offers);
  }

  @override
  List<Object?> get props => [offers];
}

class OffersError extends OffersState {
  final String message;
  const OffersError(this.message);

  @override
  List<Object?> get props => [message];
}

class OfferToggling extends OffersState {
  final List<OfferItem> offers;
  final String togglingOfferId;

  const OfferToggling({
    required this.offers,
    required this.togglingOfferId,
  });

  @override
  List<Object?> get props => [offers, togglingOfferId];
}