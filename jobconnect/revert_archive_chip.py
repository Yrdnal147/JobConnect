import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\messaging\conversations_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add back the archive IconButton to the header
header_pattern = r"Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceBetween,\s*children: \[\s*Text\(\s*'messaging\.title'\.tr\(\),\s*style: AppTypography\.displayMedium\.copyWith\(color: Colors\.white, fontSize: 26\),\s*\),\s*\],"
header_replacement = """Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'messaging.title'.tr(),
                                  style: AppTypography.displayMedium.copyWith(color: Colors.white, fontSize: 26),
                                ),
                                if (state is ConversationsLoaded)
                                  IconButton(
                                    icon: Icon(
                                      state.filterType == 'archived' ? Icons.unarchive_rounded : Icons.archive_outlined,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    tooltip: state.filterType == 'archived' ? 'Voir les messages' : 'Voir les archives',
                                    onPressed: () => _cubit.setFilterType(
                                      state.filterType == 'archived' ? 'all' : 'archived', 
                                      isStudent: true
                                    ),
                                  ),
                              ],"""
content = re.sub(header_pattern, header_replacement, content)


# 2. Remove the "Archivées" chip from _buildFilterChips
chip_pattern = r"const SizedBox\(width: AppSpacing\.sm\),\s*_buildChip\('Archivées', 'archived', currentFilter == 'archived'\),"
content = re.sub(chip_pattern, "", content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated ConversationsPage for Archive Icon")
