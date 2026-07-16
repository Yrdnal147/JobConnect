import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\blocs\messaging\messaging_cubit.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update loadConversations query (Recruteur)
load_conv_pattern = r"\.from\('conversations'\)\s*\.select\('id, last_message, last_message_at, student_id, application_id'\)\s*\.eq\('company_id', companyId\)\s*\.order\('last_message_at', ascending: false\);"
new_load_conv = """.from('conversations')
          .select('id, last_message, last_message_at, student_id, application_id')
          .eq('company_id', companyId)
          .eq('is_archived_by_company', false) // NO NEW ARCHIVED
          .order('last_message_at', ascending: false);"""
content = re.sub(load_conv_pattern, new_load_conv, content)

# 2. Update loadStudentConversations query (Student)
load_student_conv_pattern = r"\.from\('conversations'\)\s*\.select\('id, last_message, last_message_at, company_id, application_id'\)\s*\.eq\('student_id', studentId\)\s*\.order\('last_message_at', ascending: false\);"
new_load_student_conv = """.from('conversations')
          .select('id, last_message, last_message_at, company_id, application_id')
          .eq('student_id', studentId)
          .eq('is_archived_by_student', false) // NO NEW ARCHIVED
          .order('last_message_at', ascending: false);"""
content = re.sub(load_student_conv_pattern, new_load_student_conv, content)

# 3. Add archiveConversation method
archive_method = """  // ─── Archive ─────────────────────────────────────────────────────────────

  Future<void> archiveConversation(String conversationId, bool isStudent) async {
    final current = state;
    if (current is! ConversationsLoaded) return;
    
    // Mise à jour optimiste UI
    final updatedList = current.conversations.where((c) => c.conversationId != conversationId).toList();
    emit(ConversationsLoaded(conversations: updatedList));

    try {
      final column = isStudent ? 'is_archived_by_student' : 'is_archived_by_company';
      await _client
          .from('conversations')
          .update({column: true})
          .eq('id', conversationId);
    } catch (e) {
      // Revert if error
      if (isStudent) {
        loadStudentConversations();
      } else {
        loadConversations();
      }
    }
  }

  // ─── Fermeture ────────────────────────────────────────────────────────────"""

content = re.sub(r"  // ─── Fermeture ────────────────────────────────────────────────────────────", archive_method, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated MessagingCubit successfully.")
