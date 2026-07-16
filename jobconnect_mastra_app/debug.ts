import { supabase } from './src/mastra/supabase';

async function run() {
  const { data: offers } = await supabase
    .from('offers')
    .select('id, title, embedding')
    .order('created_at', { ascending: false })
    .limit(3);
    
  console.log("Latest Offers:");
  offers?.forEach(o => {
    console.log(`- ${o.title} (ID: ${o.id}) - Has Embedding? ${o.embedding ? 'YES' : 'NO'}`);
  });
  
  const { data: cache } = await supabase
    .from('feed_cache')
    .select('cards, student_id')
    .order('generated_at', { ascending: false })
    .limit(1);
    
  console.log("\nLatest Feed Cache size:");
  if (cache && cache.length > 0) {
     console.log(`Cards count: ${cache[0].cards.length} for student ${cache[0].student_id}`);
     const swiftOffer = cache[0].cards.find((c: any) => c.offerId === offers?.[0]?.id);
     console.log(`Is latest offer in cache? ${swiftOffer ? `YES (Score: ${swiftOffer.matchScore})` : 'NO'}`);
  }
}

run().catch(console.error);
