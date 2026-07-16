import re

# 1. Update conversations_page.dart
page_path = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\messaging\conversations_page.dart"
with open(page_path, 'r', encoding='utf-8') as f:
    page_content = f.read()

# Add the 'read' chip
chip_pattern = r"_buildChip\('Non-lues', 'unread', currentFilter == 'unread'\),"
chip_replacement = """_buildChip('Non-lues', 'unread', currentFilter == 'unread'),
          const SizedBox(width: AppSpacing.sm),
          _buildChip('Lues', 'read', currentFilter == 'read'),"""
page_content = re.sub(chip_pattern, chip_replacement, page_content)

with open(page_path, 'w', encoding='utf-8') as f:
    f.write(page_content)


# 2. Update messaging_cubit.dart
cubit_path = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\blocs\messaging\messaging_cubit.dart"
with open(cubit_path, 'r', encoding='utf-8') as f:
    cubit_content = f.read()

# Add the filter logic
filter_pattern = r"// Filtre 'unread' \(local\)\s*if \(_currentFilter == 'unread'\) \{\s*filtered = filtered\.where\(\(c\) => c\.unreadCount > 0\)\.toList\(\);\s*\}"
filter_replacement = """// Filtre 'unread' (local)
    if (_currentFilter == 'unread') {
      filtered = filtered.where((c) => c.unreadCount > 0).toList();
    }
    
    // Filtre 'read' (local)
    if (_currentFilter == 'read') {
      filtered = filtered.where((c) => c.unreadCount == 0).toList();
    }"""
cubit_content = re.sub(filter_pattern, filter_replacement, cubit_content)

with open(cubit_path, 'w', encoding='utf-8') as f:
    f.write(cubit_content)

print("Updated filter logic for 'Lues'")
