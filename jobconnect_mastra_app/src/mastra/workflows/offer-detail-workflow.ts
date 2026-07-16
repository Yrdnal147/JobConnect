import { createWorkflow, createStep } from '@mastra/core/workflows';
import { z } from 'zod';

const coachAnalysisStep = createStep({
  id: 'coach-analysis',
  inputSchema: z.object({
    offerId: z.string().uuid(),
    userId: z.string().uuid(),
  }),
  outputSchema: z.object({
    matchingSkills: z.array(z.string()),
    missingSkills: z.array(z.string()),
    matchPercent: z.number(),
    suggestions: z.array(z.string()),
  }),
  execute: async ({ inputData, mastra }: { inputData: any, mastra: any }) => {
    const agent = mastra.getAgent('application-coach-agent');
    const result = await agent.generate(
      `Analyse l'écart entre le profil du candidat userId: ${inputData.userId} 
       et l'offre offerId: ${inputData.offerId}`,
    );
    const parsed = JSON.parse(result.text);
    return {
      matchingSkills: parsed.matchingSkills ?? [],
      missingSkills: parsed.missingSkills ?? [],
      matchPercent: parsed.matchPercent ?? 0,
      suggestions: parsed.suggestions?.map((s: any) => s.action) ?? [],
    };
  },
});

const fetchCompanyLocationStep = createStep({
  id: 'fetch-company-location',
  inputSchema: z.object({
    offerId: z.string().uuid(),
    userId: z.string().uuid(),
  }),
  outputSchema: z.object({
    latitude: z.number(),
    longitude: z.number(),
    location: z.string(),
  }),
  execute: async ({ inputData }: { inputData: any }) => {
    const { supabase } = await import('../supabase.js');
    const { data } = await supabase
      .from('offers')
      .select('location, companies(latitude, longitude, location)')
      .eq('id', inputData.offerId)
      .single();

    const company = data?.companies as any;
    return {
      latitude: company?.latitude ?? 4.0511,
      longitude: company?.longitude ?? 9.7679,
      location: company?.location ?? 'Douala',
    };
  },
});

const prepareNotificationStep = createStep({
  id: 'prepare-notification',
  inputSchema: z.object({
    offerId: z.string().uuid(),
    userId: z.string().uuid(),
  }),
  outputSchema: z.object({
    shouldNotify: z.boolean(),
    message: z.string(),
  }),
  execute: async ({ inputData }: { inputData: any }) => {
    const { supabase } = await import('../supabase.js');

    // Vérifie si l'étudiant a déjà postulé à cette offre
    const { data: profile } = await supabase
      .from('student_profiles')
      .select('id')
      .eq('user_id', inputData.userId)
      .single();

    if (!profile) return { shouldNotify: false, message: '' };

    const { data: existing } = await supabase
      .from('applications')
      .select('id')
      .eq('student_id', profile.id)
      .eq('offer_id', inputData.offerId)
      .single();

    return {
      shouldNotify: !existing,
      message: existing
        ? 'Vous avez déjà postulé à cette offre'
        : 'Cette offre correspond à votre profil',
    };
  },
});
export const offerDetailWorkflow = createWorkflow({
  id: 'offer-detail-load',
  inputSchema: z.object({
    offerId: z.string().uuid(),
    userId: z.string().uuid(),
  }),
  outputSchema: z.object({
    coachAnalysis: z.object({
      matchingSkills: z.array(z.string()),
      missingSkills: z.array(z.string()),
      matchPercent: z.number(),
      suggestions: z.array(z.string()),
    }),
    companyLocation: z.object({
      latitude: z.number(),
      longitude: z.number(),
      location: z.string(),
    }),
    notification: z.object({
      shouldNotify: z.boolean(),
      message: z.string(),
    }),
  }),
})
  .parallel([coachAnalysisStep, fetchCompanyLocationStep, prepareNotificationStep])
  .commit();