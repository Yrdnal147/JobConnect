import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
);

async function runMigration() {
  console.log('🔄 Démarrage de la migration via API REST...');

  // 1. Récupérer toutes les candidatures sans explication
  const { data: applications, error } = await supabase
    .from('applications')
    .select('id, student_id, offer_id, status')
    .is('status_explanation', null);

  if (error) {
    console.error('❌ Erreur lors de la récupération des candidatures:', error);
    return;
  }

  if (!applications || applications.length === 0) {
    console.log('✅ Aucune candidature à migrer.');
    return;
  }

  console.log(`📋 ${applications.length} candidatures à traiter via le serveur local (port 3000).`);

  let successCount = 0;
  for (let i = 0; i < applications.length; i++) {
    const app = applications[i];
    console.log(`⏳ Traitement [${i + 1}/${applications.length}] : Candidature ${app.id} (Statut: ${app.status})`);
    
    try {
      const response = await fetch('http://localhost:3000/api/workflows/application-status-handler/start', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          input: {
            applicationId: app.id,
            studentId: app.student_id,
            offerId: app.offer_id,
            status: app.status,
          }
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP Error: ${response.status} ${response.statusText}`);
      }

      const resJson = await response.json();
      if (resJson.success) {
        console.log(`✅ Succès pour la candidature ${app.id}`);
        successCount++;
      } else {
         throw new Error(resJson.error || 'Erreur inconnue API Mastra');
      }
    } catch (e: any) {
      console.error(`❌ Échec pour la candidature ${app.id}:`, e.message);
    }
    
    // Pause pour ne pas saturer l'API
    await new Promise(r => setTimeout(r, 1000));
  }

  console.log(`\n🎉 Migration terminée ! ${successCount}/${applications.length} candidatures mises à jour avec succès.`);
}

runMigration().catch(console.error);
