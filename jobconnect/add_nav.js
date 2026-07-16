const fs = require('fs');

function addNavKeys(path, isFrench) {
  const content = JSON.parse(fs.readFileSync(path, 'utf8'));
  content['nav'] = isFrench ? {
    "home": "Accueil",
    "search": "Recherche",
    "applications": "Candidatures",
    "messages": "Messages",
    "profile": "Profil",
    "dashboard": "Dashboard",
    "offers": "Offres",
    "publish": "Publier"
  } : {
    "home": "Home",
    "search": "Search",
    "applications": "Applications",
    "messages": "Messages",
    "profile": "Profile",
    "dashboard": "Dashboard",
    "offers": "Offers",
    "publish": "Publish"
  };
  fs.writeFileSync(path, JSON.stringify(content, null, 2));
}

addNavKeys('C:/Users/LENOVO/JobConnect/jobconnect/assets/translations/fr.json', true);
addNavKeys('C:/Users/LENOVO/JobConnect/jobconnect/assets/translations/en.json', false);
console.log('nav injected');
