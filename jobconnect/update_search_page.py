import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\search\search_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the Container inside ListView.builder with _SearchOfferCard
pattern_container = r"""              return Container\(\s*margin: const EdgeInsets\.only\(bottom: AppSpacing\.md\),\s*decoration: BoxDecoration\(.*?child: Material\(\s*color: Colors\.transparent,\s*borderRadius: BorderRadius\.circular\(AppSpacing\.radiusLg\),\s*clipBehavior: Clip\.antiAlias,\s*child: InkWell\(\s*onTap: \(\) =>\s*context\.push\('/student/offer/\$\{offer\.offerId\}'\),\s*child: Padding\(.*?\)"""
pattern_container_compiled = re.compile(pattern_container, re.DOTALL)

replacement_container = """              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/student/offer/${offer.offerId}'),
                    child: _SearchOfferCard(
                      offer: offer,
                      formatType: _formatOfferType,
                    ),
                  ),
                ),
              );"""

# The above pattern won't match exactly because of formatting.
# Let's use a simpler string replacement for the ListView.builder body.

def replace_between(content, start_str, end_str, new_str):
    start_idx = content.find(start_str)
    if start_idx == -1: return content
    end_idx = content.find(end_str, start_idx)
    if end_idx == -1: return content
    return content[:start_idx] + new_str + content[end_idx + len(end_str):]

start_str = "              return Container(\n                margin: const EdgeInsets.only(bottom: AppSpacing.md),"
end_str = "              );\n            },\n          ),\n        ),"

content = replace_between(content, start_str, end_str, replacement_container + "\n            },\n          ),\n        ),")

# Now append _SearchOfferCard to the end of the file
search_offer_card_class = """

class _SearchOfferCard extends StatelessWidget {
  final SearchOfferItem offer;
  final String Function(String) formatType;

  const _SearchOfferCard({
    required this.offer,
    required this.formatType,
  });

  static const _avatarGradients = [
    [Color(0xFF0052CC), Color(0xFF00D9FF)],
    [Color(0xFF00D9FF), Color(0xFFFF6B6B)],
    [Color(0xFFFF6B6B), Color(0xFF0052CC)],
    [Color(0xFF0052CC), Color(0xFFFF6B6B)],
    [Color(0xFF00D9FF), Color(0xFF0052CC)],
  ];

  @override
  Widget build(BuildContext context) {
    final scoreColor = offer.matchScore >= 75
        ? AppColorsLight.success
        : offer.matchScore >= 50
            ? AppColorsLight.warning
            : AppColorsLight.error;

    final gradientIndex = offer.offerId.hashCode % _avatarGradients.length;
    final gradient = _avatarGradients[gradientIndex.abs()];
    final isHighMatch = offer.matchScore >= 75;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColorsLight.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isHighMatch
              ? AppColorsLight.success.withOpacity(0.4)
              : AppColorsLight.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColorsLight.bgCard,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd + 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: UserAvatar(
                  imageUrl: offer.companyLogo,
                  radius: 21,
                  defaultIcon: Icons.business_rounded,
                  gradientColors: gradient,
                  iconColor: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.title,
                      style: AppTypography.headingSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${offer.companyName} • ${offer.location}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColorsLight.textPrimary.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColorsLight.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  formatType(offer.offerType),
                  style: AppTypography.caption.copyWith(
                    color: AppColorsLight.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (offer.matchScore > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    border: Border.all(color: scoreColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 12, color: scoreColor),
                      const SizedBox(width: 4),
                      Text(
                        '${offer.matchScore}%',
                        style: AppTypography.caption.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
"""

content = content + search_offer_card_class

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Search page updated.")
