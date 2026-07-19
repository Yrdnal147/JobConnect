import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offer_detail_state.dart';
import 'offers_state.dart';

class OfferDetailCubit extends Cubit<OfferDetailState> {
  final SupabaseClient _client;

  OfferDetailCubit({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      super(const OfferDetailInitial());

  // ─── Chargement de l'offre ────────────────────────────────────────────────

  Future<void> loadOffer(String offerId) async {
    emit(const OfferDetailLoading());

    try {
      final offerRes = await _client
          .from('offers')
          .select(
            'id, title, offer_type, location, is_active, created_at, duration_months, salary_range, description, required_skills, min_education, years_of_experience',
          )
          .eq('id', offerId)
          .maybeSingle();

      if (offerRes == null) {
        emit(const OfferDetailError(message: 'Offre introuvable.'));
        return;
      }

      int applicationsCount = 0;
      try {
        final appsRes = await _client
            .from('applications')
            .select('id')
            .eq('offer_id', offerId);
        applicationsCount = (appsRes as List).length;
      } catch (_) {}

      final offer = OfferItem(
        offerId: offerRes['id'] as String,
        title: offerRes['title'] as String,
        offerType: offerRes['offer_type'] as String? ?? '',
        location: offerRes['location'] as String? ?? 'Douala',
        applicationsCount: applicationsCount,
        isActive: offerRes['is_active'] as bool? ?? true,
        postedAt: _formatDate(offerRes['created_at'] as String?),
        durationMonths: offerRes['duration_months'] as int?,
        salaryRange: offerRes['salary_range'] as String?,
        description: offerRes['description'] as String? ?? '',
        requiredSkills: List<String>.from(
          offerRes['required_skills'] as List? ?? [],
        ),
        minEducation: offerRes['min_education'] as String? ?? '',
        yearsOfExperience: offerRes['years_of_experience'] as int? ?? 0,
      );

      emit(OfferDetailLoaded(offer: offer));
    } catch (e) {
      emit(OfferDetailError(message: e.toString()));
    }
  }

  // ─── Modification de l'offre ──────────────────────────────────────────────

  Future<void> updateOffer({
    required String offerId,
    required String title,
    required String description,
    required String offerType,
    required String minEducation,
    required String location,
    required List<String> requiredSkills,
    required int yearsOfExperience,
    required bool isActive,
    int? durationMonths,
    String? salaryRange,
  }) async {
    final current = state;
    final currentOffer = current is OfferDetailLoaded ? current.offer : null;
    if (currentOffer == null) return;

    if (title.trim().isEmpty) {
      emit(
        OfferDetailError(
          message: 'Le titre est obligatoire.',
          lastKnownOffer: currentOffer,
        ),
      );
      _restoreLoaded(currentOffer);
      return;
    }

    emit(OfferDetailUpdating(offer: currentOffer));

    try {
      await _client
          .from('offers')
          .update({
            'title': title.trim(),
            'description': description.trim(),
            'offer_type': offerType,
            'min_education': minEducation,
            'location': location.trim().isEmpty ? 'Douala' : location.trim(),
            'required_skills': requiredSkills,
            'years_of_experience': yearsOfExperience,
            'is_active': isActive,
            if (durationMonths != null) 'duration_months': durationMonths,
            if (salaryRange != null && salaryRange.isNotEmpty)
              'salary_range': salaryRange,
          })
          .eq('id', offerId);

      await loadOffer(offerId);

      final loaded = state;
      if (loaded is OfferDetailLoaded) {
        emit(OfferDetailUpdated(offer: loaded.offer));
        await Future.delayed(const Duration(seconds: 1));
        if (!isClosed) emit(OfferDetailLoaded(offer: loaded.offer));
      }
    } catch (e) {
      emit(
        OfferDetailError(
          message: 'Impossible de modifier : ${e.toString()}',
          lastKnownOffer: currentOffer,
        ),
      );
      _restoreLoaded(currentOffer);
    }
  }

  // ─── Suppression en cascade ───────────────────────────────────────────────

  Future<void> deleteOffer(String offerId) async {
    final current = state;
    final currentOffer = current is OfferDetailLoaded ? current.offer : null;
    if (currentOffer == null) return;

    emit(OfferDetailDeleting(offer: currentOffer));

    try {
      // 1. Récupère les application_ids liées à cette offre
      final appsRes = await _client
          .from('applications')
          .select('id')
          .eq('offer_id', offerId);

      final applicationsList = (appsRes as List);

      // 2. Supprime les messages liés aux conversations de ces applications
      for (final app in applicationsList) {
        try {
          final convRes = await _client
              .from('conversations')
              .select('id')
              .eq('application_id', app['id'] as String)
              .maybeSingle();

          if (convRes != null) {
            await _client
                .from('messages')
                .delete()
                .eq('conversation_id', convRes['id'] as String);
          }
        } catch (_) {}
      }

      // 3. Supprime les conversations
      for (final app in applicationsList) {
        try {
          await _client
              .from('conversations')
              .delete()
              .eq('application_id', app['id'] as String);
        } catch (_) {}
      }

      // 4. Supprime les applications
      await _client.from('applications').delete().eq('offer_id', offerId);

      // 5. Supprime l'offre
      await _client.from('offers').delete().eq('id', offerId);

      emit(const OfferDetailDeleted());
    } catch (e) {
      emit(
        OfferDetailError(
          message: 'Impossible de supprimer : ${e.toString()}',
          lastKnownOffer: currentOffer,
        ),
      );
      _restoreLoaded(currentOffer);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _restoreLoaded(OfferItem offer) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) emit(OfferDetailLoaded(offer: offer));
    });
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      const months = [
        'Jan',
        'Fév',
        'Mar',
        'Avr',
        'Mai',
        'Jun',
        'Jul',
        'Aoû',
        'Sep',
        'Oct',
        'Nov',
        'Déc',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return '';
    }
  }
}
