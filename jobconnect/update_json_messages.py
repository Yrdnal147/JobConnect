import json

def update_json(filepath, lang):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if 'messages' not in data['company']:
        data['company']['messages'] = {}

    if lang == 'fr':
        data['company']['messages'].update({
            "no_conversation": "Aucune conversation",
            "no_conversation_desc": "Retenez des candidats pour débloquer\nla messagerie",
            "see_candidates": "Voir les candidatures",
            "error_loading": "Impossible de charger les messages",
            "retry": "Réessayer",
            "chat_error_loading": "Impossible de charger la conversation",
            "ai_suggestions": "Suggestions IA",
            "write_message_hint": "Écrire un message...",
            "start_chat": "Démarrez la conversation",
            "start_chat_desc": "Envoyez un premier message pour\ndémarrer la discussion."
        })
    else:
        data['company']['messages'].update({
            "no_conversation": "No conversation",
            "no_conversation_desc": "Shortlist candidates to unlock\nmessaging",
            "see_candidates": "View candidates",
            "error_loading": "Failed to load messages",
            "retry": "Retry",
            "chat_error_loading": "Failed to load the conversation",
            "ai_suggestions": "AI Suggestions",
            "write_message_hint": "Write a message...",
            "start_chat": "Start the conversation",
            "start_chat_desc": "Send a first message to\nstart the discussion."
        })

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\fr.json', 'fr')
update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\en.json', 'en')

print("JSON updated for messages.")
