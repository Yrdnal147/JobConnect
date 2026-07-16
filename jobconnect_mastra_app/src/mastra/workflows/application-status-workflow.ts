import { createWorkflow, createStep } from '@mastra/core/workflows';
import { z } from 'zod';
import { randomUUID } from 'crypto';

function extractJSON(text: string): any {
  if (!text) return {};
  try { return JSON.parse(text); } catch {}
  
  const blockMatch = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  if (blockMatch && blockMatch[1]) {
    try { return JSON.parse(blockMatch[1]); } catch {}
  }
  
  let startIndex = text.indexOf('{');
  if (startIndex !== -1) {
    let braceCount = 0;
    let inString = false;
    let escape = false;
    for (let i = startIndex; i < text.length; i++) {
      const char = text[i];
      if (escape) { escape = false; continue; }
      if (char === '\\') { escape = true; continue; }
      if (char === '"') { inString = !inString; continue; }
      if (!inString) {
        if (char === '{') braceCount++;
        else if (char === '}') braceCount--;
        
        if (braceCount === 0) {
          try { return JSON.parse(text.substring(startIndex, i + 1)); } catch (e) { break; }
        }
      }
    }
  }
  
  console.error('JSON parse error:', text);
  return {};
}

const handleRefusedStep = createStep({
  id: 'handle-refused',
  inputSchema: z.object({
    applicationId: z.string().uuid(),
    studentId: z.string().uuid(),
    offerId: z.string().uuid(),
    status: z.enum(['pending', 'refused', 'retained']),
  }),
  outputSchema: z.object({
    message: z.string(),
    actions: z.array(z.string()),
    nextStep: z.string(),
  }),
  execute: async ({ inputData, mastra }: { inputData: any, mastra: any }) => {
    if (inputData.status !== 'refused') {
      return { message: '', actions: [], nextStep: '' };
    }

    const { supabase } = await import('../supabase');
    const { data: offer } = await supabase
      .from('offers')
      .select('title, companies(name)')
      .eq('id', inputData.offerId)
      .single();
    const offerTitle = offer?.title ?? 'Candidature';
    const companyName = offer?.companies?.name ?? 'l\'entreprise';

    const cvAgent = mastra.getAgent('cv-analyzer-agent');
    const gapResult = await cvAgent.generate(
      `Re-analyse les écarts entre le profil étudiant userId: ${inputData.studentId} 
       et l'offre refusée: "${offerTitle}" chez ${companyName} (offerId: ${inputData.offerId}).
       Explique pourquoi le candidat a probablement été refusé.`,
    );

    const careerAgent = mastra.getAgent('career-status-agent');
    const result = await careerAgent.generate(
      `Le candidat userId: ${inputData.studentId} a été REFUSÉ pour l'offre "${offerTitle}" chez ${companyName}.
       Analyse des écarts : ${gapResult.text}
       Génère un message empathique expliquant brièvement ces écarts comme motif de refus (sans inventer d'autres raisons), et propose 3 actions d'amélioration.
       applicationId: ${inputData.applicationId}`,
    );

    const parsed = extractJSON(result.text);

    // Créer la notification (Bypass RLS car on est sur le backend)
    try {
      await supabase.from('notifications').insert({
        id: randomUUID(),
        user_id: inputData.studentId,
        type: 'application_refused',
        title: 'Candidature non retenue',
        body: `Votre candidature pour le poste de ${offerTitle} chez ${companyName} n'a pas été retenue cette fois.`,
        data: { applicationId: inputData.applicationId, offerId: inputData.offerId },
        is_read: false,
        created_at: new Date().toISOString()
      });
    } catch (err) {
      console.error('Erreur insert notification:', err);
    }

    await supabase.from('applications').update({
      status_explanation: JSON.stringify({
        message: parsed.message ?? '',
        actions: parsed.actions ?? [],
        nextStep: parsed.nextStep ?? ''
      })
    }).eq('id', inputData.applicationId);

    return {
      message: parsed.message ?? '',
      actions: parsed.actions?.map((a: any) => a.message) ?? [],
      nextStep: parsed.nextStep ?? '',
    };
  },
});

const handlePendingStep = createStep({
  id: 'handle-pending',
  inputSchema: z.object({
    applicationId: z.string().uuid(),
    studentId: z.string().uuid(),
    offerId: z.string().uuid(),
    status: z.enum(['pending', 'refused', 'retained']),
  }),
  outputSchema: z.object({
    message: z.string(),
    similarOffers: z.array(z.string()),
    nextStep: z.string(),
  }),
  execute: async ({ inputData, mastra }: { inputData: any, mastra: any }) => {
    if (inputData.status !== 'pending') {
      return { message: '', similarOffers: [], nextStep: '' };
    }

    const { supabase } = await import('../supabase');
    const { data: offer } = await supabase
      .from('offers')
      .select('title, companies(name, user_id)')
      .eq('id', inputData.offerId)
      .single();
    const offerTitle = offer?.title ?? 'Candidature';
    const companyName = offer?.companies?.name ?? 'l\'entreprise';
    const companyUserId = offer?.companies?.user_id;

    if (companyUserId) {
      try {
        await supabase.from('notifications').insert({
          id: randomUUID(),
          user_id: companyUserId,
          type: 'application_received',
          title: 'Nouvelle candidature',
          body: `Un candidat a postulé à votre offre "${offerTitle}".`,
          data: { applicationId: inputData.applicationId, offerId: inputData.offerId },
          is_read: false,
          created_at: new Date().toISOString()
        });
      } catch (err) {
        console.error('Erreur insert notification company:', err);
      }
    }

    const recoAgent = mastra.getAgent('recommendation-agent');
    const similarResult = await recoAgent.generate(
      `Trouve 3 offres similaires actives pour le candidat userId: ${inputData.studentId}
       qui a postulé à l'offre "${offerTitle}" chez ${companyName} (candidature en attente).`,
    );

    const careerAgent = mastra.getAgent('career-status-agent');
    const result = await careerAgent.generate(
      `La candidature pour l'offre "${offerTitle}" chez ${companyName} est EN ATTENTE.
       Offres similaires trouvées : ${similarResult.text}
       Génère un message encourageant avec ces alternatives.
       applicationId: ${inputData.applicationId}`,
    );

    const parsed = extractJSON(result.text);

    await supabase.from('applications').update({
      status_explanation: JSON.stringify({
        message: parsed.message ?? '',
        similarOffers: parsed.actions?.map((a: any) => a.message || a) ?? [],
        nextStep: parsed.nextStep ?? ''
      })
    }).eq('id', inputData.applicationId);

    return {
      message: parsed.message ?? '',
      similarOffers: parsed.actions?.map((a: any) => a.message) ?? [],
      nextStep: parsed.nextStep ?? '',
    };
  },
});

const handleRetainedStep = createStep({
  id: 'handle-retained',
  inputSchema: z.object({
    applicationId: z.string().uuid(),
    studentId: z.string().uuid(),
    offerId: z.string().uuid(),
    status: z.enum(['pending', 'refused', 'retained']),
  }),
  outputSchema: z.object({
    message: z.string(),
    nextStep: z.string(),
  }),
  execute: async ({ inputData, mastra }: { inputData: any, mastra: any }) => {
    if (inputData.status !== 'retained') {
      return { message: '', nextStep: '' };
    }

    const { supabase } = await import('../supabase');
    const { data: offer } = await supabase
      .from('offers')
      .select('title, companies(name)')
      .eq('id', inputData.offerId)
      .single();
    const offerTitle = offer?.title ?? 'Candidature';
    const companyName = offer?.companies?.name ?? 'l\'entreprise';

    const careerAgent = mastra.getAgent('career-status-agent');
    const result = await careerAgent.generate(
      `Le candidat userId: ${inputData.studentId} a été RETENU pour l'offre "${offerTitle}" chez ${companyName}.
       Génère un message de félicitations avec conseils pour le premier message. 
       REMPLACE explicitement tout espace réservé comme {offerName} par le vrai nom: "${offerTitle}". N'utilise aucune accolade.
       applicationId: ${inputData.applicationId}`,
    );

    // Créer la notification
    try {
      await supabase.from('notifications').insert({
        id: randomUUID(),
        user_id: inputData.studentId,
        type: 'application_retained',
        title: 'Félicitations ! Votre profil a été retenu',
        body: `L'entreprise ${companyName} a retenu votre candidature pour le poste de ${offerTitle}.`,
        data: { applicationId: inputData.applicationId, offerId: inputData.offerId },
        is_read: false,
        created_at: new Date().toISOString()
      });
    } catch (err) {
      console.error('Erreur insert notification:', err);
    }

    const parsed = extractJSON(result.text);

    await supabase.from('applications').update({
      status_explanation: JSON.stringify({
        message: parsed.message ?? '',
        actions: parsed.actions ?? [],
        nextStep: parsed.nextStep ?? ''
      })
    }).eq('id', inputData.applicationId);

    return {
      message: parsed.message ?? '',
      nextStep: parsed.nextStep ?? '',
    };
  },
});

export const applicationStatusWorkflow = createWorkflow({
  id: 'application-status-handler',
  inputSchema: z.object({
    applicationId: z.string().uuid(),
    studentId: z.string().uuid(),
    offerId: z.string().uuid(),
    status: z.enum(['pending', 'refused', 'retained']),
  }),
  outputSchema: z.object({
    message: z.string(),
    actions: z.array(z.string()),
    nextStep: z.string(),
  }),
})
  .parallel([handleRefusedStep, handlePendingStep, handleRetainedStep])
  .commit();