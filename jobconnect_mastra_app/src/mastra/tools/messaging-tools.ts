import { createTool } from '@mastra/core/tools';
import { z } from 'zod';
import { supabase } from '../supabase';

export const getConversationHistoryTool = createTool({
  id: 'get-conversation-history',
  description: 'Récupère les 10 derniers messages d une conversation',
  inputSchema: z.object({
    conversationId: z.string().uuid(),
  }),
  outputSchema: z.object({
    messages: z.array(z.object({
      id: z.string(),
      sender_id: z.string(),
      content: z.string(),
      created_at: z.string(),
    })),
    success: z.boolean(),
  }),
  execute: async ({ context: inputData }) => {
    try {
      const { data, error } = await supabase
        .from('messages')
        .select('id, sender_id, content, created_at')
        .eq('conversation_id', inputData.conversationId)
        .order('created_at', { ascending: false })
        .limit(10);

      if (error) throw error;

      return { messages: data ?? [], success: true };
    } catch (error) {
      return { messages: [], success: false };
    }
  },
});

export const getSenderProfileTool = createTool({
  id: 'get-sender-profile',
  description: 'Récupère le profil de l expéditeur pour contextualiser les suggestions',
  inputSchema: z.object({
    userId: z.string().uuid(),
    role: z.enum(['student', 'company']),
  }),
  outputSchema: z.object({
    name: z.string().nullable(),
    context: z.string().nullable(),
    success: z.boolean(),
  }),
  execute: async ({ context: inputData }) => {
    try {
      if (inputData.role === 'student') {
        const { data, error } = await supabase
          .from('student_profiles')
          .select('full_name, field_of_study, education_level')
          .eq('user_id', inputData.userId)
          .single();

        if (error) throw error;

        return {
          name: data?.full_name ?? null,
          context: `Étudiant en ${data?.field_of_study} - ${data?.education_level}`,
          success: true,
        };
      } else {
        const { data, error } = await supabase
          .from('companies')
          .select('name, sector')
          .eq('user_id', inputData.userId)
          .single();

        if (error) throw error;

        return {
          name: data?.name ?? null,
          context: `Entreprise dans le secteur ${data?.sector}`,
          success: true,
        };
      }
    } catch (error) {
      return { name: null, context: null, success: false };
    }
  },
});
