import { createTool } from '@mastra/core/tools';
import { string, z } from 'zod';
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
  }),
  outputSchema: z.object({
    success: z.boolean(),
    message: z.string(),
  }),
  execute: async ({ context }) => {
    try {
      // Mise à jour du profil étudiant
      const { error: profileError } = await supabase
        .from('student_profiles')
        .update({
          education_level: context.educationLevel,
          field_of_study: context.fieldOfStudy,
          years_of_experience: context.yearsOfExperience,
          profile_score: context.profileScore,
          completion_label: context.completionLabel,
        })
        .eq('user_id', context.userId);

      if (profileError) throw profileError;

      // Récupérer l'id du profil étudiant
      const { data: profile, error: fetchError } = await supabase
        .from('student_profiles')
        .select('id')
        .eq('user_id', context.userId)
        .single();

      if (fetchError) throw fetchError;

      // Supprimer les anciennes compétences
      await supabase
        .from('skills')
        .delete()
        .eq('student_id', profile.id);

      // Insérer les nouvelles compétences techniques
      const technicalSkills = context.technicalSkills.map((skill: string) => ({
        student_id: profile.id,
        name: skill,
        skill_type: 'technical',
      }));

      // Insérer les soft skills
      const softSkills = context.softSkills.map((skill: string) => ({
        student_id: profile.id,
        name: skill,
        skill_type: 'soft',
      }));

      // Insérer les langues
      const languages = context.languages.map((lang: { name: string; level: string }) => ({
        student_id: profile.id,
        name: lang.name,
        skill_type: 'language',
        level: lang.level,
      }));

      const allSkills = [...technicalSkills, ...softSkills, ...languages];

      if (allSkills.length > 0) {
        const { error: skillsError } = await supabase
          .from('skills')
          .insert(allSkills);

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