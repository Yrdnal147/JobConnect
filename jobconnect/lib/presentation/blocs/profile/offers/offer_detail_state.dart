import 'package:equatable/equatable.dart';
import 'offers_state.dart';

abstract class OfferDetailState extends Equatable {
  const OfferDetailState();

  @override
  List<Object?> get props => [];
}

class OfferDetailInitial extends OfferDetailState {
  const OfferDetailInitial();
}

class OfferDetailLoading extends OfferDetailState {
  const OfferDetailLoading();
}

class OfferDetailLoaded extends OfferDetailState {
  final OfferItem offer;

  const OfferDetailLoaded({required this.offer});

  @override
  List<Object?> get props => [offer];
}

class OfferDetailUpdating extends OfferDetailState {
  final OfferItem offer;
  const OfferDetailUpdating({required this.offer});

  @override
  List<Object?> get props => [offer];
}

class OfferDetailUpdated extends OfferDetailState {
  final OfferItem offer;
  const OfferDetailUpdated({required this.offer});

  @override
  List<Object?> get props => [offer];
}

class OfferDetailDeleting extends OfferDetailState {
  final OfferItem offer;
  const OfferDetailDeleting({required this.offer});

  @override
  List<Object?> get props => [offer];
}

class OfferDetailDeleted extends OfferDetailState {
  const OfferDetailDeleted();
}

class OfferDetailError extends OfferDetailState {
  final String message;
  final OfferItem? lastKnownOffer;

  const OfferDetailError({required this.message, this.lastKnownOffer});

  @override
  List<Object?> get props => [message, lastKnownOffer];
}
