import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\profile\profile_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildSkillsSection
skills_pattern = r"Widget _buildSkillsSection\([\s\S]*?Widget _buildVerificationSection"
new_skills = """Widget _buildSkillsSection(
      BuildContext context, StudentProfileData? profile) {
    final skills = profile?.skills ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('profile.skills.title'.tr(), style: AppTypography.headingSmall),
            TextButton.icon(
              onPressed: () => _showAddSkillDialog(context),
              icon: const Icon(Icons.add_rounded,
                  size: 16, color: AppColorsLight.primary),
              label: Text(
                'profile.skills.add'.tr(),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColorsLight.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColorsLight.bgCard,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(color: AppColorsLight.bgSurface),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: skills.isEmpty
              ? Center(
                  child: Column(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 32,
                          color: AppColorsLight.textTertiary),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'profile.skills.empty'.tr(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColorsLight.textTertiary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () =>
                            _showAddSkillDialog(context),
                        child: Text(
                          'profile.skills.add_first'.tr(),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColorsLight.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ...skills.map((skill) => _SkillChip(
                          label: skill.name,
                          skillType: skill.skillType,
                          onDelete: () =>
                              _cubit.removeSkill(skill.id),
                        )),
                    // Bouton ajouter stylisé
                    GestureDetector(
                      onTap: () => _showAddSkillDialog(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorsLight.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                          border: Border.all(
                              color: AppColorsLight.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded,
                                size: 14,
                                color: AppColorsLight.primary),
                            const SizedBox(width: 4),
                            Text(
                              'profile.skills.add'.tr(),
                              style: AppTypography.labelSmall
                                  .copyWith(
                                color: AppColorsLight.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ─── Vérification ─────────────────────────────────────────────────────────

  Widget _buildVerificationSection"""
content = re.sub(skills_pattern, new_skills, content, flags=re.DOTALL)

# Let's also update _SkillChip class if it's there
skill_chip_pattern = r"class _SkillChip extends StatelessWidget \{[\s\S]*?\}\n\}"
new_skill_chip = """class _SkillChip extends StatelessWidget {
  final String label;
  final String skillType;
  final VoidCallback onDelete;

  const _SkillChip({
    required this.label,
    required this.skillType,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color getSkillColor() {
      switch (skillType.toLowerCase()) {
        case 'technical':
          return AppColorsLight.primary;
        case 'soft':
          return const Color(0xFF00D9FF);
        case 'language':
          return AppColorsLight.success;
        default:
          return AppColorsLight.textSecondary;
      }
    }

    final color = getSkillColor();

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  size: 14, color: color.withOpacity(0.8)),
            ),
          ),
        ],
      ),
    );
  }
}"""
content = re.sub(skill_chip_pattern, new_skill_chip, content, flags=re.DOTALL)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated skills section and skill chip.")
