import express, { Request, Response } from 'express';
import { mastra } from './index'; // Assure-toi que c'est le bon chemin

const app = express();
app.use(express.json());

// Log de middleware pour debugger chaque requête arrivant sur ton serveur
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// Route unique pour tes agents
app.post('/api/agents/:agentName/generate', async (req: Request, res: Response) => {
  const { agentName } = req.params;
  let { input, messages } = req.body;

  // Si Flutter envoie 'messages' (format officiel Mastra), on extrait le texte
  if (messages && Array.isArray(messages) && messages.length > 0) {
    input = messages[0].content;
  }

  // 1. Validation basique
  if (!input) {
    return res.status(400).json({ error: "Le champ 'input' ou 'messages' est requis dans le corps JSON" });
  }

  try {
    console.log(`Tentative d'exécution de l'agent : ${agentName}`);
    
    // 2. Récupération de l'agent depuis l'instance Mastra
    const agent = mastra.getAgent(agentName as any);
    
    if (!agent) {
      return res.status(404).json({ error: `Agent '${agentName}' non trouvé` });
    }

    // 3. Exécution de l'agent
    const result = await agent.generate(input);
    
    // 4. Réponse réussie
    return res.status(200).json({ success: true, response: result });

  } catch (error: any) {
    console.error(`Erreur critique sur l'agent ${agentName}:`, error.message);
    return res.status(500).json({ 
        error: "Erreur lors de l'exécution de l'agent", 
        details: error.message 
    });
  }
});

// Route unique pour tes workflows
app.post('/api/workflows/:workflowName/start', async (req: Request, res: Response) => {
  const { workflowName } = req.params;
  const { input } = req.body;

  if (!input) {
    return res.status(400).json({ error: "Le champ 'input' est requis dans le corps JSON" });
  }

  try {
    console.log(`Tentative d'exécution du workflow : ${workflowName}`);
    
    // Récupération du workflow
    const workflow = mastra.getWorkflow(workflowName as any);
    
    if (!workflow) {
      return res.status(404).json({ error: `Workflow '${workflowName}' non trouvé` });
    }

    // Exécution du workflow via createRun()
    const run = await workflow.createRun();
    const result = await run.start({ triggerData: input, inputData: input });
    
    return res.status(200).json({ success: true, response: result });

  } catch (error: any) {
    console.error(`Erreur critique sur le workflow ${workflowName}:`, error.stack);
    return res.status(500).json({ 
        error: "Erreur lors de l'exécution du workflow", 
        details: error.message 
    });
  }
});

// Démarrage du serveur uniquement si on n'est pas sur Vercel
if (process.env.NODE_ENV !== 'production' && !process.env.VERCEL) {
  const PORT = process.env.PORT || 3000;
  app.listen(Number(PORT), '0.0.0.0', () => {
    console.log(`🚀 ========================================================`);
    console.log(`🚀 Serveur d'agents JobConnect opérationnel sur le port ${PORT}`);
    console.log(`🚀 API Prête pour les requêtes Flutter !`);
    console.log(`🚀 ========================================================`);
  });
}

export default app;