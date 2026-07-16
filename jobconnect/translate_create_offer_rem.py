import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\company\offers\create_offer_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = [
    (r"final List<Map<String, String>> _offerTypes = \[", r"List<Map<String, String>> get _offerTypes => ["),
    (r"\{'value': 'cdi',\s*'label': 'CDI'\}", r"{'value': 'cdi', 'label': 'home.filters.cdi'.tr()}"),
    (r"\{'value': 'cdd',\s*'label': 'CDD'\}", r"{'value': 'cdd', 'label': 'home.filters.cdd'.tr()}"),
    (r"\{'value': 'stage_academique',\s*'label': 'Stage académique'\}", r"{'value': 'stage_academique', 'label': 'home.filters.academic_internship'.tr()}"),
    (r"\{'value': 'stage_professionnel',\s*'label': 'Stage professionnel'\}", r"{'value': 'stage_professionnel', 'label': 'home.filters.pro_internship'.tr()}"),
    (r"_sectionLabel\(\s*'Description',\s*Icons\.description_outlined\)", r"_sectionLabel('company.offers.description_label'.tr(), Icons.description_outlined)"),
    (r"_decoration\(\s*'Décrivez le poste, les missions, les responsabilités\.\.\.',?\s*\)", r"_decoration('company.offers.description_hint'.tr())"),
    (r"'Ex:\s*compatbilté de gestion\.\.\.'", r"'company.offers.add_skill_hint'.tr()"),
    (r"'jauge de complétion de l\\'offre'", r"'company.offers.completion_gauge'.tr()"),
]

for p, r in replacements:
    content = re.sub(p, r, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("create_offer_page remaining fields translated successfully.")
