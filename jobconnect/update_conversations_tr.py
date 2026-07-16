import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\messaging\conversations_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update Search Bar
search_pattern = r"// Barre de recherche\s*Container\(\s*height: 48,[\s\S]*?onChanged: \(val\) => _cubit\.setSearchQuery\(val\),\s*\),\s*\),"
search_replacement = """// Barre de recherche
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(width: AppSpacing.md),
                                  Icon(
                                    Icons.search_rounded,
                                    color: _searchController.text.isNotEmpty ? Colors.white : Colors.white.withOpacity(0.8),
                                    size: 22,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style: AppTypography.bodyLarge.copyWith(color: Colors.white),
                                      cursorColor: Colors.white,
                                      decoration: InputDecoration(
                                        hintText: 'messaging.search_hint'.tr(),
                                        hintStyle: AppTypography.bodyLarge.copyWith(color: Colors.white.withOpacity(0.7)),
                                        border: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        disabledBorder: InputBorder.none,
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onChanged: (val) {
                                        setState(() {});
                                        _cubit.setSearchQuery(val);
                                      },
                                    ),
                                  ),
                                  if (_searchController.text.isNotEmpty)
                                    IconButton(
                                      icon: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _cubit.setSearchQuery('');
                                        setState(() {});
                                      },
                                    ),
                                ],
                              ),
                            ),"""
content = re.sub(search_pattern, search_replacement, content)


# 2. Update filters texts
content = content.replace("_buildChip('Toutes'", "_buildChip('messaging.filters.all'.tr()")
content = content.replace("_buildChip('Non-lues'", "_buildChip('messaging.filters.unread'.tr()")
content = content.replace("_buildChip('Lues'", "_buildChip('messaging.filters.read'.tr()")

# 3. Update snacbar texts
content = content.replace(
    "isArchived ? 'Conversation restaurée' : 'Conversation archivée'",
    "isArchived ? 'messaging.restored_success'.tr() : 'messaging.archived_success'.tr()"
)

# 4. Update empty state texts
content = content.replace(
    "isArchived ? 'Aucune archive' : 'messaging.empty.title'.tr()",
    "isArchived ? 'messaging.empty.archived_title'.tr() : 'messaging.empty.title'.tr()"
)
content = content.replace(
    "isArchived ? 'Vous n\\'avez aucune conversation archivée.' : 'messaging.empty.subtitle'.tr()",
    "isArchived ? 'messaging.empty.archived_subtitle'.tr() : 'messaging.empty.subtitle'.tr()"
)

# 5. Update error state texts
content = content.replace("'Erreur'", "'messaging.error.title'.tr()")
content = content.replace("const Text('Réessayer')", "Text('messaging.error.retry'.tr())")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated Translations and SearchBar")
