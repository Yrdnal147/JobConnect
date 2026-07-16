
import { Mastra } from '@mastra/core/mastra';
import { PinoLogger } from '@mastra/loggers';
import { LibSQLStore } from '@mastra/libsql';
import { DuckDBStore } from "@mastra/duckdb";
import { MastraCompositeStore } from '@mastra/core/storage';
import { Observability, MastraStorageExporter, MastraPlatformExporter, SensitiveDataFilter } from '@mastra/observability';
import { weatherWorkflow } from './workflows/weather-workflow.js';
import { cvPipelineWorkflow } from './workflows/cv-pipeline-workflow.js';
import { offerPipelineWorkflow } from './workflows/offer-pipeline-workflow.js';
import { applicationStatusWorkflow } from './workflows/application-status-workflow.js';
import { weatherAgent } from './agents/weather-agent.js';
import { cvAnalyzerAgent } from './agents/cv-analyser-agent.js';
import { matchingAgent  } from './agents/matching-agents.js';
import { recommendationAgent } from './agents/recommendation-agent.js';
import { applicationCoachAgent } from './agents/application-coach-agent.js';
import { careerStatusAgent } from './agents/career-status-agent.js';
import { messageAssistantAgent } from './agents/message-assistant-agent.js';
import { documentVerificationAgent } from './agents/document-verification-agent.js';
import { offerOptimizerAgent  } from './agents/offer-optimizer-agent.js';
import { supabase } from './supabase.js';

import { toolCallAppropriatenessScorer, completenessScorer, translationScorer } from './scorers/weather-scorer.js';

export const mastra = new Mastra({
  workflows: { weatherWorkflow, 'cv-pipeline': cvPipelineWorkflow, 'offer-pipeline': offerPipelineWorkflow, 'application-status-handler': applicationStatusWorkflow },
  agents: { 
    'weather-agent': weatherAgent, 
    'cv-analyzer-agent': cvAnalyzerAgent, 
    'matching-agents': matchingAgent, 
    'recommendation-agent': recommendationAgent, 
    'application-coach-agent': applicationCoachAgent, 
    'career-status-agent': careerStatusAgent, 
    'message-assistant-agent': messageAssistantAgent, 
    'document-verification-agent': documentVerificationAgent, 
    'offer-optimizer-agent': offerOptimizerAgent 
  },
  scorers: { toolCallAppropriatenessScorer, completenessScorer, translationScorer },
  /*
  storage: new MastraCompositeStore({
    id: 'composite-storage',
    default: new LibSQLStore({
      id: "mastra-storage",
      url: "file:./mastra.db",
    }),
    domains: {
      observability: await new DuckDBStore().getStore('observability'),
    }
  }),
  */
  logger: new PinoLogger({
    name: 'Mastra',
    level: 'info',
  }),
  /*
  observability: new Observability({
    configs: {
      default: {
        serviceName: 'mastra',
        exporters: [
          new MastraStorageExporter(), // Persists observability events to Mastra Storage
          new MastraPlatformExporter(), // Sends observability events to Mastra Platform (if MASTRA_PLATFORM_ACCESS_TOKEN is set)
        ],
        spanOutputProcessors: [
          new SensitiveDataFilter(), // Redacts sensitive data like passwords, tokens, keys
        ],
      },
    },
  }),
  */
});