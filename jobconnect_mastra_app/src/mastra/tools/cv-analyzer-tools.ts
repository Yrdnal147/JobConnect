import { createTool } from '@mastra/core/tools';
import { z } from 'zod';
import { supabase } from '../supabase';

export const saveProfileTool = createTool({
  id: 'save-profile',
  description: 'Sauvegarde le résultat de l analyse du CV dans Supabase',
  inputSchema: z.object({
    userId: z.string().uuid(),
    technicalSkills: z.array(z.string()),
    softSkills: z.array(z.string()),
    languages: z.array(z.object({
      name: z.string(),
      level: z.string(),
    })),
    educationLevel: z.string(),
    fieldOfStudy: z.string(),
    yearsOfExperience: z.number(),
    profileScore: z.number().min(0).max(100),
    completionLabel: z.string(),
    suggestions: z.array(z.object({
      priority: z.string(),
      message: z.string(),
    })).optional(),
    projects: z.array(z.string()).optional(),
  }),
  outputSchema: z.object({
    success: z.boolean(),
    message: z.string(),
  }),
  execute: async ({ context: inputData }) => {
    try {
      // Mise à jour du profil étudiant
      const { error: profileError } = await supabase
        .from('student_profiles')
        .update({
          education_level: inputData.educationLevel,
          field_of_study: inputData.fieldOfStudy,
          years_of_experience: inputData.yearsOfExperience,
          profile_score: inputData.profileScore,
          completion_label: inputData.completionLabel,
        })
        .eq('user_id', inputData.userId);

      if (profileError) throw profileError;

      if (inputData.suggestions && inputData.suggestions.length > 0) {
        const suggestionsToInsert = inputData.suggestions.map((s: any) => ({
          user_id: inputData.userId,
          priority: s.priority,
          message: s.message
        }));
        
        await supabase
          .from('profile_suggestions')
          .delete()
          .eq('user_id', inputData.userId);

        await supabase
          .from('profile_suggestions')
          .insert(suggestionsToInsert);
      }

      if (inputData.projects && inputData.projects.length > 0) {
        const projectsToInsert = inputData.projects.map((title: string) => ({
          student_id: inputData.userId,
          title: title,
          description: "Généré par analyse IA"
        }));
        
        await supabase
          .from('projects')
          .delete()
          .eq('student_id', inputData.userId);

        await supabase
          .from('projects')
          .insert(projectsToInsert);
      }

      // Supprimer les anciennes compétences
      await supabase
        .from('skills')
        .delete()
        .eq('user_id', inputData.userId);

      // Préparer les compétences
      const skillsToInsert = [
        ...(inputData.technicalSkills || []).map((skill: string) => ({
          user_id: inputData.userId,
          name: skill,
          skill_type: 'technical'
        })),
        ...(inputData.softSkills || []).map((skill: string) => ({
          user_id: inputData.userId,
          name: skill,
          skill_type: 'soft'
        })),
        ...(inputData.languages || []).map((lang: any) => ({
          user_id: inputData.userId,
          name: lang.name,
          skill_type: 'language',
          level: lang.level
        }))
      ];

      if (skillsToInsert.length > 0) {
        const { error: skillsError } = await supabase
          .from('skills')
          .insert(skillsToInsert);

        if (skillsError) throw skillsError;
      }

      return {
        success: true,
        message: 'Profil sauvegardé avec succès',
      };
    } catch (error) {
      return {
        success: false,
        message: `Erreur lors de la sauvegarde : ${error}`,
      };
    }
  },
});
