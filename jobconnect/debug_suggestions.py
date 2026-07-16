import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\blocs\messaging\messaging_cubit.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Let's replace the _fetchAISuggestions method to add logging and better JSON parsing.
pattern = r"Future<void> _fetchAISuggestions\([\s\S]*?catch \(_\) \{\}\s*\}"
replacement = """Future<void> _fetchAISuggestions(String conversationId, String content, String senderId) async {
    final current = state;
    if (current is! ChatLoaded) return;
    if (_mastraDataSource == null) {
      print("AI Suggestions Error: _mastraDataSource is null");
      return;
    }
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
      print("Fetching AI suggestions...");
      final response = await _mastraDataSource!.executeAgent(ApiEndpoints.messageAssistant, prompt);
      print("AI Suggestions Response: $response");
      
      final text = response['text'] as String?;
      if (text != null) {
        final match = RegExp(r'\{[\s\S]*\}', dotAll: true).firstMatch(text);
        if (match != null) {
          try {
            final decoded = jsonDecode(match.group(0)!);
            if (decoded['suggestions'] != null) {
              final List<dynamic> suggs = decoded['suggestions'];
              final List<String> stringSuggestions = suggs.map((s) => s['message'].toString()).toList();
              if (state is ChatLoaded && (state as ChatLoaded).conversationId == conversationId) {
                emit((state as ChatLoaded).copyWith(suggestions: stringSuggestions, showSuggestions: true));
                print("AI Suggestions updated successfully");
              }
            }
          } catch (e) {
            print("AI Suggestions JSON Parsing Error: $e");
          }
        } else {
          print("AI Suggestions Regex Match Failed on: $text");
        }
      }
    } catch (e) {
      print("AI Suggestions Network/API Error: $e");
    }
  }"""
content = re.sub(pattern, replacement, content)

# Also let's set initial suggestions to empty or "Chargement..."
initial_pattern = r"final suggestions = isStudent\s*\?\s*\['Merci !', 'Je suis disponible\.', 'Bien reçu\.'\]\s*:\s*\['Merci\.', 'Êtes-vous disponible \?', 'Bien reçu\.'\];"
initial_replacement = "final suggestions = ['Chargement des suggestions IA...'];"
content = re.sub(initial_pattern, initial_replacement, content)


with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated _fetchAISuggestions for logging")
