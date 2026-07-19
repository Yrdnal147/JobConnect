import { createStep, createWorkflow } from '@mastra/core/workflows';
import { z } from 'zod';
import { supabase } from '../supabase.js';
import { calculateFinalScore } from '../utils/scoring.js';

// ─────────────────────────────────────────────
// 1️⃣ STEP: FETCH AND EMBED OFFER
// ─────────────────────────────────────────────
const embedOfferStep = createStep({
  id: 'embed-offer',

  inputSchema: z.object({
    offerId: z.string().uuid(),
  }),

  outputSchema: z.object({
    success: z.boolean(),
    offerId: z.string().uuid(),
    message: z.string(),
  }),

  execute: async ({ inputData }) => {
    try {
      // 1. Fetch offer details from Supabase
      const { data: offer, error: fetchError } = await supabase
        .from('offers')
        .select('title, description, required_skills, min_education, offer_type')
        .eq('id', inputData.offerId)
        .single();

      if (fetchError || !offer) {
        console.error("Erreur de récupération de l'offre:", fetchError);
        return { success: false, offerId: inputData.offerId, message: "Offre introuvable" };
      }

      // 2. Build text to embed
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

      // 3. Generate embedding using Gemini
      const { GoogleGenerativeAI } = await import('@google/generative-ai');
      const genAI = new GoogleGenerativeAI(process.env['GOOGLE_GENERATIVE_AI_API_KEY'] ?? '');
      
      const embeddingModel = genAI.getGenerativeModel({ model: 'gemini-embedding-2' });
      const embeddingResult = await embeddingModel.embedContent(offerText);
      const embedding = embeddingResult.embedding.values.slice(0, 1536);

      // 4. Save embedding to Supabase
      const { error: updateError } = await supabase
        .from('offers')
        .update({ embedding })
        .eq('id', inputData.offerId);

      if (updateError) {
        console.error("Erreur d'enregistrement de l'embedding:", updateError);
        return { success: false, offerId: inputData.offerId, message: "Erreur sauvegarde" };
      }

      console.log(`✅ Embedding généré et sauvegardé pour l'offre ${inputData.offerId}`);
      return { success: true, offerId: inputData.offerId, message: "Embedding sauvegardé" };
      
    } catch (error: any) {
      console.error("Erreur inattendue dans embedOfferStep:", error);
      return { success: false, offerId: inputData.offerId, message: error.message };
    }
  },
});

// ─────────────────────────────────────────────
// 2️⃣ STEP: UPDATE MATCHING STUDENTS' FEED
// ─────────────────────────────────────────────
const updateFeedsStep = createStep({
  id: 'update-feeds',
  inputSchema: z.object({
    offerId: z.string().uuid(),
    success: z.boolean(),
  }),
  outputSchema: z.object({
    updatedCount: z.number(),
  }),
  execute: async ({ inputData }) => {
    if (!inputData.success) return { updatedCount: 0 };
    
    try {
      // 1. Fetch offer details and embedding
      const { data: offer } = await supabase
        .from('offers')
        .select('*')
        .eq('id', inputData.offerId)
        .single();
        
      if (!offer || !offer.embedding) return { updatedCount: 0 };
      
      // 2. Match students using new RPC
      const { data: matches, error: matchError } = await supabase.rpc('match_students', {
        query_embedding: offer.embedding,
        match_count: 100
      });
      
      if (matchError || !matches || matches.length === 0) {
         if (matchError) console.error("Erreur match_students:", matchError);
         return { updatedCount: 0 };
      }
      
      const matchIds = matches.map((m: any) => m.id);
      
      // Fetch everything in parallel
      const [
        { data: profiles },
        { data: skills },
        { data: currentCaches }
      ] = await Promise.all([
        supabase.from('student_profiles').select('id, education_level, years_of_experience').in('id', matchIds),
        supabase.from('skills').select('student_id, name, skill_type').in('student_id', matchIds),
        supabase.from('feed_cache').select('student_id, cards').in('student_id', matchIds)
      ]);

      const cacheUpdates = [];
      const now = new Date().toISOString();
      let updated = 0;
      
      for (const match of matches) {
        const profile = (profiles || []).find((p: any) => p.id === match.id);
        const studentSkills = (skills || []).filter((s: any) => s.student_id === match.id);
        
        const studentTechSkills = studentSkills
          .filter((s: any) => s.skill_type === 'technical')
          .map((s: any) => s.name.toLowerCase());
          
        const rawSimilarity = match.similarity ?? 0.0;
        
        const { finalScore, details } = calculateFinalScore(
          studentTechSkills,
          offer.required_skills || [],
          rawSimilarity,
          profile?.years_of_experience || 0,
          offer.years_of_experience ?? null,
          profile?.education_level || '',
          offer.min_education ?? null
        );
        
        const currentCache = (currentCaches || []).find((c: any) => c.student_id === match.id);
        let cards = currentCache?.cards || [];
        cards = cards.filter((c: any) => c.offerId !== offer.id); 
        
        cards.push({
          offerId: offer.id,
          matchScore: finalScore,
          isHighMatch: finalScore >= 70,
          details
        });
        
        cards.sort((a: any, b: any) => b.matchScore - a.matchScore);
        
        cacheUpdates.push({
          student_id: match.id,
          cards: cards,
          generated_at: now
        });
        updated++;
      }
      
      if (cacheUpdates.length > 0) {
        await supabase.from('feed_cache').upsert(cacheUpdates, { onConflict: 'student_id' });
      }
      
      console.log(`✅ Mise à jour du flux pour ${updated} étudiants suite à l'offre ${inputData.offerId}`);
      return { updatedCount: updated };
    } catch (e) {
      console.error("Erreur dans updateFeedsStep:", e);
      return { updatedCount: 0 };
    }
  }
});

// ─────────────────────────────────────────────
// 🚀 WORKFLOW DEFINITION
// ─────────────────────────────────────────────
export const offerPipelineWorkflow = createWorkflow({
  id: 'offer-pipeline',
  inputSchema: z.object({
    offerId: z.string().uuid(),
  }),
  outputSchema: z.object({
    updatedCount: z.number(),
  }),
})
  .then(embedOfferStep)
  .then(updateFeedsStep)
  .commit();

