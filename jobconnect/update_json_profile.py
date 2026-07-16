import json

def update_json(filepath, lang):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if lang == 'fr':
        data['company']['profile'].update({
            "logout_error": "Erreur lors de la déconnexion : {}",
            "saved_success": "Profil enregistré ✓",
            "unsaved": "Non sauvegardé",
            "default_name": "Entreprise",
            "info_tab": "Informations",
            "sector_hint": "Ex: Télécoms",
            "size_label": "Taille de l'entreprise",
            "size_1_10": "1-10 employés",
            "size_11_50": "11-50 employés",
            "size_51_200": "51-200 employés",
            "size_200_plus": "200+ employés",
            "desc_label": "Description",
            "desc_hint": "Décrivez votre entreprise...",
            "ceo_label": "Nom du CEO",
            "ceo_hint": "Ex: Jean Dupont",
            "website_hint": "https://...",
            "save_btn": "Enregistrer",
            "verified": "Vérifiée",
            "pending_verification": "En attente de vérification"
        })
    else:
        data['company']['profile'].update({
            "logout_error": "Error during logout: {}",
            "saved_success": "Profile saved ✓",
            "unsaved": "Unsaved",
            "default_name": "Company",
            "info_tab": "Information",
            "sector_hint": "E.g., Telecom",
            "size_label": "Company Size",
            "size_1_10": "1-10 employees",
            "size_11_50": "11-50 employees",
            "size_51_200": "51-200 employees",
            "size_200_plus": "200+ employees",
            "desc_label": "Description",
            "desc_hint": "Describe your company...",
            "ceo_label": "CEO Name",
            "ceo_hint": "E.g., John Doe",
            "website_hint": "https://...",
            "save_btn": "Save",
            "verified": "Verified",
            "pending_verification": "Pending verification"
        })

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\fr.json', 'fr')
update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\en.json', 'en')

print("JSON updated for profile.")
