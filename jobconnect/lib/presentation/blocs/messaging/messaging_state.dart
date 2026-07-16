import 'package:equatable/equatable.dart';

class ConversationItem extends Equatable {
  final String conversationId;
  final String otherPartyName;
  final String otherPartySubtitle;
  final String? otherPartyPhotoUrl;
  final String lastMessage;
  final String lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  const ConversationItem({
    required this.conversationId,
    required this.otherPartyName,
    required this.otherPartySubtitle,
    this.otherPartyPhotoUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
  });

  @override
  List<Object?> get props => [
        conversationId,
        otherPartyName,
        otherPartySubtitle,
        otherPartyPhotoUrl,
        lastMessage,
        lastMessageAt,
        unreadCount,
        isOnline,
      ];
}

class MessageItem extends Equatable {
  final String messageId;
  final String content;
  final bool isMe;
  final String createdAt;
  final DateTime rawCreatedAt;
  final bool isRead;
  final bool isEdited;
  final bool isDeleted;

  const MessageItem({
    required this.messageId,
    required this.content,
    required this.isMe,
    required this.createdAt,
    required this.rawCreatedAt,
    this.isRead = false,
    this.isEdited = false,
    this.isDeleted = false,
  });

  MessageItem copyWith({
    String? content,
    bool? isRead,
    bool? isEdited,
    bool? isDeleted,
  }) {
    return MessageItem(
      messageId: messageId,
      content: content ?? this.content,
      isMe: isMe,
      createdAt: createdAt,
      rawCreatedAt: rawCreatedAt,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [messageId, content, isMe, createdAt, rawCreatedAt, isRead, isEdited, isDeleted];
}

// ─── États ────────────────────────────────────────────────────────────────────

abstract class MessagingState extends Equatable {
  const MessagingState();

  @override
  List<Object?> get props => [];
}

class MessagingInitial extends MessagingState {
  const MessagingInitial();
}

class ConversationsLoading extends MessagingState {
  const ConversationsLoading();
}

class ConversationsLoaded extends MessagingState {
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
}

class ConversationsError extends MessagingState {
  final String message;
  const ConversationsError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatLoading extends MessagingState {
  const ChatLoading();
}

class ChatLoaded extends MessagingState {
  final String conversationId;
  final String otherPartyName;
  final String otherPartySubtitle;
  final String? otherPartyPhotoUrl;
  final List<MessageItem> messages;
  final List<String> suggestions;
  final bool showSuggestions;
  final bool isSending;
  final bool isStudent;

  const ChatLoaded({
    required this.conversationId,
    required this.otherPartyName,
    required this.otherPartySubtitle,
    this.otherPartyPhotoUrl,
    required this.messages,
    this.suggestions = const [],
    this.showSuggestions = true,
    this.isSending = false,
    this.isStudent = false,
  });

  ChatLoaded copyWith({
    List<MessageItem>? messages,
    List<String>? suggestions,
    bool? showSuggestions,
    bool? isSending,
  }) {
    return ChatLoaded(
      conversationId: conversationId,
      otherPartyName: otherPartyName,
      otherPartySubtitle: otherPartySubtitle,
      otherPartyPhotoUrl: otherPartyPhotoUrl,
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      isSending: isSending ?? this.isSending,
      isStudent: isStudent,
    );
  }

  @override
  List<Object?> get props => [
        conversationId,
        otherPartyName,
        otherPartySubtitle,
        otherPartyPhotoUrl,
        messages,
        suggestions,
        showSuggestions,
        isSending,
        isStudent,
      ];
}

class ChatError extends MessagingState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}