import json
import re

def update_json(filepath, lang):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if lang == 'fr':
        data['company']['offers'].update({
            "no_skill_added": "Aucune compétence ajoutée",
            "no_experience": "Aucune expérience",
            "exp_min_single": "{} an min",
            "exp_min_plural": "{} ans min",
            "duration_label": "Durée (mois)",
            "salary_label": "Rémunération (optionnel)",
            "ai_assistant": "Assistant IA",
            "ai_assistant_desc": "L'agent IA analysera votre offre pour vous suggérer des améliorations",
            "title_hint_short": "Ex: Développeur Flutter",
            "location_hint_short": "Ex: Douala",
            "duration_hint_short": "Ex: 3",
            "salary_hint_short": "Ex: 100 000 FCFA / mois",
            "publish_success": "Offre publiée avec succès",
        })
    else:
        data['company']['offers'].update({
            "no_skill_added": "No skill added",
            "no_experience": "No experience",
            "exp_min_single": "{} yr min",
            "exp_min_plural": "{} yrs min",
            "duration_label": "Duration (months)",
            "salary_label": "Salary (optional)",
            "ai_assistant": "AI Assistant",
            "ai_assistant_desc": "The AI agent will analyze your offer and suggest improvements",
            "title_hint_short": "E.g., Flutter Developer",
            "location_hint_short": "E.g., Douala",
            "duration_hint_short": "E.g., 3",
            "salary_hint_short": "E.g., 100,000 FCFA / month",
            "publish_success": "Offer published successfully",
        })

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\fr.json', 'fr')
update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\en.json', 'en')

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\company\offers\create_offer_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    (r"'Offre publiée avec succès'", r"'company.offers.publish_success'.tr()"),
    (r"'Ex: Développeur Flutter'", r"'company.offers.title_hint_short'.tr()"),
    (r"'Aucune compétence ajoutée'", r"'company.offers.no_skill_added'.tr()"),
    (r"'Niveau d\\'éducation minimum'", r"'company.offers.education_label'.tr()"),
    (r"'Années d\\'expérience requises'", r"'company.offers.experience_label'.tr()"),
    (r"'Aucune expérience'", r"'company.offers.no_experience'.tr()"),
    (r"'\$_yearsOfExp an\$\{\_yearsOfExp > 1 \? 's' : ''\} min'", r"_yearsOfExp > 1 ? 'company.offers.exp_min_plural'.tr(args: [_yearsOfExp.toString()]) : 'company.offers.exp_min_single'.tr(args: [_yearsOfExp.toString()])"),
    (r"'Ex: Douala'", r"'company.offers.location_hint_short'.tr()"),
    (r"'Durée \(mois\)'", r"'company.offers.duration_label'.tr()"),
    (r"'Ex: 3'", r"'company.offers.duration_hint_short'.tr()"),
    (r"'Rémunération \(optionnel\)'", r"'company.offers.salary_label'.tr()"),
    (r"'Ex: 100 000 FCFA / mois'", r"'company.offers.salary_hint_short'.tr()"),
    (r"'Assistant IA'", r"'company.offers.ai_assistant'.tr()"),
    (r"'L\\'agent IA analysera votre offre pour vous suggérer des améliorations'", r"'company.offers.ai_assistant_desc'.tr()")
]

for p, r in replacements:
    content = re.sub(p, r, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("create_offer_page fully translated.")
