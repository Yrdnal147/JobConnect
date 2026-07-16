import json
import re

def update_json(filepath, lang):
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)

    if lang == 'fr':
        data['company']['offers'].update({
            "manage_desc": "Gérez vos publications et leur visibilité",
            "active_single": "{} active",
            "active_plural": "{} actives",
            "publish_offer": "Publier une offre",
            "empty_title": "Aucune offre publiée",
            "empty_subtitle": "Vos offres apparaîtront ici",
            "publish_first": "Publier votre première offre",
            "error_loading": "Impossible de charger les offres",
            "retry": "Réessayer",
            "published_at": "Publié le {}",
            "application_single": "{} candidature",
            "application_plural": "{} candidatures",
            "view_candidates": "Voir candidats"
        })
    else:
        data['company']['offers'].update({
            "manage_desc": "Manage your publications and their visibility",
            "active_single": "{} active",
            "active_plural": "{} active",
            "publish_offer": "Publish an Offer",
            "empty_title": "No published offers",
            "empty_subtitle": "Your offers will appear here",
            "publish_first": "Publish your first offer",
            "error_loading": "Failed to load offers",
            "retry": "Retry",
            "published_at": "Published on {}",
            "application_single": "{} application",
            "application_plural": "{} applications",
            "view_candidates": "View Candidates"
        })

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\fr.json', 'fr')
update_json('C:\\Users\\LENOVO\\JobConnect\\jobconnect\\assets\\translations\\en.json', 'en')

# Now update my_offers_page.dart
filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\company\offers\my_offers_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    (r"'Gérez vos publications et leur visibilité'", r"'company.offers.manage_desc'.tr()"),
    (r"'\$activeCount active\$\{activeCount > 1 \? 's' : ''\}'", r"activeCount > 1 ? 'company.offers.active_plural'.tr(args: [activeCount.toString()]) : 'company.offers.active_single'.tr(args: [activeCount.toString()])"),
    (r"'Publier une offre'", r"'company.offers.publish_offer'.tr()"),
    (r"'Aucune offre publiée'", r"'company.offers.empty_title'.tr()"),
    (r"'Vos offres apparaîtront ici'", r"'company.offers.empty_subtitle'.tr()"),
    (r"'Publier votre première offre'", r"'company.offers.publish_first'.tr()"),
    (r"'Impossible de charger les offres'", r"'company.offers.error_loading'.tr()"),
    (r"const Text\('Réessayer'\)", r"Text('company.offers.retry'.tr())"),
    (r"'Publié le \$\{offer.postedAt\}'", r"'company.offers.published_at'.tr(args: [offer.postedAt])"),
    (r"'\$\{offer.applicationsCount\} candidature\$\{offer.applicationsCount > 1 \? 's' : ''\}'", r"offer.applicationsCount > 1 ? 'company.offers.application_plural'.tr(args: [offer.applicationsCount.toString()]) : 'company.offers.application_single'.tr(args: [offer.applicationsCount.toString()])"),
    (r"'Voir candidats'", r"'company.offers.view_candidates'.tr()")
]

for p, r in replacements:
    content = re.sub(p, r, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Offers page translated successfully.")
