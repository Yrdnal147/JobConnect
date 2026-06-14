import { createTool } from '@mastra/core/tools';
import { z } from 'zod';
import { supabase } from '../supabase';
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env['GOOGLE_GENERATIVE_AI_API_KEY'] ?? '');

export const embedProfileTool = createTool({
  id: 'embed-profile',
  description: 'Génère un embedding vectoriel du profil étudiant avec Gemini',
  inputSchema: z.object({
    userId: z.string().uuid(),
  }),
  outputSchema: z.object({
    embedding: z.array(z.number()),
    success: z.boolean(),
  }),
  execute: async ({ context }) => {
    try {
      // Récupérer le profil et les compétences
      const { data: profile } = await supabase
        .from('student_profiles')
        .select('*, skills(*)')
        .eq('user_id', context.userId)
        .single();

      if (!profile) throw new Error('Profil introuvable');

      // Construire le texte du profil
      const skills = profile.skills as Array<{ name: string; skill_type: string }>;
      const profileText = `
        Niveau: ${profile.education_level}
        Domaine: ${profile.field_of_study}
        Expérience: ${profile.years_of_experience} ans
        Compétences techniques: ${skills.filter(s => s.skill_type === 'technical').map(s => s.name).join(', ')}
        Soft skills: ${skills.filter(s => s.skill_type === 'soft').map(s => s.name).join(', ')}
        Langues: ${skills.filter(s => s.skill_type === 'language').map(s => s.name).join(', ')}
      `;

      // Générer l'embedding avec Gemini
      const model = genAI.getGenerativeModel({ model: 'text-embedding-004' });
      const result = await model.embedContent(profileText);
      const embedding = result.embedding.values;

      return { embedding, success: true };
    } catch (error) {
      return { embedding: [], success: false };
    }
  },
});

export const vectorSearchTool = createTool({
  id: 'vector-search',
  description: 'Recherche les offres les plus similaires au profil via pgvector',
  inputSchema: z.object({
    embedding: z.array(z.number()),
    limit: z.number().default(10),
  }),
  outputSchema: z.object({
    matches: z.array(z.object({
      id: z.string(),
      title: z.string(),
      company_id: z.string(),
      offer_type: z.string(),
      similarity: z.number(),
    })),
    success: z.boolean(),
  }),
  execute: async ({ context }) => {
    try {
      const { data, error } = await supabase
        .rpc('match_offers', {
          query_embedding: context.embedding,
          match_count: context.limit,
        });

      if (error) throw error;

      return { matches: data ?? [], success: true };
    } catch (error) {
      return { matches: [], success: false };
    }
  },
});

export const saveMatchesTool = createTool({
  id: 'save-matches',
  description: 'Sauvegarde les résultats du matching dans le feed_cache',
  inputSchema: z.object({
    userId: z.string().uuid(),
    cards: z.array(z.object({
      offerId: z.string(),
      companyName: z.string(),
      companyLogo: z.string().nullable(),
      title: z.string(),
      matchScore: z.number(),
      offerType: z.string(),
      location: z.string(),
      postedAt: z.string(),
      isHighMatch: z.boolean(),
    })),
  }),
  outputSchema: z.object({
    success: z.boolean(),
    message: z.string(),
  }),
  execute: async ({ context }) => {
    try {
      const { data: profile } = await supabase
        .from('student_profiles')
        .select('id')
        .eq('user_id', context.userId)
        .single();

      if (!profile) throw new Error('Profil introuvable');

      const { error } = await supabase
        .from('feed_cache')
        .upsert({
          student_id: profile.id,
          cards: context.cards,
          generated_at: new Date().toISOString(),
        });

      if (error) throw error;

      return { success: true, message: 'Feed sauvegardé avec succès' };
    } catch (error) {
      return { success: false, message: `Erreur : ${error}` };
    }
  },
});