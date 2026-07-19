import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/datasources/company_datasource.dart';
import 'company_profil_state.dart';

class CompanyProfileCubit extends Cubit<CompanyProfileState> {
  final CompanyDataSource _dataSource;

  CompanyProfileCubit({CompanyDataSource? dataSource})
    : _dataSource = dataSource ?? CompanyDataSource(),
      super(const CompanyProfileInitial());

  // ─── Load ────────────────────────────────────────────────────────────────

  Future<void> loadProfile() async {
    emit(const CompanyProfileLoading());

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final email = user?.email ?? '';
      final metaName =
          user?.userMetadata?['full_name'] as String? ?? 'Entreprise';

      final data = await _dataSource.fetchCompanyProfile();

      if (data == null) {
        emit(
          CompanyProfileLoaded(
            profile: CompanyProfileData(name: metaName, email: email),
            isDirty: false,
          ),
        );
        return;
      }

      final profile = CompanyProfileData(
        name: data['name'] as String? ?? metaName,
        email: email,
        sector: data['sector'] as String? ?? '',
        size: data['size'] as String? ?? '',
        description: data['description'] as String? ?? '',
        ceoName: data['ceo_name'] as String? ?? '',
        website: data['website'] as String? ?? '',
        location: data['location'] as String? ?? 'Douala',
        logoUrl: data['logo_url'] as String?,
        verificationStatus: _parseVerificationStatus(
          data['verification_status'] as String?,
        ),
        isVerified: data['is_verified'] as bool? ?? false,
      );

      emit(CompanyProfileLoaded(profile: profile, isDirty: false));
    } catch (e) {
      emit(CompanyProfileError(message: e.toString()));
    }
  }

  // ─── Field updates ────────────────────────────────────────────────────────

  void updateName(String value) => _updateField((p) => p.copyWith(name: value));
  void updateSector(String value) =>
      _updateField((p) => p.copyWith(sector: value));
  void updateSize(String value) => _updateField((p) => p.copyWith(size: value));
  void updateDescription(String value) =>
      _updateField((p) => p.copyWith(description: value));
  void updateCeoName(String value) =>
      _updateField((p) => p.copyWith(ceoName: value));
  void updateWebsite(String value) =>
      _updateField((p) => p.copyWith(website: value));
  void updateLocation(String value) =>
      _updateField((p) => p.copyWith(location: value));

  void _updateField(CompanyProfileData Function(CompanyProfileData) updater) {
    final current = state;
    if (current is CompanyProfileLoaded) {
      emit(current.copyWith(profile: updater(current.profile), isDirty: true));
    }
  }

  // ─── Save ────────────────────────────────────────────────────────────────

  Future<void> saveProfile() async {
    final current = state;
    if (current is! CompanyProfileLoaded) return;

    final profile = current.profile;

    if (profile.name.trim().isEmpty) {
      emit(
        CompanyProfileError(
          message: 'Le nom de l\'entreprise est obligatoire.',
          lastKnownProfile: profile,
        ),
      );
      _restoreLoaded(profile);
      return;
    }

    emit(CompanyProfileSaving(profile: profile));

    try {
      final saved = await _dataSource.saveCompanyProfile(
        name: profile.name.trim(),
        sector: profile.sector.trim(),
        size: profile.size,
        description: profile.description.trim(),
        ceoName: profile.ceoName.trim(),
        website: profile.website.trim(),
        location: profile.location.trim(),
        logoUrl: profile.logoUrl,
      );

      final updatedProfile = profile.copyWith(
        name: saved['name'] as String? ?? profile.name,
        sector: saved['sector'] as String? ?? profile.sector,
        verificationStatus: _parseVerificationStatus(
          saved['verification_status'] as String?,
        ),
        isVerified: saved['is_verified'] as bool? ?? profile.isVerified,
      );

      emit(CompanyProfileSaved(profile: updatedProfile));

      await Future.delayed(const Duration(seconds: 1));
      if (!isClosed) {
        emit(CompanyProfileLoaded(profile: updatedProfile, isDirty: false));
      }
    } catch (e) {
      emit(
        CompanyProfileError(
          message: 'Impossible d\'enregistrer : ${e.toString()}',
          lastKnownProfile: profile,
        ),
      );
      _restoreLoaded(profile);
    }
  }

  // ─── Logo upload ─────────────────────────────────────────────────────────

  Future<void> uploadLogo(File imageFile) async {
    final current = state;
    if (current is! CompanyProfileLoaded) return;

    final profile = current.profile;
    emit(CompanyLogoUploading(profile: profile));

    try {
      final url = await _dataSource.uploadCompanyLogo(imageFile);

      await _dataSource.saveCompanyProfile(
        name: profile.name,
        sector: profile.sector,
        size: profile.size,
        description: profile.description,
        ceoName: profile.ceoName,
        website: profile.website,
        location: profile.location,
        logoUrl: url,
      );

      final updatedProfile = profile.copyWith(logoUrl: url);
      emit(CompanyProfileLoaded(profile: updatedProfile, isDirty: false));
    } catch (e) {
      emit(
        CompanyProfileError(
          message: 'Erreur lors du téléchargement : ${e.toString()}',
          lastKnownProfile: profile,
        ),
      );
      _restoreLoaded(profile);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _restoreLoaded(CompanyProfileData profile) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) {
        emit(CompanyProfileLoaded(profile: profile, isDirty: true));
      }
    });
  }

  CompanyVerificationStatus _parseVerificationStatus(String? raw) {
    switch (raw) {
      case 'pending':
        return CompanyVerificationStatus.pending;
      case 'verified':
        return CompanyVerificationStatus.verified;
      case 'rejected':
        return CompanyVerificationStatus.rejected;
      default:
        return CompanyVerificationStatus.none;
    }
  }
}
