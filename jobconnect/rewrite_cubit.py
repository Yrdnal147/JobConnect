import os

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\blocs\messaging\messaging_cubit.dart"

new_content = """import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/datasources/mastra_remote_datasource.dart';
import 'messaging_state.dart';

class MessagingCubit extends Cubit<MessagingState> {
  final SupabaseClient _client;
  final IMastraRemoteDataSource? _mastraDataSource;
  RealtimeChannel? _messageChannel;

  // Pagination & Filtering Cache
  static const int _limit = 15;
  List<ConversationItem> _cachedConversations = [];
  bool _hasReachedMax = false;
  int _currentPage = 0;
  String _currentFilter = 'all'; // 'all', 'unread', 'archived'
  String _currentSearch = '';

  MessagingCubit({
    SupabaseClient? client,
    IMastraRemoteDataSource? mastraDataSource,
  })  : _client = client ?? Supabase.instance.client,
        _mastraDataSource = mastraDataSource,
        super(const MessagingInitial());

  // ─── Filtres et Recherche ──────────────────────────────────────────────────

  Future<void> setFilterType(String type, {bool isStudent = false}) async {
    if (_currentFilter == type) return;
    _currentFilter = type;
    
    // Si on passe aux archives (ou qu'on en sort), on doit recharger depuis la DB 
    // car la requête SQL de base filtre sur is_archived_by_...
    if (type == 'archived' || state is ConversationsLoaded && (state as ConversationsLoaded).filterType == 'archived') {
      if (isStudent) {
        await loadStudentConversations(loadMore: false);
      } else {
        await loadConversations(loadMore: false);
      }
    } else {
      // Filtrage local (ex: 'all' -> 'unread')
      _emitFilteredState();
    }
  }

  void setSearchQuery(String query) {
    _currentSearch = query.trim().toLowerCase();
    _emitFilteredState();
  }

  void _emitFilteredState() {
    if (state is! ConversationsLoaded && state is! ConversationsLoading) return;
    
    List<ConversationItem> filtered = List.from(_cachedConversations);

    // Filtre 'unread' (local)
    if (_currentFilter == 'unread') {
      filtered = filtered.where((c) => c.unreadCount > 0).toList();
    }

    // Filtre de recherche
    if (_currentSearch.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.otherPartyName.toLowerCase().contains(_currentSearch) ||
               c.otherPartySubtitle.toLowerCase().contains(_currentSearch) ||
               c.lastMessage.toLowerCase().contains(_currentSearch);
      }).toList();
    }

    emit(ConversationsLoaded(
      conversations: filtered,
      filterType: _currentFilter,
      searchQuery: _currentSearch,
      hasReachedMax: _hasReachedMax,
      currentPage: _currentPage,
      isLoadingMore: false,
    ));
  }

  // ─── Conversations recruteur ──────────────────────────────────────────────

  Future<void> loadConversations({bool loadMore = false}) async {
    if (loadMore && _hasReachedMax) return;

    if (!loadMore) {
      _currentPage = 0;
      _hasReachedMax = false;
      _cachedConversations = [];
      emit(const ConversationsLoading());
    } else {
      if (state is ConversationsLoaded) {
        emit((state as ConversationsLoaded).copyWith(isLoadingMore: true));
      }
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const ConversationsError('Utilisateur non connecté'));
        return;
      }

      final companyRow = await _client
          .from('companies')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (companyRow == null) {
        _hasReachedMax = true;
        _emitFilteredState();
        return;
      }

      final companyId = companyRow['id'] as String;
      final start = _currentPage * _limit;
      final end = start + _limit - 1;
      
      final bool isArchivedQuery = _currentFilter == 'archived';

      final convsRes = await _client
          .from('conversations')
          .select('id, last_message, last_message_at, student_id, application_id')
          .eq('company_id', companyId)
          .eq('is_archived_by_company', isArchivedQuery)
          .order('last_message_at', ascending: false)
          .range(start, end);

      final convs = convsRes as List;

      if (convs.isEmpty) {
        _hasReachedMax = true;
        _emitFilteredState();
        return;
      }

      if (convs.length < _limit) {
        _hasReachedMax = true;
      } else {
        _currentPage++;
      }

      final List<ConversationItem> newConversations = [];

      for (final conv in convs) {
        try {
          final studentId = conv['student_id'] as String;
          final applicationId = conv['application_id'] as String?;

          final profileRes = await _client
              .from('student_profiles')
              .select('full_name, field_of_study, photo_url')
              .eq('id', studentId)
              .maybeSingle();

          int unreadCount = 0;
          try {
            final unreadRes = await _client
                .from('messages')
                .select('id')
                .eq('conversation_id', conv['id'] as String)
                .eq('is_read', false)
                .neq('sender_id', user.id);
            unreadCount = (unreadRes as List).length;
          } catch (_) {}
          
          String offerTitle = '';
          if (applicationId != null) {
            try {
              final appRes = await _client
                  .from('applications')
                  .select('offers(title)')
                  .eq('id', applicationId)
                  .maybeSingle();
              if (appRes != null && appRes['offers'] != null) {
                offerTitle = (appRes['offers'] as Map)['title'] as String? ?? '';
              }
            } catch (_) {}
          }

          if (profileRes != null) {
            newConversations.add(ConversationItem(
              conversationId: conv['id'] as String,
              otherPartyName: profileRes['full_name'] as String? ?? 'Étudiant',
              otherPartySubtitle: offerTitle.isNotEmpty ? offerTitle : (profileRes['field_of_study'] as String? ?? ''),
              otherPartyPhotoUrl: profileRes['photo_url'] as String?,
              lastMessage: conv['last_message'] as String? ?? '',
              lastMessageAt: _formatTime(conv['last_message_at'] as String?),
              unreadCount: unreadCount,
            ));
          }
        } catch (_) {
          continue;
        }
      }

      _cachedConversations.addAll(newConversations);
      _emitFilteredState();
    } catch (e) {
      if (!loadMore) emit(ConversationsError(e.toString()));
    }
  }

  // ─── Conversations candidat ───────────────────────────────────────────────

  Future<void> loadStudentConversations({bool loadMore = false}) async {
    if (loadMore && _hasReachedMax) return;

    if (!loadMore) {
      _currentPage = 0;
      _hasReachedMax = false;
      _cachedConversations = [];
      emit(const ConversationsLoading());
    } else {
      if (state is ConversationsLoaded) {
        emit((state as ConversationsLoaded).copyWith(isLoadingMore: true));
      }
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const ConversationsError('Utilisateur non connecté'));
        return;
      }

      final studentRow = await _client
          .from('student_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (studentRow == null) {
        _hasReachedMax = true;
        _emitFilteredState();
        return;
      }

      final studentId = studentRow['id'] as String;
      final start = _currentPage * _limit;
      final end = start + _limit - 1;

      final bool isArchivedQuery = _currentFilter == 'archived';

      final convsRes = await _client
          .from('conversations')
          .select('id, last_message, last_message_at, company_id, application_id')
          .eq('student_id', studentId)
          .eq('is_archived_by_student', isArchivedQuery)
          .order('last_message_at', ascending: false)
          .range(start, end);

      final convs = convsRes as List;

      if (convs.isEmpty) {
        _hasReachedMax = true;
        _emitFilteredState();
        return;
      }
      
      if (convs.length < _limit) {
        _hasReachedMax = true;
      } else {
        _currentPage++;
      }

      final List<ConversationItem> newConversations = [];

      for (final conv in convs) {
        try {
          final companyId = conv['company_id'] as String;
          final applicationId = conv['application_id'] as String?;

          final companyRes = await _client
              .from('companies')
              .select('name, sector, logo_url')
              .eq('id', companyId)
              .maybeSingle();

          int unreadCount = 0;
          try {
            final unreadRes = await _client
                .from('messages')
                .select('id')
                .eq('conversation_id', conv['id'] as String)
                .eq('is_read', false)
                .neq('sender_id', user.id);
            unreadCount = (unreadRes as List).length;
          } catch (_) {}
          
          String offerTitle = '';
          if (applicationId != null) {
            try {
              final appRes = await _client
                  .from('applications')
                  .select('offers(title)')
                  .eq('id', applicationId)
                  .maybeSingle();
              if (appRes != null && appRes['offers'] != null) {
                offerTitle = (appRes['offers'] as Map)['title'] as String? ?? '';
              }
            } catch (_) {}
          }

          if (companyRes != null) {
            newConversations.add(ConversationItem(
              conversationId: conv['id'] as String,
              otherPartyName: companyRes['name'] as String? ?? 'Entreprise',
              otherPartySubtitle: offerTitle.isNotEmpty ? offerTitle : (companyRes['sector'] as String? ?? ''),
              otherPartyPhotoUrl: companyRes['logo_url'] as String?,
              lastMessage: conv['last_message'] as String? ?? '',
              lastMessageAt: _formatTime(conv['last_message_at'] as String?),
              unreadCount: unreadCount,
            ));
          }
        } catch (_) {
          continue;
        }
      }

      _cachedConversations.addAll(newConversations);
      _emitFilteredState();
    } catch (e) {
      if (!loadMore) emit(ConversationsError(e.toString()));
    }
  }

  // ─── Archive & Unarchive ──────────────────────────────────────────────────

  Future<void> archiveConversation(String conversationId, bool isStudent) async {
    _cachedConversations.removeWhere((c) => c.conversationId == conversationId);
    _emitFilteredState();

    try {
      final column = isStudent ? 'is_archived_by_student' : 'is_archived_by_company';
      await _client
          .from('conversations')
          .update({column: true})
          .eq('id', conversationId);
    } catch (e) {
      if (isStudent) {
        loadStudentConversations();
      } else {
        loadConversations();
      }
    }
  }

  Future<void> unarchiveConversation(String conversationId, bool isStudent) async {
    _cachedConversations.removeWhere((c) => c.conversationId == conversationId);
    _emitFilteredState();

    try {
      final column = isStudent ? 'is_archived_by_student' : 'is_archived_by_company';
      await _client
          .from('conversations')
          .update({column: false})
          .eq('id', conversationId);
    } catch (e) {
      if (isStudent) {
        loadStudentConversations();
      } else {
        loadConversations();
      }
    }
  }

  // ─── Chat (commun) ────────────────────────────────────────────────────────
  
  Future<void> openChat(String conversationId, {bool isStudent = false}) async {
    emit(const ChatLoading());
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const ChatError('Utilisateur non connecté'));
        return;
      }

      final convRes = await _client
          .from('conversations')
          .select('student_id, company_id, application_id')
          .eq('id', conversationId)
          .maybeSingle();

      if (convRes == null) {
        emit(const ChatError('Conversation introuvable'));
        return;
      }

      final applicationId = convRes['application_id'] as String?;
      String offerTitle = '';
      if (applicationId != null) {
          try {
            final appRes = await _client
                .from('applications')
                .select('offers(title)')
                .eq('id', applicationId)
                .maybeSingle();
            if (appRes != null && appRes['offers'] != null) {
              offerTitle = (appRes['offers'] as Map)['title'] as String? ?? '';
            }
          } catch (_) {}
      }

      String otherPartyName;
      String otherPartySubtitle;
      String? otherPartyPhotoUrl;

      if (isStudent) {
        final companyId = convRes['company_id'] as String;
        final companyRes = await _client
            .from('companies')
            .select('name, sector, logo_url')
            .eq('id', companyId)
            .maybeSingle();
        otherPartyName     = companyRes?['name'] as String? ?? 'Entreprise';
        otherPartySubtitle = offerTitle.isNotEmpty ? offerTitle : (companyRes?['sector'] as String? ?? '');
        otherPartyPhotoUrl = companyRes?['logo_url'] as String?;
      } else {
        final studentId = convRes['student_id'] as String;
        final profileRes = await _client
            .from('student_profiles')
            .select('full_name, field_of_study, photo_url')
            .eq('id', studentId)
            .maybeSingle();
        otherPartyName     = profileRes?['full_name'] as String? ?? 'Étudiant';
        otherPartySubtitle = offerTitle.isNotEmpty ? offerTitle : (profileRes?['field_of_study'] as String? ?? '');
        otherPartyPhotoUrl = profileRes?['photo_url'] as String?;
      }

      final messagesRes = await _client
          .from('messages')
          .select('id, content, sender_id, created_at, is_read')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final messages = (messagesRes as List).map((msg) {
        return MessageItem(
          messageId: msg['id'] as String,
          content: msg['content'] as String,
          isMe: msg['sender_id'] == user.id,
          createdAt: _formatTime(msg['created_at'] as String?),
          isRead: msg['is_read'] as bool? ?? false,
        );
      }).toList();

      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', user.id);

      final suggestions = isStudent
          ? ['Merci !', 'Je suis disponible.', 'Bien reçu.']
          : ['Merci.', 'Êtes-vous disponible ?', 'Bien reçu.'];

      emit(ChatLoaded(
        conversationId: conversationId,
        otherPartyName: otherPartyName,
        otherPartySubtitle: otherPartySubtitle,
        otherPartyPhotoUrl: otherPartyPhotoUrl,
        messages: messages,
        suggestions: suggestions,
        showSuggestions: messages.isNotEmpty,
        isStudent: isStudent,
      ));

      _subscribeToMessages(conversationId, user.id);
      
      if (messages.isNotEmpty && !messages.last.isMe) {
        _fetchAISuggestions(conversationId, messages.last.content, user.id);
      }
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _subscribeToMessages(String conversationId, String currentUserId) {
    _messageChannel?.unsubscribe();
    _messageChannel = _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'conversation_id', value: conversationId),
          callback: (payload) {
            final current = state;
            if (current is! ChatLoaded) return;
            final newMsg = payload.newRecord;
            final message = MessageItem(
              messageId: newMsg['id'] as String,
              content: newMsg['content'] as String,
              isMe: newMsg['sender_id'] == currentUserId,
              createdAt: _formatTime(newMsg['created_at'] as String?),
              isRead: false,
            );
            if (!message.isMe) {
              _client.from('messages').update({'is_read': true}).eq('id', message.messageId).then((_) {});
              _fetchAISuggestions(conversationId, message.content, currentUserId);
            }
            emit(current.copyWith(messages: [...current.messages, message], showSuggestions: !message.isMe));
          },
        ).subscribe();
  }

  Future<void> sendMessage(String content) async {
    final current = state;
    if (current is! ChatLoaded) return;
    if (content.trim().isEmpty) return;
    final user = _client.auth.currentUser;
    if (user == null) return;
    emit(current.copyWith(isSending: true, showSuggestions: false));

    try {
      final inserted = await _client.from('messages').insert({
        'conversation_id': current.conversationId,
        'sender_id': user.id,
        'content': content.trim(),
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      await _client.from('conversations').update({
        'last_message': content.trim(),
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', current.conversationId);

      final newMessage = MessageItem(
        messageId: inserted['id'] as String,
        content: content.trim(),
        isMe: true,
        createdAt: _formatTime(inserted['created_at'] as String?),
        isRead: false,
      );

      emit(current.copyWith(messages: [...current.messages, newMessage], isSending: false, showSuggestions: false));
    } catch (e) {
      emit(current.copyWith(isSending: false));
    }
  }

  Future<void> closeChat({bool isStudent = false}) async {
    await _messageChannel?.unsubscribe();
    _messageChannel = null;
    if (isStudent) {
      await loadStudentConversations(loadMore: false);
    } else {
      await loadConversations(loadMore: false);
    }
  }

  Future<void> _fetchAISuggestions(String conversationId, String content, String senderId) async {
    final current = state;
    if (current is! ChatLoaded) return;
    if (_mastraDataSource == null) return;
    try {
      final senderRole = current.isStudent ? 'company' : 'student';
      final prompt = '''
Génère 3 suggestions de réponse courtes pour ce message.
conversationId: $conversationId
userId de l'expéditeur: $senderId
role de l'expéditeur: $senderRole
Dernier message : "$content"
Réponds STRICTEMENT en format JSON valide contenant une clé "suggestions" qui est une liste d'objets avec "tone" et "message".
''';
      final response = await _mastraDataSource.executeAgent(ApiEndpoints.messageAssistant, prompt);
      final text = response['text'] as String?;
      if (text != null) {
        final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
        if (match != null) {
          final decoded = jsonDecode(match.group(0)!);
          if (decoded['suggestions'] != null) {
            final List<dynamic> suggs = decoded['suggestions'];
            final List<String> stringSuggestions = suggs.map((s) => s['message'].toString()).toList();
            if (state is ChatLoaded && (state as ChatLoaded).conversationId == conversationId) {
              emit((state as ChatLoaded).copyWith(suggestions: stringSuggestions, showSuggestions: true));
            }
          }
        }
      }
    } catch (_) {}
  }

  String _formatTime(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final now  = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      if (diff.inDays == 1) return 'Hier';
      if (diff.inDays < 7) {
        const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return days[date.weekday - 1];
      }
      return '${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Future<void> close() async {
    await _messageChannel?.unsubscribe();
    return super.close();
  }
}
"""

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(new_content)
print("Rewrote MessagingCubit")
