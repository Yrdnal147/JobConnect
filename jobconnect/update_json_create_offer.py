import json

def update_json(filepath, lang):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if lang == 'fr':
        data['company']['offers'].update({
            "title_hint": "Ex: Développeur Flutter Sénior",
            "description_hint": "Décrivez les missions, l'environnement...",
            "education_label": "Niveau d'études minimum",
            "add_skill_hint": "Ajouter une compétence",
            "location_label": "Localisation",
            "location_hint": "Ex: Douala, Akwa",
            "experience_label": "Années d'expérience",
            "salary_label": "Salaire (optionnel)",
            "salary_hint": "Ex: 500k - 800k FCFA",
            "duration_label": "Durée en mois (optionnel)",
            "duration_hint": "Ex: 6",
            "main_info": "Informations principales",
            "profile_wanted": "Profil recherché",
            "additional_details": "Détails additionnels",
            "published_success": "Offre publiée ✓"
        })
    else:
        data['company']['offers'].update({
            "title_hint": "E.g., Senior Flutter Developer",
            "description_hint": "Describe the missions, environment...",
            "education_label": "Minimum Education Level",
            "add_skill_hint": "Add a skill",
            "location_label": "Location",
            "location_hint": "E.g., Douala, Akwa",
            "experience_label": "Years of Experience",
            "salary_label": "Salary (optional)",
            "salary_hint": "E.g., 500k - 800k FCFA",
            "duration_label": "Duration in months (optional)",
            "duration_hint": "E.g., 6",
            "main_info": "Main Information",
            "profile_wanted": "Desired Profile",
            "additional_details": "Additional Details",
            "published_success": "Offer published ✓"
        })

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\fr.json', 'fr')
update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\en.json', 'en')

print("JSON files updated.")
