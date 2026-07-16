import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\messaging\conversations_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildConversationTile signature and body to add Dismissible
tile_pattern = r"Widget _buildConversationTile\([\s\S]*?final hasUnread = conv\.unreadCount > 0;"
new_tile_start = """Widget _buildConversationTile(
      BuildContext context, ConversationItem conv) {
    final hasUnread = conv.unreadCount > 0;

    return Dismissible(
      key: Key(conv.conversationId),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _cubit.archiveConversation(conv.conversationId, true); // true = isStudent
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messaging.conversation_archived'.tr(fallback: 'Conversation archivée')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColorsLight.bgDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColorsLight.textTertiary.withOpacity(0.2), // Couleur d'archive douce
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: const Icon(Icons.archive_rounded, color: Colors.white, size: 32),
      ),
      child: Container("""

content = re.sub(tile_pattern, new_tile_start, content)

# I also need to close the Dismissible at the end of the method.
# In the previous replace, I opened a `return Dismissible(... child: Container(`.
# At the end of `_buildConversationTile`, it was `    );\n  }` for the Container.
# I need to add one more parenthesis.
# Let's just find the end of the method:
end_pattern = r"                      \),\n                    \],\n                  \),\n                \),\n              \],\n            \),\n          \),\n        \),\n      \),\n    \);\n  }"
end_replacement = r"""                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }"""
content = re.sub(end_pattern, end_replacement, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated ConversationsPage with Dismissible.")
