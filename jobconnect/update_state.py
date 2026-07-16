import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\blocs\messaging\messaging_state.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Update ConversationsLoaded
pattern = r"class ConversationsLoaded extends MessagingState \{\s*final List<ConversationItem> conversations;\s*const ConversationsLoaded\(\{required this\.conversations\}\);\s*@override\s*List<Object\?> get props => \[conversations\];\s*\}"
replacement = """class ConversationsLoaded extends MessagingState {
  final List<ConversationItem> conversations;
  final bool isShowingArchived;

  const ConversationsLoaded({
    required this.conversations,
    this.isShowingArchived = false,
  });

  @override
  List<Object?> get props => [conversations, isShowingArchived];
}"""

content = re.sub(pattern, replacement, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated MessagingState")
