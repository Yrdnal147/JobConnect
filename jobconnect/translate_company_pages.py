import os
import re

replacements = {
    "my_offers_page.dart": [
        (r"'Offres Actives'", r"'company.offers.active_offers_tab'.tr()"),
        (r"'Brouillons'", r"'company.offers.drafts_tab'.tr()"),
        (r"'Mes Offres'", r"'company.offers.my_offers'.tr()"),
        (r"'company.offers.my_offers'\.tr\(\)", r"'company.offers.my_offers'.tr()"), # avoid double replace
        (r"import 'package:flutter_bloc/flutter_bloc.dart';", r"import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:easy_localization/easy_localization.dart';")
    ],
    "company_profile_page.dart": [
        (r"'Profil Entreprise'", r"'company.profile.title'.tr()"),
        (r"'company.profile.title'\.tr\(\)", r"'company.profile.title'.tr()"),
        (r"import 'package:flutter_bloc/flutter_bloc.dart';", r"import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:easy_localization/easy_localization.dart';")
    ],
    "create_offer_page.dart": [
        (r"'Publier une offre'", r"'company.offers.create_title'.tr()"),
        (r"'Trouvez le talent idéal'", r"'company.offers.create_subtitle'.tr()"),
        (r"'company.offers.create_title'\.tr\(\)", r"'company.offers.create_title'.tr()"),
        (r"import 'package:flutter_bloc/flutter_bloc.dart';", r"import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:easy_localization/easy_localization.dart';")
    ],
    "active_offer_page.dart": [
        (r"'Offres Actives'", r"'company.offers.active_title'.tr()"),
        (r"import 'package:flutter_bloc/flutter_bloc.dart';", r"import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:easy_localization/easy_localization.dart';")
    ],
    "offer_detail_page.dart": [
        (r"'Détails de l\'offre'", r"'company.offers.details.title'.tr()"),
        (r"import 'package:flutter_bloc/flutter_bloc.dart';", r"import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:easy_localization/easy_localization.dart';")
    ],
    "all_candidates_page.dart": [
        (r"'Tous les candidats'", r"'company.candidates.all_title'.tr()"),
        (r"import 'package:flutter_bloc/flutter_bloc.dart';", r"import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:easy_localization/easy_localization.dart';")
    ],
    "retained_candidates_page.dart": [
        (r"'Candidats retenus'", r"'company.candidates.retained_title'.tr()"),
        (r"import 'package:flutter_bloc/flutter_bloc.dart';", r"import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:easy_localization/easy_localization.dart';")
    ],
    "candidate_detail_page.dart": [
        (r"'Profil du candidat'", r"'company.candidates.detail_title'.tr()"),
        (r"import 'package:flutter_bloc/flutter_bloc.dart';", r"import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:easy_localization/easy_localization.dart';")
    ],
    "conversations_page.dart": [
        (r"'Messages'", r"'company.messages.title'.tr()"),
        (r"import 'package:flutter_bloc/flutter_bloc.dart';", r"import 'package:flutter_bloc/flutter_bloc.dart';\nimport 'package:easy_localization/easy_localization.dart';")
    ]
}

def process_files():
    base_dir = r"C:\Users\LENOVO\JobConnect\jobconnect\lib\presentation\pages\company"
    for root, dirs, files in os.walk(base_dir):
        for file in files:
            if file in replacements:
                filepath = os.path.join(root, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                
                # Check if easy_localization is already imported
                has_easy_localization = "import 'package:easy_localization/easy_localization.dart';" in content
                
                for pattern, replacement in replacements[file]:
                    if "easy_localization" in replacement and has_easy_localization:
                        continue
                    content = re.sub(pattern, replacement, content)
                
                if content != original_content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"Updated {file}")

process_files()
