import 'package:equatable/equatable.dart';

abstract class CreateOfferState extends Equatable {
  const CreateOfferState();

  @override
  List<Object?> get props => [];
}

class CreateOfferInitial extends CreateOfferState {
  const CreateOfferInitial();
}

/// Publication en cours vers Supabase
class CreateOfferPublishing extends CreateOfferState {
  const CreateOfferPublishing();
}

/// Offre publiée avec succès
class CreateOfferSuccess extends CreateOfferState {
  final String offerId;
  const CreateOfferSuccess({required this.offerId});

  @override
  List<Object?> get props => [offerId];
}

/// Erreur lors de la publication
class CreateOfferError extends CreateOfferState {
  final String message;
  const CreateOfferError(this.message);

  @override
  List<Object?> get props => [message];
}
