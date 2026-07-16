import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\messaging\conversations_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update the Header to add the toggle button
header_pattern = r"(Row\(\s*mainAxisAlignment: MainAxisAlignment\.spaceBetween,\s*children: \[\s*Text\([\s\S]*?if \(state is ConversationsLoaded &&\s*state\.conversations\.isNotEmpty\)\s*Container\([\s\S]*?\),\s*\])"
def header_replacement(match):
    original = match.group(0)
    # We add an IconButton at the end of the Row
    return original[:-1] + """
                                  if (state is ConversationsLoaded)
                                    IconButton(
                                      icon: Icon(
                                        state.isShowingArchived ? Icons.unarchive_rounded : Icons.archive_outlined,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                      tooltip: state.isShowingArchived ? 'Voir les messages' : 'Voir les archives',
                                      onPressed: () => _cubit.toggleArchiveView(true), // true = isStudent
                                    ),
                                ]"""
content = re.sub(header_pattern, header_replacement, content)

# 2. Update _buildBody to pass isShowingArchived
build_body_pattern = r"Widget _buildBody\(BuildContext context, MessagingState state\) \{[\s\S]*?_buildConversationTile\(context, conv\);"
def build_body_replacement(match):
    return match.group(0).replace("_buildConversationTile(context, conv);", "_buildConversationTile(context, conv, state.isShowingArchived);")
content = re.sub(build_body_pattern, build_body_replacement, content)

# Update _buildEmptyState call to pass isShowingArchived
empty_state_call = r"return _buildEmptyState\(\);"
content = re.sub(empty_state_call, "return _buildEmptyState((state as ConversationsLoaded).isShowingArchived);", content)

# 3. Update _buildEmptyState signature and text
empty_state_def = r"Widget _buildEmptyState\(\) \{"
content = re.sub(empty_state_def, "Widget _buildEmptyState(bool isArchived) {", content)

empty_title_pattern = r"'messaging\.empty\.title'\.tr\(\)"
content = re.sub(empty_title_pattern, "isArchived ? 'Aucune archive' : 'messaging.empty.title'.tr()", content)

empty_subtitle_pattern = r"'messaging\.empty\.subtitle'\.tr\(\)"
content = re.sub(empty_subtitle_pattern, "isArchived ? 'Vous n\\'avez aucune conversation archivée pour le moment.' : 'messaging.empty.subtitle'.tr()", content)

# 4. Update _buildConversationTile
tile_pattern = r"Widget _buildConversationTile\(\s*BuildContext context, ConversationItem conv\) \{"
content = re.sub(tile_pattern, "Widget _buildConversationTile(BuildContext context, ConversationItem conv, bool isArchived) {", content)

dismissible_pattern = r"onDismissed: \(direction\) \{[\s\S]*?\},"
dismissible_replacement = """onDismissed: (direction) {
        if (isArchived) {
          _cubit.unarchiveConversation(conv.conversationId, true);
        } else {
          _cubit.archiveConversation(conv.conversationId, true);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArchived ? 'Conversation restaurée' : 'Conversation archivée'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColorsLight.bgDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },"""
content = re.sub(dismissible_pattern, dismissible_replacement, content)

background_pattern = r"background: Container\([\s\S]*?child: const Icon\(Icons\.archive_rounded, color: Colors\.white, size: 32\),\s*\),"
background_replacement = """background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: isArchived ? AppColorsLight.success.withOpacity(0.8) : AppColorsLight.error.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Icon(isArchived ? Icons.unarchive_rounded : Icons.archive_rounded, color: Colors.white, size: 32),
      ),"""
content = re.sub(background_pattern, background_replacement, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated ConversationsPage for unarchive")
