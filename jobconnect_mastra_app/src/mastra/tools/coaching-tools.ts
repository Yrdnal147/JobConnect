import { createTool } from '@mastra/core/tools';
import { z } from 'zod';
import { supabase } from '../supabase';

export const getOfferDetailsTool = createTool({
  id: 'get-offer-details',
  description: 'Récupère les détails d une offre d emploi depuis Supabase',
  inputSchema: z.object({
    offerId: z.string().uuid(),
  }),
  outputSchema: z.object({
    offer: z.object({
      id: z.string(),
      title: z.string(),
      description: z.string(),
      required_skills: z.array(z.string()),
      min_education: z.string().nullable(),
      offer_type: z.string(),
      location: z.string(),
    }).nullable(),
    success: z.boolean(),
  }),
  execute: async ({ context }) => {
    try {
      const { data, error } = await supabase
        .from('offers')
        .select('id, title, description, required_skills, min_education, offer_type, location')
        .eq('id', context.offerId)
        .single();

      if (error) throw error;

      return { offer: data, success: true };
    } catch (error) {
      return { offer: null, success: false };
    }
  },
});

export const getStudentProfileTool = createTool({
  id: 'get-student-profile',
  description: 'Récupère le profil complet d un étudiant depuis Supabase',
  inputSchema: z.object({
    userId: z.string().uuid(),
  }),
  outputSchema: z.object({
    profile: z.object({
      id: z.string(),
      full_name: z.string().nullable(),
      education_level: z.string().nullable(),
      field_of_study: z.string().nullable(),
      years_of_experience: z.number(),
      profile_score: z.number(),
      skills: z.array(z.object({
        name: z.string(),
        skill_type: z.string(),
        level: z.string().nullable(),
      })),
    }).nullable(),
    success: z.boolean(),
  }),
  execute: async ({ context }) => {
    try {
      const { data, error } = await supabase
        .from('student_profiles')
        .select('id, full_name, education_level, field_of_study, years_of_experience, profile_score, skills(*)')
        .eq('user_id', context.userId)
        .single();

      if (error) throw error;

      return { profile: data, success: true };
    } catch (error) {
      return { profile: null, success: false };
    }
  },
});

export const saveCoachSuggestionTool = createTool({
  id: 'save-coach-suggestion',
  description: 'Sauvegarde la suggestion du coach dans la candidature',
  inputSchema: z.object({
    applicationId: z.string().uuid(),
    coachSuggestion: z.string(),
  }),
  outputSchema: z.object({
    success: z.boolean(),
    message: z.string(),
  }),
  execute: async ({ context }) => {
    try {
      const { error } = await supabase
        .from('applications')
        .update({ coach_suggestion: context.coachSuggestion })
        .eq('id', context.applicationId);

      if (error) throw error;

      return { success: true, message: 'Suggestion sauvegardée' };
    } catch (error) {
      return { success: false, message: `Erreur : ${error}` };
    }
  },
});

export const saveStatusExplanationTool = createTool({
  id: 'save-status-explanation',
  description: 'Sauvegarde l explication du statut dans la candidature',
  inputSchema: z.object({
    applicationId: z.string().uuid(),
    statusExplanation: z.string(),
  }),
  outputSchema: z.object({
    success: z.boolean(),
    message: z.string(),
  }),
  execute: async ({ context }) => {
    try {
      const { error } = await supabase
        .from('applications')
        .update({ status_explanation: context.statusExplanation })
        .eq('id', context.applicationId);

      if (error) throw error;

      return { success: true, message: 'Explication sauvegardée' };
    } catch (error) {
      return { success: false, message: `Erreur : ${error}` };
    }
  },
});

export const createNotificationTool = createTool({
  id: 'create-notification',
  description: 'Crée une notification pour un utilisateur',
  inputSchema: z.object({
    userId: z.string().uuid(),
    type: z.enum(['match', 'retained', 'refused', 'message']),
    title: z.string(),
    body: z.string(),
    data: z.record(z.string(), z.unknown()).optional(),
  }),
  outputSchema: z.object({
    success: z.boolean(),
    message: z.string(),
  }),
  execute: async ({ context }) => {
    try {
      const { error } = await supabase
        .from('notifications')
        .insert({
          user_id: context.userId,
          type: context.type,
          title: context.title,
          body: context.body,
          data: context.data ?? {},
        });

      if (error) throw error;

      return { success: true, message: 'Notification créée' };
    } catch (error) {
      return { success: false, message: `Erreur : ${error}` };
    }
  },
});