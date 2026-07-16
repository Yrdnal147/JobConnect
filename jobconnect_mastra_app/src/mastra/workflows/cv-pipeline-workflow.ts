import { createStep, createWorkflow } from '@mastra/core/workflows';
import { z } from 'zod';
import { extractText, getDocumentProxy } from 'unpdf';
import { supabase } from '../supabase.js';
import { calculateFinalScore } from '../utils/scoring.js';

// ─────────────────────────────────────────────
// 🔧 UTIL: JSON extraction robuste
// ─────────────────────────────────────────────
function extractJSON(text: string): any {
  if (!text) return {};

  try {
    return JSON.parse(text);
  } catch {}

  try {
    const match = text.match(/\{(?:[^{}]|(?:\{[^{}]*\}))*\}/);
    if (!match) return {};
    return JSON.parse(match[0]);
  } catch (e) {
    console.error('JSON parse error:', text);
    return {};
  }
}

// ─────────────────────────────────────────────
// 🔧 SAFE AGENT GETTER
// ─────────────────────────────────────────────
function getAgentSafe(mastra: any, id: string) {
  const agent = mastra?.getAgent?.(id);
  if (!agent) {
    throw new Error(`Agent introuvable: ${id}`);
  }
  return agent;
}

// ─────────────────────────────────────────────
// 1️⃣ STEP: DOWNLOAD + EXTRACT CV
// ─────────────────────────────────────────────
const downloadCvStep = createStep({
  id: 'download-cv',

  inputSchema: z.object({
    cvUrl: z.string().url(),
    userId: z.string().uuid(),
    targetOpportunity: z.enum([
      'full-time',
      'internship',
      'academic-internship',
      'freelance',
    ]),
  }),

  outputSchema: z.object({
    cvText: z.string(),
    userId: z.string(),
    targetOpportunity: z.enum([
      'full-time',
      'internship',
      'academic-internship',
      'freelance',
    ]),
  }),

  execute: async ({ inputData }) => {
    try {
      const urlObj = new URL(inputData.cvUrl);
      urlObj.searchParams.set('cb', Date.now().toString());
      const response = await fetch(urlObj.toString());
      const buffer = await response.arrayBuffer();

      const pdf = await getDocumentProxy(new Uint8Array(buffer));
      const { text } = await extractText(pdf, { mergePages: true });

      return {
        cvText: text?.trim() || '',
        userId: inputData.userId,
        targetOpportunity: inputData.targetOpportunity,
      };
    } catch (error) {
      return {
        cvText: '',
        userId: inputData.userId,
        targetOpportunity: inputData.targetOpportunity,
      };
    }
  },
});

// ─────────────────────────────────────────────
// 2️⃣ STEP: CV ANALYSIS (IA)
// ─────────────────────────────────────────────
const analyzeCvStep = createStep({
  id: 'analyze-cv',

  inputSchema: z.object({
    cvText: z.string(),
    userId: z.string(),
    targetOpportunity: z.enum([
      'full-time',
      'internship',
      'academic-internship',
      'freelance',
    ]),
    educationLevel: z.enum(['bac', 'bac+2', 'bac+3', 'bac+4', 'bac+5', 'doctorat', '']).optional(),
  }),

  outputSchema: z.object({
    profileScore: z.number(),
    completionLabel: z.string(),
    technicalSkills: z.array(z.string()),
    userId: z.string(),
    targetOpportunity: z.enum([
      'full-time',
      'internship',
      'academic-internship',
      'freelance',
    ]),
  }),

  execute: async ({ inputData, mastra }) => {
    const agent = getAgentSafe(mastra, 'cv-analyzer-agent');

    const result = await agent.generate(
      `
Return ONLY valid JSON.

CV:
${inputData.cvText}

RÈGLE STRICTE: Pour educationLevel, tu DOIS obligatoirement choisir l'une de ces valeurs exactes (ou une chaîne vide ""):
'bac', 'bac+2', 'bac+3', 'bac+4', 'bac+5', 'doctorat'
Par exemple, "Master 2" = "bac+5", "Licence" = "bac+3", "BTS" = "bac+2". Ne renvoie jamais autre chose.

IMPORTANT: Tu dois extraire TOUTES les compétences techniques mentionnées dans le CV (langages de programmation, frameworks, bases de données, outils logiciels, etc.). Sois exhaustif !

Format STRICT:
{
  "technicalSkills": ["skill1", "skill2"],
  "softSkills": ["skill1"],
  "languages": [{"name": "Français", "level": "natif"}],
  "educationLevel": "bac+5",
  "fieldOfStudy": "Informatique",
  "yearsOfExperience": 2,
  "profileScore": 75,
  "completionLabel": "Bon profil",
  "suggestions": [{"priority": "high", "message": "Ajoutez vos projets"}],
  "projects": ["Projet 1"]
}
      `
    );

    const parsed = extractJSON(result.text);

    // ── Sauvegarder dans Supabase ──
    try {
      // 1. Mise à jour du profil et récupération de l'ID
      const { data: updateData, error: updateError } = await supabase
        .from('student_profiles')
        .update({
          education_level: (parsed.educationLevel && parsed.educationLevel !== '') ? parsed.educationLevel : null,
          field_of_study: parsed.fieldOfStudy ?? '',
          years_of_experience: Number(parsed.yearsOfExperience || 0),
          profile_score: Number(parsed.profileScore || 0),
          completion_label: parsed.completionLabel ?? 'Faible',
        })
        .eq('user_id', inputData.userId)
        .select('id');

      if (updateError) {
        console.error('⚠️ [CRITICAL] Update student_profiles a échoué:', updateError);
      }

      const profile = updateData && updateData.length > 0 ? updateData[0] : null;

      if (profile) {
        // 2. Supprimer les anciennes compétences puis insérer les nouvelles
        await supabase.from('skills').delete().eq('student_id', profile.id);

        const skillsToInsert = [
          ...(parsed.technicalSkills || []).map((s: string) => ({
            student_id: profile.id, name: s, skill_type: 'technical',
          })),
          ...(parsed.softSkills || []).map((s: string) => ({
            student_id: profile.id, name: s, skill_type: 'soft',
          })),
          ...(parsed.languages || []).map((l: { name: string; level: string }) => ({
            student_id: profile.id, name: l.name, skill_type: 'language', level: l.level,
          })),
        ];
        if (skillsToInsert.length > 0) {
          await supabase.from('skills').insert(skillsToInsert);
        }
      }

      // 3. Suggestions
      if (parsed.suggestions?.length) {
        await supabase.from('profile_suggestions').delete().eq('user_id', inputData.userId);
        await supabase.from('profile_suggestions').insert(
          parsed.suggestions.map((s: { priority: string; message: string }) => ({
            user_id: inputData.userId, priority: s.priority, message: s.message,
          }))
        );
      }

      console.log(`✅ Profil sauvegardé pour ${inputData.userId}`);
    } catch (saveError) {
      console.error('⚠️ Erreur sauvegarde profil (non bloquante):', saveError);
    }

    return {
      profileScore: parsed.profileScore ?? 0,
      completionLabel: parsed.completionLabel ?? 'Faible',
      technicalSkills: parsed.technicalSkills ?? [],
      userId: inputData.userId,
      targetOpportunity: inputData.targetOpportunity,
    };
  },
});

// ─────────────────────────────────────────────
// 3️⃣ STEP: MATCHING OFFRES (déterministe, pas d'agent LLM)
// ─────────────────────────────────────────────
const runMatchingStep = createStep({
  id: 'run-matching',

  inputSchema: z.object({
    profileScore: z.number(),
    completionLabel: z.string(),
    technicalSkills: z.array(z.string()),
    userId: z.string(),
    targetOpportunity: z.enum([
      'full-time',
      'internship',
      'academic-internship',
      'freelance',
    ]),
  }),

  outputSchema: z.object({
    matchesCount: z.number(),
    matches: z.any(),
    userId: z.string(),
    targetOpportunity: z.enum([
      'full-time',
      'internship',
      'academic-internship',
      'freelance',
    ]),
  }),

  execute: async ({ inputData }) => {
    try {
      // 1. Récupérer le profil complet
      const { data: profile } = await supabase
        .from('student_profiles')
        .select('*')
        .eq('user_id', inputData.userId)
        .single();

      if (!profile) {
        console.warn('⚠️ Profil introuvable pour le matching');
        return { matchesCount: 0, userId: inputData.userId, targetOpportunity: inputData.targetOpportunity };
      }

      // Récupérer les compétences
      const { data: skillsData } = await supabase
        .from('skills')
        .select('*')
        .eq('student_id', profile.id);
        
      const skills = (skillsData || []) as Array<{ name: string; skill_type: string }>;
      const profileText = [
        `Niveau: ${profile.education_level}`,
        `Domaine: ${profile.field_of_study}`,
        `Expérience: ${profile.years_of_experience} ans`,
        `Compétences techniques: ${skills.filter(s => s.skill_type === 'technical').map(s => s.name).join(', ')}`,
        `Soft skills: ${skills.filter(s => s.skill_type === 'soft').map(s => s.name).join(', ')}`,
        `Langues: ${skills.filter(s => s.skill_type === 'language').map(s => s.name).join(', ')}`,
      ].join('\n');

      // 3. Générer l'embedding avec Gemini
      const { GoogleGenerativeAI } = await import('@google/generative-ai');
      const genAI = new GoogleGenerativeAI(process.env['GOOGLE_GENERATIVE_AI_API_KEY'] ?? '');
      const embeddingModel = genAI.getGenerativeModel({ model: 'gemini-embedding-2' });
      const embeddingResult = await embeddingModel.embedContent(profileText);
      const embedding = embeddingResult.embedding.values.slice(0, 1536);

      console.log(`🔍 Embedding généré (${embedding.length} dimensions) pour ${inputData.userId}`);

      // 3.5 Sauvegarder l'embedding dans student_profiles
      const { error: updateError } = await supabase
        .from('student_profiles')
        .update({ embedding })
        .eq('id', profile.id);
        
      if (updateError) {
        console.error('⚠️ Erreur sauvegarde embedding étudiant:', updateError.message);
      }

      // 4. Recherche vectorielle via pgvector
      const { data: matches, error: matchError } = await supabase
        .rpc('match_offers', {
          query_embedding: embedding,
          match_count: 100, // On demande toutes les offres
        });

      if (matchError) {
        console.error('⚠️ Erreur recherche vectorielle:', matchError.message);
        return { matchesCount: 0, userId: inputData.userId, targetOpportunity: inputData.targetOpportunity };
      }

      const matchCount = matches?.length ?? 0;
      console.log(`✅ ${matchCount} offres trouvées par matching vectoriel`);

      return {
        matchesCount: matchCount,
        matches: matches || [],
        userId: inputData.userId,
        targetOpportunity: inputData.targetOpportunity,
      };
    } catch (error) {
      console.error('⚠️ Erreur matching (non bloquante):', error);
      return { matchesCount: 0, userId: inputData.userId, targetOpportunity: inputData.targetOpportunity };
    }
  },
});

// ─────────────────────────────────────────────
// 4️⃣ STEP: BUILD FEED (déterministe, pas d'agent LLM)
// ─────────────────────────────────────────────
const buildFeedStep = createStep({
  id: 'build-feed',

  inputSchema: z.object({
    matchesCount: z.number(),
    matches: z.any().optional(),
    userId: z.string(),
    targetOpportunity: z.enum([
      'full-time',
      'internship',
      'academic-internship',
      'freelance',
    ]),
  }),

  outputSchema: z.object({
    feedBuilt: z.boolean(),
    cardsCount: z.number(),
  }),

  execute: async ({ inputData }) => {
    try {
      // Récupérer le profil pour obtenir le student_id
      const { data: profileData } = await supabase
        .from('student_profiles')
        .select('id, years_of_experience, education_level')
        .eq('user_id', inputData.userId)
        .single();
      const profile = profileData as any;

      if (!profile) {
        return { feedBuilt: false, cardsCount: 0 };
      }

      // 2ème requête explicite pour les compétences (car la jointure skills(*) semble échouer)
      const { data: skills } = await supabase
        .from('skills')
        .select('name, skill_type')
        .eq('student_id', profile.id);

      const studentSkills = (skills || []) as Array<{ name: string; skill_type: string }>;
      const studentTechSkills = studentSkills
        .filter(s => s.skill_type === 'technical')
        .map(s => s.name.toLowerCase());
      
      console.log(`[Score Debug] ${studentTechSkills.length} compétences techniques trouvées pour l'étudiant:`, studentTechSkills);

      // Récupérer les données complètes des offres matchées (compétences requises)
      const offerIds = (inputData.matches || []).map((m: any) => m.id || m.offer_id);
      let offersDetails: Record<string, any> = {};
      if (offerIds.length > 0) {
        const { data: offersData } = await supabase
          .from('offers')
          .select('id, title, required_skills, min_education, years_of_experience')
          .in('id', offerIds);
        for (const o of offersData || []) {
          offersDetails[o.id] = o;
        }
      }

      const cards = (inputData.matches || []).map((m: any) => {
        const offerId = m.id || m.offer_id;
        const rawSimilarity = m.similarity ?? 0.0;

        const offerDetail = offersDetails[offerId];

        const { finalScore, details } = calculateFinalScore(
          studentTechSkills,
          offerDetail?.required_skills || [],
          rawSimilarity,
          profile.years_of_experience || 0,
          offerDetail?.years_of_experience ?? null,
          profile.education_level || '',
          offerDetail?.min_education ?? null
        );

        console.log(`[Score Debug] Offre ${offerId}: Final=${finalScore}% | Détails=`, details);

        return {
          offerId,
          matchScore: finalScore,
          isHighMatch: finalScore >= 70,
          details
        };
      });

      // Sauvegarder dans feed_cache
      if (cards.length > 0) {
        const { error: cacheError } = await supabase
          .from('feed_cache')
          .upsert({
            student_id: profile.id,
            cards: cards,
            generated_at: new Date().toISOString(),
          }, { onConflict: 'student_id' });
        if (cacheError) {
           console.error('⚠️ Erreur sauvegarde feed_cache:', cacheError);
        }
      }

      console.log(`✅ Feed construit pour ${inputData.userId} (${inputData.matchesCount} offres)`);

      return {
        feedBuilt: true,
        cardsCount: inputData.matchesCount,
      };
    } catch (error) {
      console.error('⚠️ Erreur build feed:', error);
      return { feedBuilt: false, cardsCount: 0 };
    }
  },
});

// ─────────────────────────────────────────────
// 🚀 WORKFLOW PRINCIPAL
// ─────────────────────────────────────────────
export const cvPipelineWorkflow = createWorkflow({
  id: 'cv-pipeline',

  inputSchema: z.object({
    cvUrl: z.string().url(),
    userId: z.string().uuid(),
    targetOpportunity: z.enum([
      'full-time',
      'internship',
      'academic-internship',
      'freelance',
    ]),
  }),

  outputSchema: z.object({
    feedBuilt: z.boolean(),
    cardsCount: z.number(),
  }),
})
  .then(downloadCvStep)
  .then(analyzeCvStep)
  .then(runMatchingStep)
  .then(buildFeedStep)
  .commit();