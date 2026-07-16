import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offers_state.dart';

class OffersCubit extends Cubit<OffersState> {
  final SupabaseClient _client;

  OffersCubit({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        super(const OffersInitial());

  // ─── Charge toutes les offres ─────────────────────────────────────────────

  Future<void> loadOffers() async {
    emit(const OffersLoading());

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const OffersError('Utilisateur non connecté'));
        return;
      }

      // Récupère l'id entreprise
      final companyRow = await _client
          .from('companies')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (companyRow == null) {
        emit(const OffersLoaded(offers: []));
        return;
      }

      final companyId = companyRow['id'] as String;

      // Récupère toutes les offres
      final offersRes = await _client
          .from('offers')
          .select('id, title, offer_type, location, is_active, created_at, duration_months, salary_range')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);

      final offersRaw = offersRes as List;

      if (offersRaw.isEmpty) {
        emit(const OffersLoaded(offers: []));
        return;
      }

      // Pour chaque offre, compte les candidatures
      final List<OfferItem> offers = [];

      for (final offer in offersRaw) {
        try {
          int applicationsCount = 0;
          try {
            final appsRes = await _client
                .from('applications')
                .select('id')
                .eq('offer_id', offer['id'] as String);
            applicationsCount = (appsRes as List).length;
          } catch (_) {}

          offers.add(OfferItem(
            offerId: offer['id'] as String,
            title: offer['title'] as String,
            offerType: offer['offer_type'] as String? ?? '',
            location: offer['location'] as String? ?? 'Douala',
            applicationsCount: applicationsCount,
            isActive: offer['is_active'] as bool? ?? true,
            postedAt: _formatDate(offer['created_at'] as String?),
            durationMonths: offer['duration_months'] as int?,
            salaryRange: offer['salary_range'] as String?,
          ));
        } catch (_) {
          continue;
        }
      }

      emit(OffersLoaded(offers: offers));
    } catch (e) {
      emit(OffersError(e.toString()));
    }
  }

  // ─── Toggle actif/inactif ─────────────────────────────────────────────────

  Future<void> toggleOfferStatus(String offerId, bool newValue) async {
    final current = state;
    if (current is! OffersLoaded) return;

    // Affiche un état de chargement sur cette offre spécifique
    emit(OfferToggling(
      offers: current.offers,
      togglingOfferId: offerId,
    ));

    try {
      await _client
          .from('offers')
          .update({'is_active': newValue})
          .eq('id', offerId);

      // Met à jour la liste localement sans recharger
      final updatedOffers = current.offers.map((o) {
        if (o.offerId == offerId) {
          return o.copyWith(isActive: newValue);
        }
        return o;
      }).toList();

      emit(OffersLoaded(offers: updatedOffers));
    } catch (e) {
      // En cas d'erreur, restaure l'état précédent
      emit(OffersLoaded(offers: current.offers));
    }
  }

  // ─── Refresh ──────────────────────────────────────────────────────────────

  Future<void> refresh() => loadOffers();

  // ─── Helper ──────────────────────────────────────────────────────────────

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }
}