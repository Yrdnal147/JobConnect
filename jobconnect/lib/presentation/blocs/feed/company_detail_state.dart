import 'package:equatable/equatable.dart';

class CompanyOfferItem extends Equatable {
  final String offerId;
  final String title;
  final String offerType;
  final String location;

  const CompanyOfferItem({
    required this.offerId,
    required this.title,
    required this.offerType,
    required this.location,
  });

  @override
  List<Object?> get props => [offerId, title, offerType, location];
}

class CompanyDetailData extends Equatable {
  final String companyId;
  final String name;
  final String sector;
  final String size;
  final String description;
  final String ceoName;
  final String? website;
  final String location;
  final String? logoUrl;
  final bool isVerified;
  final int activeOffersCount;
  final List<CompanyOfferItem> activeOffers;

  const CompanyDetailData({
    required this.companyId,
    required this.name,
    this.sector = '',
    this.size = '',
    this.description = '',
    this.ceoName = '',
    this.website,
    this.location = 'Douala',
    this.logoUrl,
    this.isVerified = false,
    this.activeOffersCount = 0,
    this.activeOffers = const [],
  });

  @override
  List<Object?> get props => [
        companyId, name, sector, size, description,
        ceoName, website, location, logoUrl,
        isVerified, activeOffersCount, activeOffers,
      ];
}

abstract class CompanyDetailState extends Equatable {
  const CompanyDetailState();

  @override
  List<Object?> get props => [];
}

class CompanyDetailInitial extends CompanyDetailState {
  const CompanyDetailInitial();
}

class CompanyDetailLoading extends CompanyDetailState {
  const CompanyDetailLoading();
}

class CompanyDetailLoaded extends CompanyDetailState {
  final CompanyDetailData company;
  const CompanyDetailLoaded({required this.company});

  @override
  List<Object?> get props => [company];
}

class CompanyDetailError extends CompanyDetailState {
  final String message;
  const CompanyDetailError(this.message);

  @override
  List<Object?> get props => [message];
}