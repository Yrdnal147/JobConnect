import re

filepath = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\student\messaging\conversations_page.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add resizeToAvoidBottomInset: false
scaffold_pattern = r"return Scaffold\(\s*backgroundColor: AppColorsLight\.bgDark,"
scaffold_replacement = "return Scaffold(\n            resizeToAvoidBottomInset: false,\n            backgroundColor: AppColorsLight.bgDark,"
content = re.sub(scaffold_pattern, scaffold_replacement, content)

# 2. Add SingleChildScrollView to empty state
empty_pattern = r"Widget _buildEmptyState\(bool isArchived\) \{\s*return Center\(\s*child: Column\("
empty_replacement = "Widget _buildEmptyState(bool isArchived) {\n    return Center(\n      child: SingleChildScrollView(\n        child: Column("
content = re.sub(empty_pattern, empty_replacement, content)

# Also close the parenthesis for SingleChildScrollView in empty state
empty_close_pattern = r"textAlign: TextAlign\.center,\s*\),\s*\],\s*\),\s*\);"
empty_close_replacement = "textAlign: TextAlign.center,\n          ),\n        ],\n      ),\n      ),\n    );"
content = re.sub(empty_close_pattern, empty_close_replacement, content)


with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed overflow")
