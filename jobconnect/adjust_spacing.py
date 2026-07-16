import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\messaging\conversations_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Change the spacing above the search bar
pattern = r"const SizedBox\(height: AppSpacing\.lg\),\s*// Barre de recherche"
replacement = r"const SizedBox(height: AppSpacing.sm),\n                            // Barre de recherche"
content = re.sub(pattern, replacement, content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated spacing")
