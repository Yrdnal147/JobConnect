import { createClient } from '@supabase/supabase-js';
import { GoogleGenerativeAI } from '@google/generative-ai';
import * as dotenv from 'dotenv';

dotenv.config();

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_KEY!);
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_GENERATIVE_AI_API_KEY!);
const model = genAI.getGenerativeModel({ model: 'gemini-embedding-2' });

async function main() {
  console.log('Récupération des offres sans embedding...');
  const { data: offers, error } = await supabase
    .from('offers')
    .select('id, title, description, required_skills, min_education, offer_type')
    .filter('embedding', 'is', 'null');

  if (error || !offers) {
    console.error('Erreur:', error);
    return;
  }

  console.log(`${offers.length} offres à traiter.`);

  for (const offer of offers) {
    console.log(`Processing ${offer.id} (${offer.title})...`);
    const skillsText = Array.isArray(offer.required_skills) 
      ? offer.required_skills.join(', ') 
      : offer.required_skills;
      
    const offerText = `
      Titre: ${offer.title}
      Type: ${offer.offer_type}
      Niveau requis: ${offer.min_education}
      Compétences requises: ${skillsText}
      Description: ${offer.description}
    `.trim();

    try {
      const result = await model.embedContent(offerText);
      const embedding = result.embedding.values.slice(0, 1536);

      const { error: updateError } = await supabase
        .from('offers')
        .update({ embedding })
        .eq('id', offer.id);
        
      if (updateError) {
        console.error(`Erreur maj ${offer.id}:`, updateError);
      } else {
        console.log(`✅ Embedding sauvegardé pour ${offer.id}`);
      }
    } catch (e) {
      console.error(`Erreur IA pour ${offer.id}:`, e);
    }
  }
  
  console.log('Terminé !');
}

main();
