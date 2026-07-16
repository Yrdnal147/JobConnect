const fs = require('fs');
const frPath = 'C:/Users/LENOVO/JobConnect/jobconnect/assets/translations/fr.json';
const enPath = 'C:/Users/LENOVO/JobConnect/jobconnect/assets/translations/en.json';

function addOfferDetailKeys(path, isFrench) {
  const content = JSON.parse(fs.readFileSync(path, 'utf8'));
  content['offer_detail'] = isFrench ? {
    'title': 'Détails de l\'offre',
    'applied_success': 'Candidature envoyée',
    'no_description': 'Aucune description disponible.',
    'description': 'Description',
    'required_skills': 'Compétences requises',
    'mastered': 'Vous maîtrisez',
    'to_acquire': 'À acquérir',
    'education': 'Niveau d\'éducation requis',
    'minimum': '{} minimum',
    'experience': 'Expérience requise',
    'no_experience': 'Aucune expérience requise',
    'years_experience_single': '{} an minimum',
    'years_experience_plural': '{} ans minimum',
    'published': 'Publié {}',
    'apply': 'Postuler à cette offre',
    'not_found': 'Offre introuvable',
    'retry': 'Réessayer',
    'ai_assistant': 'Assistant IA',
    'advice_before_apply': 'Conseil avant de postuler',
    'ai_analyzing': 'L\'IA analyse votre candidature...',
    'suggestions': 'Voici quelques suggestions :',
    'suggested_action': 'Action suggérée pour "{}"',
    'cancel': 'Annuler',
    'apply_anyway': 'Postuler quand même'
  } : {
    'title': 'Offer Details',
    'applied_success': 'Application sent',
    'no_description': 'No description available.',
    'description': 'Description',
    'required_skills': 'Required skills',
    'mastered': 'You master',
    'to_acquire': 'To acquire',
    'education': 'Required education level',
    'minimum': '{} minimum',
    'experience': 'Required experience',
    'no_experience': 'No experience required',
    'years_experience_single': '{} year minimum',
    'years_experience_plural': '{} years minimum',
    'published': 'Published {}',
    'apply': 'Apply to this offer',
    'not_found': 'Offer not found',
    'retry': 'Retry',
    'ai_assistant': 'AI Assistant',
    'advice_before_apply': 'Advice before applying',
    'ai_analyzing': 'AI is analyzing your application...',
    'suggestions': 'Here are some suggestions:',
    'suggested_action': 'Suggested action for "{}"',
    'cancel': 'Cancel',
    'apply_anyway': 'Apply anyway'
  };
  fs.writeFileSync(path, JSON.stringify(content, null, 2));
}

addOfferDetailKeys(frPath, true);
addOfferDetailKeys(enPath, false);
console.log('done');
