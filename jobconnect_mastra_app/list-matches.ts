import { supabase } from './src/mastra/supabase';

async function run() {
  // 1. Get all offers
  const { data: offers, error: offersError } = await supabase
    .from('offers')
    .select('id, title, offer_type, location, required_skills, min_education, years_of_experience, is_active, companies!inner(name)')
    .order('created_at', { ascending: false });

  if (offersError) {
    console.error('Erreur récupération offres:', offersError);
    return;
  }

  // 2. Get all feed_cache entries
  const { data: caches, error: cacheError } = await supabase
    .from('feed_cache')
    .select('student_id, cards');

  if (cacheError) {
    console.error('Erreur récupération feed_cache:', cacheError);
    return;
  }

  // 3. Get student profiles for names
  const { data: profiles } = await supabase
    .from('student_profiles')
    .select('id, user_id');

  const { data: users } = await supabase.auth.admin.listUsers();

  const studentNames: Record<string, string> = {};
  for (const profile of profiles || []) {
    const user = users?.users?.find((u: any) => u.id === profile.user_id);
    studentNames[profile.id] = user?.user_metadata?.full_name || profile.user_id;
  }

  // Build a map: offerId -> [{studentName, matchScore, details}]
  const offerMatches: Record<string, Array<{studentName: string, matchScore: number, details: any}>> = {};

  for (const cache of caches || []) {
    const studentName = studentNames[cache.student_id] || cache.student_id;
    const cards = cache.cards as Array<any>;
    for (const card of cards) {
      const offerId = card.offerId;
      if (!offerMatches[offerId]) offerMatches[offerId] = [];
      offerMatches[offerId].push({
        studentName,
        matchScore: card.matchScore,
        details: card.details || null
      });
    }
  }

  // 4. Display results
  console.log('='.repeat(100));
  console.log('  OFFRES ET SCORES DE MATCHING JOBCONNECT');
  console.log('='.repeat(100));
  console.log('');

  for (const offer of offers || []) {
    const company = (offer as any).companies;
    const matches = offerMatches[offer.id] || [];
    const status = offer.is_active ? '🟢 Active' : '🔴 Inactive';

    console.log(`┌${'─'.repeat(98)}┐`);
    console.log(`│ 📋 ${offer.title}`);
    console.log(`│ 🏢 ${company?.name || 'N/A'} | ${offer.offer_type} | 📍 ${offer.location || 'N/A'} | ${status}`);
    console.log(`│ 🔧 Compétences requises: ${Array.isArray(offer.required_skills) ? offer.required_skills.join(', ') : offer.required_skills || 'Non spécifiées'}`);
    console.log(`│ 🎓 Éducation min: ${offer.min_education || 'Non spécifiée'} | 📅 Expérience: ${offer.years_of_experience ?? 'Non spécifiée'} ans`);
    console.log(`│`);

    if (matches.length === 0) {
      console.log(`│ ⚠️  Aucun matching calculé pour cette offre`);
    } else {
      // Sort by score desc
      matches.sort((a, b) => b.matchScore - a.matchScore);
      console.log(`│ 🎯 SCORES DE MATCHING (${matches.length} étudiant(s)):`);
      for (const m of matches) {
        const bar = '█'.repeat(Math.floor(m.matchScore / 5)) + '░'.repeat(20 - Math.floor(m.matchScore / 5));
        const emoji = m.matchScore >= 75 ? '🔥' : m.matchScore >= 50 ? '👍' : '⚡';
        const detailStr = m.details
          ? ` [Skills:${m.details.hardSkills}% | Sémantique:${m.details.semantic}% | Exp:${m.details.experience ?? 'N/A'}% | Édu:${m.details.education ?? 'N/A'}%]`
          : '';
        console.log(`│   ${emoji} ${m.studentName}: ${m.matchScore}% ${bar}${detailStr}`);
      }
    }
    console.log(`└${'─'.repeat(98)}┘`);
    console.log('');
  }

  // Summary
  const totalOffers = offers?.length || 0;
  const offersWithMatches = Object.keys(offerMatches).length;
  const allScores = Object.values(offerMatches).flat().map(m => m.matchScore);
  const avgScore = allScores.length > 0 ? (allScores.reduce((a, b) => a + b, 0) / allScores.length).toFixed(1) : 'N/A';
  const maxScore = allScores.length > 0 ? Math.max(...allScores) : 'N/A';
  const minScore = allScores.length > 0 ? Math.min(...allScores) : 'N/A';

  console.log('='.repeat(100));
  console.log(`  RÉSUMÉ: ${totalOffers} offres | ${offersWithMatches} avec matching | Score moyen: ${avgScore}% | Min: ${minScore}% | Max: ${maxScore}%`);
  console.log('='.repeat(100));
}

run().catch(console.error);
