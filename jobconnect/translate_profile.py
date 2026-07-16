import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\company\profile\company_profile_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    (r"'Erreur lors de la déconnexion : \$\{state\.message\}'", r"'company.profile.logout_error'.tr(args: [state.message])"),
    (r"'Profil enregistré ✓'", r"'company.profile.saved_success'.tr()"),
    (r"Text\(\s*'Non sauvegardé'", r"Text(\n                                            'company.profile.unsaved'.tr()"),
    (r"tooltip:\s*'Paramètres'", r"tooltip: 'company.profile.settings'.tr()"),
    (r"profile\?\.name \?\? 'Entreprise'", r"profile?.name ?? 'company.profile.default_name'.tr()"),
    (r"Text\('Informations',", r"Text('company.profile.info_tab'.tr(),"),
    (r"_fieldLabel\('Secteur d\\'activité',", r"_fieldLabel('company.profile.industry'.tr(),"),
    (r"_decoration\('Ex: Télécoms',", r"_decoration('company.profile.sector_hint'.tr(),"),
    (r"_fieldLabel\('Taille de l\\'entreprise',", r"_fieldLabel('company.profile.size_label'.tr(),"),
    (r"Text\('1-10 employés'\)", r"Text('company.profile.size_1_10'.tr())"),
    (r"Text\('11-50 employés'\)", r"Text('company.profile.size_11_50'.tr())"),
    (r"Text\('51-200 employés'\)", r"Text('company.profile.size_51_200'.tr())"),
    (r"Text\('200\+ employés'\)", r"Text('company.profile.size_200_plus'.tr())"),
    (r"_fieldLabel\(\s*'Description',\s*Icons\.notes_rounded\)", r"_fieldLabel('company.profile.desc_label'.tr(), Icons.notes_rounded)"),
    (r"_decoration\('Décrivez votre entreprise\.\.\.'\)", r"_decoration('company.profile.desc_hint'.tr())"),
    (r"_fieldLabel\('Nom du CEO', Icons\.badge_outlined\)", r"_fieldLabel('company.profile.ceo_label'.tr(), Icons.badge_outlined)"),
    (r"_decoration\('Ex: Jean Dupont',", r"_decoration('company.profile.ceo_hint'.tr(),"),
    (r"_fieldLabel\('Site web', Icons\.language_rounded\)", r"_fieldLabel('company.profile.website'.tr(), Icons.language_rounded)"),
    (r"_decoration\('https://\.\.\.',", r"_decoration('company.profile.website_hint'.tr(),"),
    (r"Text\(\s*'Enregistrer'", r"Text(\n                                      'company.profile.save_btn'.tr()"),
    (r"Text\(\s*'Se déconnecter'", r"Text(\n                                'company.profile.logout'.tr()"),
    (r"label = 'Vérifiée';", r"label = 'company.profile.verified'.tr();"),
    (r"label = 'En attente de vérification';", r"label = 'company.profile.pending_verification'.tr();")
]

for p, r in replacements:
    content = re.sub(p, r, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Profile page translated successfully.")
