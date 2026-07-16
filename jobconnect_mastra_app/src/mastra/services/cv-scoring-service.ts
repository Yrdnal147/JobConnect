export type CvProfile = {
  technicalSkills?: string[];
  softSkills?: string[];
  languages?: { name: string; level: string }[];
  educationLevel?: string;
  fieldOfStudy?: string;
  yearsOfExperience?: number;
};

export function computeCvScore(profile: CvProfile): number {
  let score = 0;

  // TECH (40)
  const tech = profile.technicalSkills?.length || 0;
  score += Math.min(tech * 5, 40);

  // EDUCATION (25)
  const map: Record<string, number> = {
    'bac+3': 18,
    'licence': 18,
    'bac+5': 25,
    'master': 25,
    'bts': 10,
    'dut': 10,
  };

  score += map[(profile.educationLevel || '').toLowerCase()] || 10;

  // EXPERIENCE (20)
  score += Math.min((profile.yearsOfExperience || 0) * 10, 20);

  // LANGUAGES (5)
  const lang = profile.languages?.length || 0;
  score += lang >= 2 ? 5 : lang === 1 ? 3 : 0;

  return Math.min(Math.round(score), 100);
}