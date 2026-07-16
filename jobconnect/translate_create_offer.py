import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\company\offers\create_offer_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    (r"'Titre du poste'", r"'company.offers.title_label'.tr()"),
    (r"'Ex: Développeur Flutter Sénior'", r"'company.offers.title_hint'.tr()"),
    (r"'Description du poste'", r"'company.offers.description_label'.tr()"),
    (r"'Décrivez les missions, l\\'environnement...'", r"'company.offers.description_hint'.tr()"),
    (r"'Type de contrat'", r"'company.offers.type_label'.tr()"),
    (r"'Niveau d\\'études minimum'", r"'company.offers.education_label'.tr()"),
    (r"'Compétences requises'", r"'company.offers.requirements_label'.tr()"),
    (r"'Ajouter une compétence'", r"'company.offers.add_skill_hint'.tr()"),
    (r"'Localisation'", r"'company.offers.location_label'.tr()"),
    (r"'Ex: Douala, Akwa'", r"'company.offers.location_hint'.tr()"),
    (r"'Années d\\'expérience'", r"'company.offers.experience_label'.tr()"),
    (r"'Salaire \(optionnel\)'", r"'company.offers.salary_label'.tr()"),
    (r"'Ex: 500k - 800k FCFA'", r"'company.offers.salary_hint'.tr()"),
    (r"'Durée en mois \(optionnel\)'", r"'company.offers.duration_label'.tr()"),
    (r"'Ex: 6'", r"'company.offers.duration_hint'.tr()"),
    (r"'Publier l\\'offre'", r"'company.offers.publish_btn'.tr()"),
    (r"'Informations principales'", r"'company.offers.main_info'.tr()"),
    (r"'Profil recherché'", r"'company.offers.profile_wanted'.tr()"),
    (r"'Détails additionnels'", r"'company.offers.additional_details'.tr()"),
    (r"'Offre publiée ✓'", r"'company.offers.published_success'.tr()")
]

for p, r in replacements:
    content = re.sub(p, r, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("create_offer_page translated successfully.")
