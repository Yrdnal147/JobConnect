import { createWorkflow, createStep } from '@mastra/core/workflows';
import { z } from 'zod';
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env['GOOGLE_GENERATIVE_AI_API_KEY'] ?? '');

const optimizeOfferStep = createStep({
  id: 'optimize-offer',
  inputSchema: z.object({
    offerId: z.string().uuid(),
    title: z.string(),
    description: z.string(),
    requiredSkills: z.array(z.string()),
    offerType: z.string(),
    companyName: z.string(),
  }),
  outputSchema: z.object({
    qualityScore: z.number(),
    shouldPublish: z.boolean(),
    suggestions: z.array(z.string()),
  }),
  execute: async ({ inputData, mastra }: { inputData: any, mastra: any }) => {
    const agent = mastra.getAgent('offer-optimizer-agent');
    const result = await agent.generate(
      `Analyse la qualité de cette offre avant publication :
       Titre: ${inputData.title}
       Entreprise: ${inputData.companyName}
       Type: ${inputData.offerType}
       Compétences requises: ${inputData.requiredSkills.join(', ')}
       Description: ${inputData.description}`,
    );

    try {
      const parsed = JSON.parse(result.text);
      return {
        qualityScore: parsed.qualityScore ?? 0,
        shouldPublish: (parsed.qualityScore ?? 0) >= 50,
        suggestions: parsed.improvements?.map((i: any) => i.message) ?? [],
      };
    } catch {
      return { qualityScore: 0, shouldPublish: true, suggestions: [] };
    }
  },
});

const generateEmbeddingStep = createStep({
  id: 'generate-embedding',
  inputSchema: z.object({
    offerId: z.string().uuid(),
    title: z.string(),
    description: z.string(),
    requiredSkills: z.array(z.string()),
    offerType: z.string(),
    companyName: z.string(),
    qualityScore: z.number(),
    shouldPublish: z.boolean(),
    suggestions: z.array(z.string()),
  }),
  outputSchema: z.object({
    embeddingGenerated: z.boolean(),
  }),
  execute: async ({ inputData }: { inputData: any }) => {
    try {
      const offerText = `
        ${inputData.title}
        ${inputData.companyName}
        ${inputData.offerType}
        ${inputData.requiredSkills.join(' ')}
        ${inputData.description}
      `;

      const model = genAI.getGenerativeModel({ model: 'gemini-embedding-2' });
      const result = await model.embedContent(offerText);
      const embedding = result.embedding.values.slice(0, 1536);

      const { supabase } = await import('../supabase.js');
      const { error } = await supabase
        .from('offers')
        .update({ embedding })
        .eq('id', inputData.offerId);

      if (error) throw error;

      return { embeddingGenerated: true };
    } catch {
      return { embeddingGenerated: false };
    }
  },
});

const notifyMatchingStudentsStep = createStep({
  id: 'notify-matching-students',
  inputSchema: z.object({
    offerId: z.string().uuid(),
    title: z.string(),
    description: z.string(),
    requiredSkills: z.array(z.string()),
    offerType: z.string(),
    companyName: z.string(),
    qualityScore: z.number(),
    shouldPublish: z.boolean(),
    suggestions: z.array(z.string()),
    embeddingGenerated: z.boolean(),
  }),
  outputSchema: z.object({
    notifiedCount: z.number(),
  }),
  execute: async ({ inputData }: { inputData: any }) => {
    try {
      if (!inputData.embeddingGenerated) return { notifiedCount: 0 };

      const { supabase } = await import('../supabase.js');

      // Récupérer les étudiants avec un profil complet (score >= 50)
      const { data: students } = await supabase
        .from('student_profiles')
        .select('id, user_id')
        .gte('profile_score', 50);

      if (!students || students.length === 0) return { notifiedCount: 0 };

      // Créer une notification pour chaque étudiant correspondant
      const notifications = students.map((student: any) => ({
        user_id: student.user_id,
        type: 'match',
        title: 'Nouvelle offre correspondant à votre profil',
        body: `${inputData.companyName} a publié : ${inputData.title}`,
        data: { offerId: inputData.offerId },
      }));

      const { error } = await supabase
        .from('notifications')
        .insert(notifications);

      if (error) throw error;

      return { notifiedCount: notifications.length };
    } catch {
      return { notifiedCount: 0 };
    }
  },
});

export const offerPublishedWorkflow = createWorkflow({
  id: 'offer-published',
  inputSchema: z.object({
    offerId: z.string().uuid(),
    title: z.string(),
    description: z.string(),
    requiredSkills: z.array(z.string()),
    offerType: z.string(),
    companyName: z.string(),
  }),
  outputSchema: z.object({
    qualityScore: z.number(),
    shouldPublish: z.boolean(),
    suggestions: z.array(z.string()),
    embeddingGenerated: z.boolean(),
    notifiedCount: z.number(),
  }),
})
  .then(optimizeOfferStep)
  .then(generateEmbeddingStep)
  .then(notifyMatchingStudentsStep)
  .commit();