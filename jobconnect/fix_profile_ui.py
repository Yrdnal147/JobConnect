import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\profile\profile_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add score badge in header
header_pattern = r"(Expanded\(\s*child: Column\(\s*crossAxisAlignment: CrossAxisAlignment\.start,\s*children: \[)\s*(Text\(\s*profile\?\.fullName[\s\S]*?overflow: TextOverflow\.ellipsis,\s*\),)"
def header_replacement(match):
    prefix = match.group(1)
    text_widget = match.group(2)
    new_header = f"""{prefix}
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: {text_widget.strip()}
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(color: scoreColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 14, color: scoreColor),
                          const SizedBox(width: 4),
                          Text(
                            '${{score}}%',
                            style: AppTypography.labelLarge.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),"""
    return new_header

content = re.sub(header_pattern, header_replacement, content)

# 2. Fix 'profile.cv.title' issue in score card
cv_title_pattern = r"Text\(\s*'profile\.cv\.title'\.tr\(\),\s*//\s*\"Mon CV\"\s*style:\s*AppTypography\.headingSmall,\s*\),"
content = re.sub(cv_title_pattern, "Text('CV & Documents', style: AppTypography.headingSmall,),", content)

# 3. Fix AppStrings.aiAnalyzing overflow
analyzing_pattern = r"Text\(\s*isCvAnalyzing\s*\?[\s\S]*?style:\s*AppTypography\.labelLarge\.copyWith\([\s\S]*?\),\s*\),"
def analyzing_replacement(match):
    return f"""Expanded(
                    child: {match.group(0).strip()[:-1]}
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),"""
content = re.sub(analyzing_pattern, analyzing_replacement, content)

# 4. Fix _SkillChip overflow
skillchip_pattern = r"class _SkillChip extends StatelessWidget \{[\s\S]*?\}\n\}"
new_skillchip = """class _SkillChip extends StatelessWidget {
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
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.only(left: 12, right: 4, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
content = re.sub(skillchip_pattern, new_skillchip, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Profile fixes applied successfully.")
