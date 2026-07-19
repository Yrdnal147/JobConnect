import { supabase } from './src/mastra/supabase';
import { calculateFinalScore } from './src/mastra/utils/scoring';

async function run() {
  console.log("Recalcul des scores avec la nouvelle pénalité...");

  // 1. Fetch all offers
  const { data: offers } = await supabase.from('offers').select('*');
  if (!offers) return;

  // 2. Fetch all students who have a feed_cache
  const { data: caches } = await supabase.from('feed_cache').select('student_id, cards');
  if (!caches) return;

  for (const cache of caches) {
    const studentId = cache.student_id;
    const { data: profile } = await supabase.from('student_profiles').select('education_level, years_of_experience').eq('id', studentId).maybeSingle();
    const { data: skills } = await supabase.from('skills').select('name, skill_type').eq('student_id', studentId);
    
    const studentTechSkills = (skills || [])
      .filter((s: any) => s.skill_type === 'technical')
      .map((s: any) => s.name.toLowerCase());

    const newCards = [];

    // On reprend chaque ancienne carte pour récupérer la similarité brute
    for (const card of cache.cards) {
       const offer = offers.find(o => o.id === card.offerId);
       if (!offer) continue;

       // On doit retrouver pgvectorSimilarity depuis le score sémantique enregistré
       // old semantic = ((sim - 0.65) / (0.88 - 0.65)) * 100
       // sim = (semantic / 100) * 0.23 + 0.65
       let pgvectorSimilarity = 0.65;
       if (card.details && card.details.semantic !== undefined) {
          pgvectorSimilarity = (card.details.semantic / 100) * 0.23 + 0.65;
       }

       const { finalScore, details } = calculateFinalScore(
          studentTechSkills,
          offer.required_skills || [],
          pgvectorSimilarity,
          profile?.years_of_experience || 0,
          offer.years_of_experience ?? null,
          profile?.education_level || '',
          offer.min_education ?? null
       );

       newCards.push({
         offerId: offer.id,
         matchScore: finalScore,
         isHighMatch: finalScore >= 70,
         details
       });
    }

    newCards.sort((a: any, b: any) => b.matchScore - a.matchScore);

    await supabase.from('feed_cache').upsert({
      student_id: studentId,
      cards: newCards,
      generated_at: new Date().toISOString()
    }, { onConflict: 'student_id' });
    
    console.log(`✅ Scores mis à jour pour l'étudiant ${studentId}`);
  }

  console.log("Terminé.");
}

run().catch(console.error);
