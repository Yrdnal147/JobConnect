import { createWorkflow, createStep } from '@mastra/core/workflows';
import { z } from 'zod';

const saveMessageStep = createStep({
  id: 'save-message',
  inputSchema: z.object({
    conversationId: z.string().uuid(),
    senderId: z.string().uuid(),
    content: z.string(),
  }),
  outputSchema: z.object({
    messageId: z.string(),
    success: z.boolean(),
  }),
  execute: async ({ inputData }: { inputData: any }) => {
    const { supabase } = await import('../supabase');
    const { data, error } = await supabase
      .from('messages')
      .insert({
        conversation_id: inputData.conversationId,
        sender_id: inputData.senderId,
        content: inputData.content,
      })
      .select('id')
      .single();

    if (error) return { messageId: '', success: false };
    return { messageId: data.id, success: true };
  },
});

const generateSuggestionsStep = createStep({
  id: 'generate-suggestions',
  inputSchema: z.object({
    conversationId: z.string().uuid(),
    senderId: z.string().uuid(),
    content: z.string(),
  }),
  outputSchema: z.object({
    suggestions: z.array(z.object({
      tone: z.string(),
      message: z.string(),
    })),
  }),
  execute: async ({ inputData, mastra }: { inputData: any, mastra: any }) => {
    const agent = mastra.getAgent('message-assistant-agent');
    const result = await agent.generate(
      `Génère 3 suggestions de réponse pour ce message reçu dans la conversation ${inputData.conversationId}.
       Dernier message : "${inputData.content}"
       Expéditeur userId: ${inputData.senderId}`,
    );

    try {
      const parsed = JSON.parse(result.text);
      return { suggestions: parsed.suggestions ?? [] };
    } catch {
      return { suggestions: [] };
    }
  },
});

export const newMessageWorkflow = createWorkflow({
  id: 'new-message',
  inputSchema: z.object({
    conversationId: z.string().uuid(),
    senderId: z.string().uuid(),
    content: z.string(),
  }),
  outputSchema: z.object({
    messageId: z.string(),
    success: z.boolean(),
    suggestions: z.array(z.object({
      tone: z.string(),
      message: z.string(),
    })),
  }),
})
  .parallel([saveMessageStep, generateSuggestionsStep])
  .commit();