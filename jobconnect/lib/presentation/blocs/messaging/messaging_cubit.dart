import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../data/datasources/mastra_remote_datasource.dart';
import 'messaging_state.dart';

class MessagingCubit extends Cubit<MessagingState> {
  final SupabaseClient _client;
  final IMastraRemoteDataSource? _mastraDataSource;
  RealtimeChannel? _messageChannel;

  List<ConversationItem> _allConversations = [];
  final Set<String> _archivedConversations = {};

  MessagingCubit({
    SupabaseClient? client,
    IMastraRemoteDataSource? mastraDataSource,
  }) : _client = client ?? Supabase.instance.client,
       _mastraDataSource = mastraDataSource,
       super(const MessagingInitial());

  // ─── Conversations recruteur ──────────────────────────────────────────────

  Future<void> loadConversations({bool loadMore = false}) async {
    String filterType = 'all';
    String searchQuery = '';
    if (state is ConversationsLoaded) {
      filterType = (state as ConversationsLoaded).filterType;
      searchQuery = (state as ConversationsLoaded).searchQuery;
    } else {
      emit(const ConversationsLoading());
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
        emit(const ConversationsLoaded(conversations: []));
        return;
      }

      final companyId = companyRow['id'] as String;

      final convsRes = await _client
          .from('conversations')
          .select(
            'id, last_message, last_message_at, student_id, application_id',
          )
          .eq('company_id', companyId)
          .order('last_message_at', ascending: false);

      final convs = convsRes as List;

      if (convs.isEmpty) {
        emit(const ConversationsLoaded(conversations: []));
        return;
      }

      final List<ConversationItem> conversations = [];

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
                offerTitle =
                    (appRes['offers'] as Map)['title'] as String? ?? '';
              }
            } catch (_) {}
          }

          if (profileRes != null) {
            conversations.add(
              ConversationItem(
                conversationId: conv['id'] as String,
                otherPartyName:
                    profileRes['full_name'] as String? ?? 'Étudiant',
                otherPartySubtitle: offerTitle.isNotEmpty
                    ? offerTitle
                    : (profileRes['field_of_study'] as String? ?? ''),
                otherPartyPhotoUrl: profileRes['photo_url'] as String?,
                lastMessage: conv['last_message'] as String? ?? '',
                lastMessageAt: _formatTime(conv['last_message_at'] as String?),
                unreadCount: unreadCount,
              ),
            );
          }
        } catch (_) {
          continue;
        }
      }

      if (isClosed) return;
      _allConversations = conversations;
      emit(
        ConversationsLoaded(
          conversations: _applyFilters(
            _allConversations,
            filterType,
            searchQuery,
          ),
          filterType: filterType,
          searchQuery: searchQuery,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(ConversationsError(e.toString()));
    }
  }

  // ─── Conversations candidat ───────────────────────────────────────────────

  Future<void> loadStudentConversations({bool loadMore = false}) async {
    String filterType = 'all';
    String searchQuery = '';
    if (state is ConversationsLoaded) {
      filterType = (state as ConversationsLoaded).filterType;
      searchQuery = (state as ConversationsLoaded).searchQuery;
    } else {
      emit(const ConversationsLoading());
    }

    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        emit(const ConversationsError('Utilisateur non connecté'));
        return;
      }

      // Récupère le profil étudiant
      final studentRow = await _client
          .from('student_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (studentRow == null) {
        emit(const ConversationsLoaded(conversations: []));
        return;
      }

      final studentId = studentRow['id'] as String;

      final convsRes = await _client
          .from('conversations')
          .select(
            'id, last_message, last_message_at, company_id, application_id',
          )
          .eq('student_id', studentId)
          .order('last_message_at', ascending: false);

      final convs = convsRes as List;

      if (convs.isEmpty) {
        emit(const ConversationsLoaded(conversations: []));
        return;
      }

      final List<ConversationItem> conversations = [];

      for (final conv in convs) {
        try {
          final companyId = conv['company_id'] as String;
          final applicationId = conv['application_id'] as String?;

          // Infos entreprise
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
                offerTitle =
                    (appRes['offers'] as Map)['title'] as String? ?? '';
              }
            } catch (_) {}
          }

          if (companyRes != null) {
            conversations.add(
              ConversationItem(
                conversationId: conv['id'] as String,
                otherPartyName: companyRes['name'] as String? ?? 'Entreprise',
                otherPartySubtitle: offerTitle.isNotEmpty
                    ? offerTitle
                    : (companyRes['sector'] as String? ?? ''),
                otherPartyPhotoUrl: companyRes['logo_url'] as String?,
                lastMessage: conv['last_message'] as String? ?? '',
                lastMessageAt: _formatTime(conv['last_message_at'] as String?),
                unreadCount: unreadCount,
              ),
            );
          }
        } catch (_) {
          continue;
        }
      }

      if (isClosed) return;
      _allConversations = conversations;
      emit(
        ConversationsLoaded(
          conversations: _applyFilters(
            _allConversations,
            filterType,
            searchQuery,
          ),
          filterType: filterType,
          searchQuery: searchQuery,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(ConversationsError(e.toString()));
    }
  }

  // ─── Chat (commun recruteur + candidat) ──────────────────────────────────

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
      List<String> jobDetails = [];

      if (applicationId != null) {
        try {
          final appRes = await _client
              .from('applications')
              .select('offers(title, offer_type, location, salary_range, description, required_skills)')
              .eq('id', applicationId)
              .maybeSingle();
          if (appRes != null && appRes['offers'] != null) {
            final offerMap = appRes['offers'] as Map;
            offerTitle = offerMap['title'] as String? ?? '';
            
            if (offerTitle.isNotEmpty) {
              jobDetails.add("Poste : $offerTitle");
            }
            final offerType = offerMap['offer_type'] as String? ?? '';
            final location = offerMap['location'] as String? ?? '';
            if (offerType.isNotEmpty || location.isNotEmpty) {
              jobDetails.add([
                if (offerType.isNotEmpty) "Type : $offerType",
                if (location.isNotEmpty) "Lieu : $location",
              ].join(" - "));
            }
            final salary = offerMap['salary_range'] as String? ?? '';
            if (salary.isNotEmpty) {
              jobDetails.add("Salaire : $salary");
            }
            final skills = offerMap['required_skills'] as List? ?? [];
            if (skills.isNotEmpty) {
              final skillsStr = skills.map((s) => s.toString()).take(4).join(", ");
              jobDetails.add("Compétences : $skillsStr${skills.length > 4 ? '...' : ''}");
            }
            final description = offerMap['description'] as String? ?? '';
            if (description.isNotEmpty) {
              final shortDesc = description.length > 80 ? '${description.substring(0, 80).trim()}...' : description;
              jobDetails.add("Mission : $shortDesc");
            }
          }
        } catch (_) {}
      }

      String otherPartyName;
      String otherPartySubtitle;
      String? otherPartyPhotoUrl;

      if (isStudent) {
        // Candidat → affiche infos entreprise
        final companyId = convRes['company_id'] as String;
        final companyRes = await _client
            .from('companies')
            .select('name, sector, logo_url')
            .eq('id', companyId)
            .maybeSingle();

        otherPartyName = companyRes?['name'] as String? ?? 'Entreprise';
        otherPartySubtitle = offerTitle.isNotEmpty
            ? offerTitle
            : (companyRes?['sector'] as String? ?? '');
        otherPartyPhotoUrl = companyRes?['logo_url'] as String?;
      } else {
        // Recruteur → affiche infos étudiant
        final studentId = convRes['student_id'] as String;
        final profileRes = await _client
            .from('student_profiles')
            .select('full_name, field_of_study, photo_url')
            .eq('id', studentId)
            .maybeSingle();

        otherPartyName = profileRes?['full_name'] as String? ?? 'Étudiant';
        otherPartySubtitle = offerTitle.isNotEmpty
            ? offerTitle
            : (profileRes?['field_of_study'] as String? ?? '');
        otherPartyPhotoUrl = profileRes?['photo_url'] as String?;
      }

      // Messages
      final messagesRes = await _client
          .from('messages')
          .select(
            'id, content, sender_id, created_at, is_read, is_edited, is_deleted',
          )
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final messages = (messagesRes as List).map((msg) {
        return MessageItem(
          messageId: msg['id'] as String,
          content: msg['content'] as String,
          isMe: msg['sender_id'] == user.id,
          createdAt: _formatTime(msg['created_at'] as String?),
          rawCreatedAt: DateTime.parse(msg['created_at'] as String).toUtc(),
          isRead: msg['is_read'] as bool? ?? false,
          isEdited: msg['is_edited'] as bool? ?? false,
          isDeleted: msg['is_deleted'] as bool? ?? false,
        );
      }).toList();

      // Marque les messages comme lus
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', user.id);

      final suggestions = isStudent
          ? [
              'Merci pour votre message !',
              'Je suis disponible pour un entretien.',
              'Bien reçu, à bientôt.',
            ]
          : [
              'Merci, nous reviendrons vers vous rapidement.',
              'Êtes-vous disponible pour un entretien cette semaine ?',
              'Bien reçu, à bientôt.',
            ];

      if (isClosed) return;
      emit(
        ChatLoaded(
          conversationId: conversationId,
          otherPartyName: otherPartyName,
          otherPartySubtitle: otherPartySubtitle,
          otherPartyPhotoUrl: otherPartyPhotoUrl,
          messages: messages,
          suggestions: suggestions,
          showSuggestions: messages.isNotEmpty,
          isStudent: isStudent,
          jobDetails: jobDetails,
        ),
      );

      _subscribeToMessages(conversationId, user.id);

      // Fetch AI suggestions if the last message is not from me
      if (messages.isNotEmpty && !messages.last.isMe) {
        // Run asynchronously without awaiting to not block UI
        _fetchAISuggestions(conversationId, messages.last.content, user.id);
      }
    } catch (e) {
      if (isClosed) return;
      emit(ChatError(e.toString()));
    }
  }

  // ─── Realtime ─────────────────────────────────────────────────────────────

  void _subscribeToMessages(String conversationId, String currentUserId) {
    _messageChannel?.unsubscribe();

    _messageChannel = _client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final current = state;
            if (current is! ChatLoaded) return;

            final msgRecord = payload.eventType == PostgresChangeEvent.delete
                ? payload.oldRecord
                : payload.newRecord;

            final messageId = msgRecord['id'] as String;

            if (payload.eventType == PostgresChangeEvent.insert) {
              if (current.messages.any((m) => m.messageId == messageId))
                return; // Evite les doublons

              final message = MessageItem(
                messageId: messageId,
                content: msgRecord['content'] as String,
                isMe: msgRecord['sender_id'] == currentUserId,
                createdAt: _formatTime(msgRecord['created_at'] as String?),
                rawCreatedAt: DateTime.parse(
                  msgRecord['created_at'] as String,
                ).toUtc(),
                isRead: msgRecord['is_read'] as bool? ?? false,
                isEdited: msgRecord['is_edited'] as bool? ?? false,
                isDeleted: msgRecord['is_deleted'] as bool? ?? false,
              );

              if (!message.isMe) {
                _client
                    .from('messages')
                    .update({'is_read': true})
                    .eq('id', messageId)
                    .then((_) {});

                _fetchAISuggestions(
                  conversationId,
                  message.content,
                  currentUserId,
                );
              }

              emit(
                current.copyWith(
                  messages: [...current.messages, message],
                  showSuggestions: !message.isMe,
                ),
              );
            } else if (payload.eventType == PostgresChangeEvent.update) {
              final updatedMessages = current.messages.map((m) {
                if (m.messageId == messageId) {
                  return m.copyWith(
                    content: msgRecord['content'] as String,
                    isEdited: msgRecord['is_edited'] as bool? ?? false,
                    isDeleted: msgRecord['is_deleted'] as bool? ?? false,
                    isRead: msgRecord['is_read'] as bool? ?? false,
                  );
                }
                return m;
              }).toList();
              emit(current.copyWith(messages: updatedMessages));
            }
          },
        )
        .subscribe();
  }

  // ─── Envoi message ────────────────────────────────────────────────────────

  Future<void> sendMessage(String content) async {
    final current = state;
    if (current is! ChatLoaded) return;
    if (content.trim().isEmpty) return;

    final user = _client.auth.currentUser;
    if (user == null) return;

    emit(current.copyWith(isSending: true, showSuggestions: false));

    try {
      // Insère le message
      final inserted = await _client
          .from('messages')
          .insert({
            'conversation_id': current.conversationId,
            'sender_id': user.id,
            'content': content.trim(),
            'is_read': false,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      // Met à jour last_message
      await _client
          .from('conversations')
          .update({
            'last_message': content.trim(),
            'last_message_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', current.conversationId);

      final newMessage = MessageItem(
        messageId: inserted['id'] as String,
        content: content.trim(),
        isMe: true,
        createdAt: _formatTime(inserted['created_at'] as String?),
        rawCreatedAt: DateTime.parse(inserted['created_at'] as String).toUtc(),
        isRead: false,
        isEdited: false,
        isDeleted: false,
      );

      if (isClosed) return;
      emit(
        current.copyWith(
          messages: [...current.messages, newMessage],
          isSending: false,
          showSuggestions: false,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(current.copyWith(isSending: false));
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    final current = state;
    if (current is! ChatLoaded) return;

    try {
      final updatedMessages = current.messages.map((m) {
        if (m.messageId == messageId) {
          return m.copyWith(content: newContent, isEdited: true);
        }
        return m;
      }).toList();
      emit(current.copyWith(messages: updatedMessages));

      await _client
          .from('messages')
          .update({'content': newContent, 'is_edited': true})
          .eq('id', messageId);

      if (updatedMessages.isNotEmpty &&
          updatedMessages.last.messageId == messageId) {
        await _client
            .from('conversations')
            .update({'last_message': newContent})
            .eq('id', current.conversationId);
      }
    } catch (_) {}
  }

  Future<void> deleteMessage(String messageId) async {
    final current = state;
    if (current is! ChatLoaded) return;

    try {
      final deletedText = 'Ce message a été supprimé';
      final updatedMessages = current.messages.map((m) {
        if (m.messageId == messageId) {
          return m.copyWith(content: deletedText, isDeleted: true);
        }
        return m;
      }).toList();
      emit(current.copyWith(messages: updatedMessages));

      await _client
          .from('messages')
          .update({'content': deletedText, 'is_deleted': true})
          .eq('id', messageId);

      if (updatedMessages.isNotEmpty &&
          updatedMessages.last.messageId == messageId) {
        await _client
            .from('conversations')
            .update({'last_message': deletedText})
            .eq('id', current.conversationId);
      }
    } catch (_) {}
  }

  // ─── Fermeture ────────────────────────────────────────────────────────────

  Future<void> closeChat({bool isStudent = false}) async {
    await _messageChannel?.unsubscribe();
    _messageChannel = null;
    if (isStudent) {
      await loadStudentConversations();
    } else {
      await loadConversations();
    }
  }

  // ─── Helper ──────────────────────────────────────────────────────────────

  Future<void> _fetchAISuggestions(
    String conversationId,
    String content,
    String senderId,
  ) async {
    final current = state;
    if (current is! ChatLoaded) return;
    if (_mastraDataSource == null) return;

    try {
      final senderRole = current.isStudent ? 'company' : 'student';
      final prompt =
          '''
Génère 3 suggestions de réponse courtes pour ce message.
conversationId: $conversationId
userId de l'expéditeur: $senderId
role de l'expéditeur: $senderRole
Dernier message : "$content"
Réponds STRICTEMENT en format JSON valide contenant une clé "suggestions" qui est une liste d'objets avec "tone" et "message".
''';
      final response = await _mastraDataSource.executeAgent(
        ApiEndpoints.messageAssistant,
        prompt,
      );

      final text = response['text'] as String?;
      if (text != null) {
        final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
        if (match != null) {
          final decoded = jsonDecode(match.group(0)!);
          if (decoded['suggestions'] != null) {
            final List<dynamic> suggs = decoded['suggestions'];
            final List<String> stringSuggestions = suggs
                .map((s) => s['message'].toString())
                .toList();

            if (state is ChatLoaded &&
                (state as ChatLoaded).conversationId == conversationId) {
              emit(
                (state as ChatLoaded).copyWith(
                  suggestions: stringSuggestions,
                  showSuggestions: true,
                ),
              );
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
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Hier';
      } else if (diff.inDays < 7) {
        const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
        return days[date.weekday - 1];
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (_) {
      return '';
    }
  }

  // --- Local Filtering and Archiving ---

  List<ConversationItem> _applyFilters(
    List<ConversationItem> source,
    String filterType,
    String query,
  ) {
    var list = source.where((c) {
      final isArchived = _archivedConversations.contains(c.conversationId);
      if (filterType == 'archived') {
        return isArchived;
      } else {
        if (isArchived)
          return false; // Hide archived conversations from other views
        if (filterType == 'unread') return c.unreadCount > 0;
        if (filterType == 'read') return c.unreadCount == 0;
        return true;
      }
    }).toList();

    if (query.isNotEmpty) {
      final lower = query.toLowerCase();
      list = list
          .where(
            (c) =>
                c.otherPartyName.toLowerCase().contains(lower) ||
                c.otherPartySubtitle.toLowerCase().contains(lower),
          )
          .toList();
    }
    return list;
  }

  void setFilterType(String type, {bool isStudent = false}) {
    if (state is ConversationsLoaded) {
      final current = state as ConversationsLoaded;
      final filtered = _applyFilters(
        _allConversations,
        type,
        current.searchQuery,
      );
      emit(current.copyWith(filterType: type, conversations: filtered));
    }
  }

  void setSearchQuery(String query, {bool isStudent = true}) {
    if (state is ConversationsLoaded) {
      final current = state as ConversationsLoaded;
      final filtered = _applyFilters(
        _allConversations,
        current.filterType,
        query,
      );
      emit(current.copyWith(searchQuery: query, conversations: filtered));
    }
  }

  Future<void> archiveConversation(
    String conversationId,
    bool isStudent,
  ) async {
    _archivedConversations.add(conversationId);
    if (state is ConversationsLoaded) {
      final current = state as ConversationsLoaded;
      emit(
        current.copyWith(
          conversations: _applyFilters(
            _allConversations,
            current.filterType,
            current.searchQuery,
          ),
        ),
      );
    }
    try {
      final column = isStudent ? 'student_archived' : 'company_archived';
      await _client
          .from('conversations')
          .update({column: true})
          .eq('id', conversationId);
    } catch (_) {}
  }

  Future<void> unarchiveConversation(
    String conversationId,
    bool isStudent,
  ) async {
    _archivedConversations.remove(conversationId);
    if (state is ConversationsLoaded) {
      final current = state as ConversationsLoaded;
      emit(
        current.copyWith(
          conversations: _applyFilters(
            _allConversations,
            current.filterType,
            current.searchQuery,
          ),
        ),
      );
    }
    try {
      final column = isStudent ? 'student_archived' : 'company_archived';
      await _client
          .from('conversations')
          .update({column: false})
          .eq('id', conversationId);
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    await _messageChannel?.unsubscribe();
    return super.close();
  }
}
