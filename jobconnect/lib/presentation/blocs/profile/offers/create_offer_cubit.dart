import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'create_offer_state.dart';
import '../../../../data/datasources/mastra_remote_datasource.dart';

class CreateOfferCubit extends Cubit<CreateOfferState> {
  final SupabaseClient _client;
  final IMastraRemoteDataSource? _mastraRemoteDataSource;

  CreateOfferCubit({SupabaseClient? client, IMastraRemoteDataSource? mastraRemoteDataSource})
      : _client = client ?? Supabase.instance.client,
        _mastraRemoteDataSource = mastraRemoteDataSource,
        super(const CreateOfferInitial());

  // ─── Publication de l'offre ───────────────────────────────────────────────

  Future<void> publishOffer({
    required String title,
    required String description,
    required String offerType,
    required String minEducation,
    required String location,
    required List<String> requiredSkills,
    required int yearsOfExperience,
    int? durationMonths,
    String? salaryRange,
  }) async {
    // Validation des champs obligatoires
    if (title.trim().isEmpty) {
      emit(const CreateOfferError('Le titre du poste est obligatoire.'));
      _resetAfterError();
      return;
    }
    if (description.trim().isEmpty) {
      emit(const CreateOfferError('La description est obligatoire.'));
      _resetAfterError();
      return;
    }
    if (requiredSkills.isEmpty) {
      emit(const CreateOfferError(
          'Ajoutez au moins une compétence requise.'));
      _resetAfterError();
      return;
    }

    emit(const CreateOfferPublishing());

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const CreateOfferError('Utilisateur non connecté.'));
        return;
      }

      // Récupère l'id entreprise
      final companyRow = await _client
          .from('companies')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (companyRow == null) {
        emit(const CreateOfferError(
            'Profil entreprise introuvable. Complétez votre profil d\'abord.'));
        return;
      }

      final companyId = companyRow['id'] as String;

      // Insère l'offre dans Supabase
      final response = await _client
          .from('offers')
          .insert({
            'company_id': companyId,
            'title': title.trim(),
            'description': description.trim(),
            'offer_type': offerType,
            'required_skills': requiredSkills,
            'min_education': minEducation,
            'location': location.trim().isEmpty ? 'Douala' : location.trim(),
            'is_active': true,
            'years_of_experience': yearsOfExperience,
            if (durationMonths != null) 'duration_months': durationMonths,
            if (salaryRange != null && salaryRange.isNotEmpty)
              'salary_range': salaryRange,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      // Met à jour le compteur d'offres actives
      try {
        await _client.rpc('increment_active_offers', params: {
          'company_id_param': companyId,
        });
      } catch (_) {
        // Non bloquant si la fonction RPC n'existe pas
      }

      final offerId = response['id'] as String;

      // Appel optionnel à Mastra pour générer l'embedding de l'offre
      if (_mastraRemoteDataSource != null) {
        try {
          await _mastraRemoteDataSource.startWorkflow(
            '/api/workflows/offer-pipeline/start',
            {'offerId': offerId},
          );
        } catch (e) {
          // Non bloquant si l'embedding échoue
          print('Erreur lors de la génération de l\'embedding pour l\'offre : $e');
        }
      }

      emit(CreateOfferSuccess(offerId: offerId));
    } catch (e) {
      emit(CreateOfferError(
          'Impossible de publier l\'offre : ${e.toString()}'));
    }
  }

  // ─── Reset après erreur ───────────────────────────────────────────────────

  void _resetAfterError() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!isClosed) emit(const CreateOfferInitial());
    });
  }

  void reset() => emit(const CreateOfferInitial());
}