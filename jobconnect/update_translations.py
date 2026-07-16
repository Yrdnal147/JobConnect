import json

def update_json(filepath, lang):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if lang == 'fr':
        company_data = {
            "dashboard": {
                "overview": "Vue d'ensemble",
                "active_offers": "Offres actives",
                "applications": "Candidatures",
                "retained": "Retenus",
                "messages": "Messages",
                "recent_applications": "Candidatures récentes",
                "see_all": "Voir tout",
                "quick_actions": "Actions rapides",
                "publish_offer": "Publier une offre",
                "empty_applications": "Aucune candidature pour l'instant",
                "publish_first_offer": "Publier votre première offre",
                "error_loading": "Impossible de charger les données",
                "retry": "Réessayer",
                "hello": "Bonjour "
            },
            "offers": {
                "active_title": "Offres Actives",
                "my_offers": "Mes Offres",
                "create_title": "Publier une offre",
                "create_subtitle": "Trouvez le talent idéal",
                "title_label": "Titre du poste",
                "description_label": "Description du poste",
                "type_label": "Type de contrat",
                "requirements_label": "Compétences requises",
                "publish_btn": "Publier l'offre",
                "empty_offers": "Aucune offre publiée pour le moment",
                "active_offers_tab": "Offres Actives",
                "drafts_tab": "Brouillons",
                "see_details": "Voir les détails",
                "applications_count": "{} candidatures",
                "edit_offer": "Modifier l'offre",
                "delete_offer": "Supprimer l'offre",
                "delete_confirm_title": "Supprimer l'offre ?",
                "delete_confirm_desc": "Cette action est irréversible. Toutes les candidatures associées seront également supprimées.",
                "cancel": "Annuler",
                "delete": "Supprimer",
                "details": {
                    "title": "Détails de l'offre",
                    "edit": "Modifier",
                    "delete": "Supprimer",
                    "description": "Description",
                    "skills": "Compétences requises",
                    "candidates": "Candidats",
                    "no_candidates": "Aucun candidat pour l'instant",
                    "view_all_candidates": "Voir tous les candidats",
                    "close_offer": "Clôturer l'offre",
                    "republish_offer": "Republier l'offre",
                    "published_on": "Publié le {}",
                    "closed_on": "Clôturé le {}"
                }
            },
            "candidates": {
                "all_title": "Tous les candidats",
                "retained_title": "Candidats retenus",
                "detail_title": "Profil du candidat",
                "match_score": "Score de matching",
                "ai_analysis": "Analyse IA",
                "skills": "Compétences",
                "education": "Formation",
                "experience": "Expérience",
                "contact": "Contacter",
                "reject": "Refuser",
                "retain": "Retenir le profil",
                "retained": "Profil retenu",
                "rejected": "Profil refusé",
                "send_message": "Envoyer un message",
                "view_cv": "Voir le CV",
                "no_cv": "Aucun CV disponible",
                "status_pending": "En attente",
                "status_retained": "Retenu",
                "status_rejected": "Refusé",
                "empty_all": "Aucun candidat pour le moment",
                "empty_retained": "Aucun candidat retenu pour l'instant"
            },
            "profile": {
                "title": "Profil Entreprise",
                "settings": "Paramètres",
                "about": "À propos",
                "website": "Site web",
                "industry": "Secteur d'activité",
                "location": "Localisation",
                "edit_profile": "Modifier le profil",
                "logout": "Se déconnecter",
                "complete_profile": "Compléter le profil"
            },
            "messages": {
                "title": "Messages",
                "empty_conversations": "Aucune conversation",
                "empty_conversations_desc": "Vos conversations avec les candidats apparaîtront ici",
                "type_message": "Écrire un message...",
                "send": "Envoyer"
            }
        }
    else:
        company_data = {
            "dashboard": {
                "overview": "Overview",
                "active_offers": "Active Offers",
                "applications": "Applications",
                "retained": "Retained",
                "messages": "Messages",
                "recent_applications": "Recent Applications",
                "see_all": "See All",
                "quick_actions": "Quick Actions",
                "publish_offer": "Publish an Offer",
                "empty_applications": "No applications yet",
                "publish_first_offer": "Publish your first offer",
                "error_loading": "Failed to load data",
                "retry": "Retry",
                "hello": "Hello "
            },
            "offers": {
                "active_title": "Active Offers",
                "my_offers": "My Offers",
                "create_title": "Publish an Offer",
                "create_subtitle": "Find the perfect talent",
                "title_label": "Job Title",
                "description_label": "Job Description",
                "type_label": "Contract Type",
                "requirements_label": "Required Skills",
                "publish_btn": "Publish Offer",
                "empty_offers": "No published offers yet",
                "active_offers_tab": "Active Offers",
                "drafts_tab": "Drafts",
                "see_details": "View Details",
                "applications_count": "{} applications",
                "edit_offer": "Edit Offer",
                "delete_offer": "Delete Offer",
                "delete_confirm_title": "Delete this offer?",
                "delete_confirm_desc": "This action cannot be undone. All associated applications will also be deleted.",
                "cancel": "Cancel",
                "delete": "Delete",
                "details": {
                    "title": "Offer Details",
                    "edit": "Edit",
                    "delete": "Delete",
                    "description": "Description",
                    "skills": "Required Skills",
                    "candidates": "Candidates",
                    "no_candidates": "No candidates yet",
                    "view_all_candidates": "View all candidates",
                    "close_offer": "Close Offer",
                    "republish_offer": "Republish Offer",
                    "published_on": "Published on {}",
                    "closed_on": "Closed on {}"
                }
            },
            "candidates": {
                "all_title": "All Candidates",
                "retained_title": "Retained Candidates",
                "detail_title": "Candidate Profile",
                "match_score": "Match Score",
                "ai_analysis": "AI Analysis",
                "skills": "Skills",
                "education": "Education",
                "experience": "Experience",
                "contact": "Contact",
                "reject": "Reject",
                "retain": "Retain Profile",
                "retained": "Profile Retained",
                "rejected": "Profile Rejected",
                "send_message": "Send Message",
                "view_cv": "View Resume",
                "no_cv": "No Resume available",
                "status_pending": "Pending",
                "status_retained": "Retained",
                "status_rejected": "Rejected",
                "empty_all": "No candidates yet",
                "empty_retained": "No retained candidates yet"
            },
            "profile": {
                "title": "Company Profile",
                "settings": "Settings",
                "about": "About",
                "website": "Website",
                "industry": "Industry",
                "location": "Location",
                "edit_profile": "Edit Profile",
                "logout": "Log Out",
                "complete_profile": "Complete Profile"
            },
            "messages": {
                "title": "Messages",
                "empty_conversations": "No conversations",
                "empty_conversations_desc": "Your conversations with candidates will appear here",
                "type_message": "Type a message...",
                "send": "Send"
            }
        }

    data['company'] = company_data
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\fr.json', 'fr')
update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\en.json', 'en')
