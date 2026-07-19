import 'package:equatable/equatable.dart';

class SearchOfferItem extends Equatable {
  final String offerId;
  final String title;
  final String companyName;
  final String? companyLogo;
  final String offerType;
  final String location;
  final int matchScore;
  final List<String> requiredSkills;

  const SearchOfferItem({
    required this.offerId,
    required this.title,
    required this.companyName,
    this.companyLogo,
    required this.offerType,
    required this.location,
    required this.matchScore,
    this.requiredSkills = const [],
  });

  @override
  List<Object?> get props => [
    offerId,
    title,
    companyName,
    companyLogo,
    offerType,
    location,
    matchScore,
    requiredSkills,
  ];
}

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  final List<String> recentSearches;
  const SearchInitial({this.recentSearches = const []});

  @override
  List<Object?> get props => [recentSearches];
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final List<SearchOfferItem> results;
  final String query;
  final String
  activeFilter; // 'Tous', 'CDI', 'CDD', 'Stage académique', 'Stage pro'

  const SearchLoaded({
    required this.results,
    required this.query,
    this.activeFilter = 'Tous',
  });

  List<SearchOfferItem> get filteredResults {
    if (activeFilter == 'Tous') return results;
    final map = {
      'CDI': 'cdi',
      'CDD': 'cdd',
      'Stage académique': 'stage_academique',
      'Stage pro': 'stage_professionnel',
    };
    return results.where((r) => r.offerType == map[activeFilter]).toList();
  }

  SearchLoaded copyWith({
    List<SearchOfferItem>? results,
    String? query,
    String? activeFilter,
  }) {
    return SearchLoaded(
      results: results ?? this.results,
      query: query ?? this.query,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  @override
  List<Object?> get props => [results, query, activeFilter];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
