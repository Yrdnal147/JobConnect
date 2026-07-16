import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\profile\profile_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Replace _buildHeader
header_pattern = r"Widget _buildHeader\([\s\S]*?Widget _buildVerificationBadge"
new_header = """Widget _buildHeader(
      StudentProfileData? profile, bool isPhotoUploading) {
    final score = profile?.profileScore ?? 0;
    final scoreColor = score >= 75
        ? AppColorsLight.success
        : score >= 50
            ? AppColorsLight.warning
            : AppColorsLight.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColorsLight.primary.withOpacity(0.2), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar avec jauge de score autour
          GestureDetector(
            onTap: isPhotoUploading ? null : _pickAvatar,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    backgroundColor: scoreColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    strokeWidth: 4,
                  ),
                ),
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: AppColorsLight.bgCard,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: scoreColor.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: isPhotoUploading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColorsLight.primary,
                            strokeWidth: 2,
                          ),
                        )
                      : UserAvatar(
                          imageUrl: profile?.photoUrl,
                          radius: 37,
                          defaultIcon: Icons.person_rounded,
                          backgroundColor: Colors.transparent,
                          iconColor: AppColorsLight.primary,
                        ),
                ),
                if (!isPhotoUploading)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColorsLight.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColorsLight.bgCard,
                          width: 2.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile?.fullName ?? 'profile.default_name'.tr(),
                  style: AppTypography.headingMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (profile?.targetOpportunity.isNotEmpty == true)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColorsLight.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      profile!.targetOpportunity,
                      style: AppTypography.caption.copyWith(
                        color: AppColorsLight.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  profile?.email ?? '',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildVerificationBadge(profile?.verificationStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge"""

content = re.sub(header_pattern, new_header, content, flags=re.DOTALL)

# 2. Replace _buildScoreCard (now acts purely as CV section since score is in Header)
score_card_pattern = r"Widget _buildScoreCard\([\s\S]*?Widget _buildSkillsSection"
new_score_card = """Widget _buildScoreCard(BuildContext context,
      StudentProfileData? profile, bool isCvUploading, bool isCvAnalyzing) {
    
    final bool hasCv = profile?.cvUrl != null || profile?.cvFileName != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: hasCv ? AppColorsLight.success.withOpacity(0.05) : AppColorsLight.primary.withOpacity(0.03),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: hasCv ? AppColorsLight.success.withOpacity(0.3) : AppColorsLight.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasCv ? Icons.check_circle_rounded : Icons.document_scanner_rounded,
                color: hasCv ? AppColorsLight.success : AppColorsLight.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'profile.cv.title'.tr(), // "Mon CV"
                style: AppTypography.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          if (hasCv) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: AppColorsLight.success.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColorsLight.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColorsLight.error, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.cvFileName ?? 'CV Uploadé',
                          style: AppTypography.labelLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vérifié par l\\'IA',
                          style: AppTypography.caption.copyWith(color: AppColorsLight.success),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Bouton upload CV stylisé
          InkWell(
            onTap: (isCvUploading || isCvAnalyzing) ? null : _pickCv,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: hasCv ? Colors.transparent : AppColorsLight.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: hasCv ? Border.all(color: AppColorsLight.primary) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCvUploading || isCvAnalyzing)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: hasCv ? AppColorsLight.primary : Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Icon(
                      hasCv ? Icons.sync_rounded : Icons.cloud_upload_rounded,
                      size: 20,
                      color: hasCv ? AppColorsLight.primary : Colors.white,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    isCvAnalyzing
                        ? AppStrings.aiAnalyzing
                        : isCvUploading
                            ? 'profile.cv.uploading'.tr()
                            : hasCv
                                ? 'Mettre à jour le CV'
                                : 'Importer un CV (PDF)',
                    style: AppTypography.labelLarge.copyWith(
                      color: hasCv ? AppColorsLight.primary : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Compétences ──────────────────────────────────────────────────────────

  Widget _buildSkillsSection"""

content = re.sub(score_card_pattern, new_score_card, content, flags=re.DOTALL)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated header and score card.")
