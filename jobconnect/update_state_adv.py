import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\blocs\messaging\messaging_state.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

pattern = r"class ConversationsLoaded extends MessagingState \{[\s\S]*?\n\}"
replacement = """class ConversationsLoaded extends MessagingState {
  final List<ConversationItem> conversations;
  final String filterType; // 'all', 'unread', 'archived'
  final String searchQuery;
  final bool hasReachedMax;
  final int currentPage;
  final bool isLoadingMore;

  const ConversationsLoaded({
    required this.conversations,
    this.filterType = 'all',
    this.searchQuery = '',
    this.hasReachedMax = false,
    this.currentPage = 0,
    this.isLoadingMore = false,
  });

  ConversationsLoaded copyWith({
    List<ConversationItem>? conversations,
    String? filterType,
    String? searchQuery,
    bool? hasReachedMax,
    int? currentPage,
    bool? isLoadingMore,
  }) {
    return ConversationsLoaded(
      conversations: conversations ?? this.conversations,
      filterType: filterType ?? this.filterType,
      searchQuery: searchQuery ?? this.searchQuery,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        filterType,
        searchQuery,
        hasReachedMax,
        currentPage,
        isLoadingMore,
      ];
}"""
content = re.sub(pattern, replacement, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated ConversationsLoaded state.")
