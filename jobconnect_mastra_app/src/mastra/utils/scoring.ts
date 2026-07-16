export const SCORING_CONFIG = {
  weights: {
    hardSkills: 45,
    semantic: 30,
    experience: 15,
    education: 10
  },
  hardSkillsZeroCap: 40 // Plafond de 40% si le candidat n'a aucune des compétences dures requises
};

/** Normalise les noms des technos pour le matching exact */
export function normalizeSkill(skill: string): string {
  if (!skill) return '';
  return skill
    .toLowerCase()
    .trim()
    .replace(/\.js$/, '')
    .replace(/js$/, '')
    .replace(/node\.?js/, 'node')
    .replace(/react\.?js/, 'react')
    .replace(/vue\.?js/, 'vue');
}

export function computeHardSkillsScore(studentTechSkills: string[], offerRequiredSkills: string[]): number {
  if (!offerRequiredSkills || offerRequiredSkills.length === 0) return 100;
  if (!studentTechSkills || studentTechSkills.length === 0) return 0;
  
  const normalizedStudent = studentTechSkills.map(normalizeSkill);
  const normalizedOffer = offerRequiredSkills.map(normalizeSkill);
  
  const matchedSkills = normalizedOffer.filter(req =>
    normalizedStudent.some(skill =>
      req === skill || req.includes(skill) || skill.includes(req) || 
      req.split(' ').some(w => w.length > 3 && skill.includes(w))
    )
  );
  
  return (matchedSkills.length / normalizedOffer.length) * 100;
}

export function computeSemanticScore(pgvectorSimilarity: number): number {
  const baseline = 0.65;
  const maxSim = 0.88;
  let score = ((pgvectorSimilarity - baseline) / (maxSim - baseline)) * 100;
  return Math.max(0, Math.min(100, score));
}

export function computeExperienceScore(studentExp: number, offerExp: number | null | undefined): number | null {
  if (offerExp === null || offerExp === undefined) return null;
  if (offerExp <= 0) return 100;
  const sExp = studentExp || 0;
  if (sExp >= offerExp) return 100;
  
  // Tolérance d'un an
  if (offerExp - sExp <= 1) {
    return 80;
  }
  
  const ratio = sExp / offerExp;
  return Math.max(0, ratio * 100);
}

export function parseEducationLevel(level: string): number {
  if (!level) return 0;
  const l = level.toLowerCase();
  if (l.includes('doctorat')) return 8;
  if (l.includes('master') || l.includes('bac+5')) return 5;
  if (l.includes('bac+4')) return 4;
  if (l.includes('licence') || l.includes('bac+3')) return 3;
  if (l.includes('bts') || l.includes('dut') || l.includes('bac+2')) return 2;
  if (l.includes('bac')) return 0;
  return 0;
}

export function computeEducationScore(studentEdu: string, offerEdu: string | null | undefined): number | null {
  if (offerEdu === null || offerEdu === undefined || offerEdu.trim() === '') return null;
  const sLevel = parseEducationLevel(studentEdu);
  const oLevel = parseEducationLevel(offerEdu);
  
  if (sLevel >= oLevel) return 100;
  
  // Tolérance d'un niveau (ex: Bac+4 au lieu de Bac+5)
  if (oLevel - sLevel === 1) {
    return 80;
  }
  
  if (sLevel === 0) return 0;
  
  return (sLevel / oLevel) * 100;
}

export function calculateFinalScore(
  studentTechSkills: string[],
  offerRequiredSkills: string[],
  pgvectorSimilarity: number,
  studentExp: number,
  offerExp: number | null | undefined,
  studentEdu: string,
  offerEdu: string | null | undefined
) {
  const hardSkills = computeHardSkillsScore(studentTechSkills, offerRequiredSkills);
  const semantic = computeSemanticScore(pgvectorSimilarity);
  const experience = computeExperienceScore(studentExp, offerExp);
  const education = computeEducationScore(studentEdu, offerEdu);
  
  let validWeights = SCORING_CONFIG.weights.hardSkills + SCORING_CONFIG.weights.semantic;
  let totalWeightedScore = 
    (hardSkills * SCORING_CONFIG.weights.hardSkills) +
    (semantic * SCORING_CONFIG.weights.semantic);
    
  if (experience !== null) {
    validWeights += SCORING_CONFIG.weights.experience;
    totalWeightedScore += (experience * SCORING_CONFIG.weights.experience);
  }
  
  if (education !== null) {
    validWeights += SCORING_CONFIG.weights.education;
    totalWeightedScore += (education * SCORING_CONFIG.weights.education);
  }
  
  let totalScore = totalWeightedScore / validWeights;
    
  if (hardSkills === 0 && offerRequiredSkills && offerRequiredSkills.length > 0) {
    totalScore = Math.min(SCORING_CONFIG.hardSkillsZeroCap, totalScore);
  }
  
  return {
    finalScore: Math.round(totalScore),
    details: {
      hardSkills: Math.round(hardSkills),
      semantic: Math.round(semantic),
      experience: experience !== null ? Math.round(experience) : null,
      education: education !== null ? Math.round(education) : null
    }
  };
}
