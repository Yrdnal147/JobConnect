import re

# Conversations Page
filepath_conv = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\company\messaging\conversations_page.dart"
with open(filepath_conv, 'r', encoding='utf-8') as f:
    content_conv = f.read()

replacements_conv = [
    (r"'Aucune conversation'", r"'company.messages.no_conversation'.tr()"),
    (r"'Retenez des candidats pour débloquer\\nla messagerie'", r"'company.messages.no_conversation_desc'.tr()"),
    (r"'Voir les candidatures'", r"'company.messages.see_candidates'.tr()"),
    (r"'Impossible de charger les messages'", r"'company.messages.error_loading'.tr()"),
    (r"'Réessayer'", r"'company.messages.retry'.tr()")
]

for p, r in replacements_conv:
    content_conv = re.sub(p, r, content_conv)

with open(filepath_conv, 'w', encoding='utf-8') as f:
    f.write(content_conv)

# Chat Page
filepath_chat = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\company\messaging\chat_page.dart"
with open(filepath_chat, 'r', encoding='utf-8') as f:
    content_chat = f.read()

replacements_chat = [
    (r"'Impossible de charger la conversation'", r"'company.messages.chat_error_loading'.tr()"),
    (r"'Réessayer'", r"'company.messages.retry'.tr()"),
    (r"'Suggestions IA'", r"'company.messages.ai_suggestions'.tr()"),
    (r"'Écrire un message\.\.\.'", r"'company.messages.write_message_hint'.tr()"),
    (r"'Démarrez la conversation'", r"'company.messages.start_chat'.tr()"),
    (r"'Envoyez un premier message pour\\ndémarrer la discussion\.'", r"'company.messages.start_chat_desc'.tr()")
]

for p, r in replacements_chat:
    content_chat = re.sub(p, r, content_chat)

# In chat_page.dart, we need to add the import for easy_localization since it uses .tr()
if "import 'package:easy_localization/easy_localization.dart';" not in content_chat:
    content_chat = content_chat.replace(
        "import 'package:flutter_bloc/flutter_bloc.dart';",
        "import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:easy_localization/easy_localization.dart';"
    )

with open(filepath_chat, 'w', encoding='utf-8') as f:
    f.write(content_chat)

print("Messaging pages translated successfully.")
