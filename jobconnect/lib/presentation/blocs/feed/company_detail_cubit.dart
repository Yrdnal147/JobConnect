import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'company_detail_state.dart';

class CompanyDetailCubit extends Cubit<CompanyDetailState> {
  final SupabaseClient _client;

  CompanyDetailCubit({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client,
        super(const CompanyDetailInitial());

  // ─── Charge les détails de l'entreprise ──────────────────────────────────

  Future<void> loadCompany(String companyId) async {
    emit(const CompanyDetailLoading());

    try {
      // Charge les infos de l'entreprise
      final companyRes = await _client
          .from('companies')
          .select('''
            id, name, sector, size, description,
            ceo_name, website, location, logo_url,
            is_verified, active_offers_count
          ''')
          .eq('id', companyId)
          .maybeSingle();

      if (companyRes == null) {
        emit(const CompanyDetailError('Entreprise introuvable'));
        return;
      }

      // Charge les offres actives de l'entreprise
      List<CompanyOfferItem> activeOffers = [];
      try {
        final offersRes = await _client
            .from('offers')
            .select('id, title, offer_type, location')
            .eq('company_id', companyId)
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(5);

        activeOffers = (offersRes as List).map((offer) {
          return CompanyOfferItem(
            offerId: offer['id'] as String,
            title: offer['title'] as String,
            offerType: offer['offer_type'] as String? ?? '',
            location: offer['location'] as String? ?? 'Douala',
          );
        }).toList();
      } catch (_) {}

      final company = CompanyDetailData(
        companyId: companyRes['id'] as String,
        name: companyRes['name'] as String? ?? 'Entreprise',
        sector: companyRes['sector'] as String? ?? '',
        size: companyRes['size'] as String? ?? '',
        description: companyRes['description'] as String? ?? '',
        ceoName: companyRes['ceo_name'] as String? ?? '',
        website: companyRes['website'] as String?,
        location: companyRes['location'] as String? ?? 'Douala',
        logoUrl: companyRes['logo_url'] as String?,
        isVerified: companyRes['is_verified'] as bool? ?? false,
        activeOffersCount:
            companyRes['active_offers_count'] as int? ?? activeOffers.length,
        activeOffers: activeOffers,
      );

      emit(CompanyDetailLoaded(company: company));
    } catch (e) {
      emit(CompanyDetailError(e.toString()));
    }
  }

  // ─── Refresh ──────────────────────────────────────────────────────────────

  Future<void> refresh(String companyId) => loadCompany(companyId);
}