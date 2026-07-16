import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';

class CompanyVerificationPage extends StatefulWidget {
  const CompanyVerificationPage({super.key});

  @override
  State<CompanyVerificationPage> createState() =>
      _CompanyVerificationPageState();
}

class _CompanyVerificationPageState extends State<CompanyVerificationPage> {
  // États possibles : 'none', 'uploading', 'pending', 'verified', 'rejected'
  String _status = 'none';

  Future<void> _handleUpload() async {
    setState(() => _status = 'uploading');

    // Simulation appel Document Verification Agent (mode RCCM)
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _status = 'pending');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsLight.bgDark,
      appBar: AppBar(
        backgroundColor: AppColorsLight.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/company/profile');
            }
          },
        ),
        title: const Text('Vérification de votre entreprise'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColorsLight.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: AppColorsLight.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColorsLight.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Document requis',
                          style: AppTypography.headingSmall.copyWith(
                            color: AppColorsLight.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'RCCM (Registre du Commerce et du Crédit Mobilier) — document officiel attestant l\'existence légale de votre entreprise.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Status display
              if (_status == 'none') _buildUploadZone(),
              if (_status == 'uploading') _buildUploadingState(),
              if (_status == 'pending') _buildPendingState(),
              if (_status == 'verified') _buildVerifiedState(),
              if (_status == 'rejected') _buildRejectedState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _handleUpload,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColorsLight.bgCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: AppColorsLight.bgSurface,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColorsLight.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: AppColorsLight.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Uploader le RCCM', style: AppTypography.headingSmall),
            const SizedBox(height: 4),
            Text('format requis: PDF, JPG ou PNG', style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadingState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColorsLight.bgCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColorsLight.bgSurface),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColorsLight.primary),
          const SizedBox(height: AppSpacing.md),
          Text('L\'IA analyse votre document...',
              style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildPendingState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColorsLight.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_top_rounded,
              color: AppColorsLight.warning, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            'En cours de révision',
            style: AppTypography.headingSmall.copyWith(
              color: AppColorsLight.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vous serez notifié dans les 24h',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColorsLight.success.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.verified_rounded,
              color: AppColorsLight.success, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Entreprise vérifiée !',
            style: AppTypography.headingSmall.copyWith(
              color: AppColorsLight.success,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Vous avez obtenu le badge vérifié',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColorsLight.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cancel_rounded,
              color: AppColorsLight.error, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Document refusé',
            style: AppTypography.headingSmall.copyWith(
              color: AppColorsLight.error,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Document illisible ou non conforme. Veuillez réessayer.',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton(
            onPressed: () => setState(() => _status = 'none'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsLight.primary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}