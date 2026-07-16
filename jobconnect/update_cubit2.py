import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\blocs\messaging\messaging_cubit.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update loadConversations (Company)
p1 = r"Future<void> loadConversations\(\) async \{"
r1 = """Future<void> loadConversations({bool showArchived = false}) async {"""
content = re.sub(p1, r1, content)

p1b = r"\.eq\('is_archived_by_company', false\)"
r1b = """.eq('is_archived_by_company', showArchived)"""
content = re.sub(p1b, r1b, content)

# 2. Update loadStudentConversations (Student)
p2 = r"Future<void> loadStudentConversations\(\) async \{"
r2 = """Future<void> loadStudentConversations({bool showArchived = false}) async {"""
content = re.sub(p2, r2, content)

p2b = r"\.eq\('is_archived_by_student', false\)"
r2b = """.eq('is_archived_by_student', showArchived)"""
content = re.sub(p2b, r2b, content)

# 3. Update the emit for ConversationsLoaded
p3 = r"emit\(ConversationsLoaded\(conversations: conversations\)\);"
r3 = """emit(ConversationsLoaded(conversations: conversations, isShowingArchived: showArchived));"""
content = re.sub(p3, r3, content)

# 4. Add toggleArchiveView and unarchiveConversation to the Archive section
p4 = r"// ─── Archive ─────────────────────────────────────────────────────────────"
r4 = """// ─── Archive ─────────────────────────────────────────────────────────────

  Future<void> toggleArchiveView(bool isStudent) async {
    final current = state;
    bool showArchived = true;
    if (current is ConversationsLoaded) {
      showArchived = !current.isShowingArchived;
    }
    
    if (isStudent) {
      await loadStudentConversations(showArchived: showArchived);
    } else {
      await loadConversations(showArchived: showArchived);
    }
  }

  Future<void> unarchiveConversation(String conversationId, bool isStudent) async {
    final current = state;
    if (current is! ConversationsLoaded) return;
    
    // Optimistic UI update
    final updatedList = current.conversations.where((c) => c.conversationId != conversationId).toList();
    emit(ConversationsLoaded(conversations: updatedList, isShowingArchived: current.isShowingArchived));

    try {
      final column = isStudent ? 'is_archived_by_student' : 'is_archived_by_company';
      await _client
          .from('conversations')
          .update({column: false})
          .eq('id', conversationId);
    } catch (e) {
      if (isStudent) {
        loadStudentConversations(showArchived: true);
      } else {
        loadConversations(showArchived: true);
      }
    }
  }"""
content = re.sub(p4, r4, content)

# Note: The emit for ConversationsLoaded with empty lists also needs isShowingArchived
p5 = r"emit\(const ConversationsLoaded\(conversations: \[\]\)\);"
r5 = """emit(ConversationsLoaded(conversations: const [], isShowingArchived: showArchived));"""
content = re.sub(p5, r5, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated MessagingCubit")
