const fs = require('fs');

function updateTranslations(path, isFrench) {
  const content = JSON.parse(fs.readFileSync(path, 'utf8'));
  content.settings['current_password'] = isFrench ? "Mot de passe actuel" : "Current password";
  content.settings['current_password_incorrect'] = isFrench ? "L'ancien mot de passe est incorrect." : "The current password is incorrect.";
  content.settings['password_empty'] = isFrench ? "Veuillez entrer l'ancien mot de passe." : "Please enter the current password.";
  fs.writeFileSync(path, JSON.stringify(content, null, 2));
}

updateTranslations('C:/Users/LENOVO/JobConnect/jobconnect/assets/translations/fr.json', true);
updateTranslations('C:/Users/LENOVO/JobConnect/jobconnect/assets/translations/en.json', false);
console.log('Translations updated');
