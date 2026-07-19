class ApiEndpoints {
  ApiEndpoints._();

  // Workflows
  static const String cvPipeline = '/api/workflows/cv-pipeline/start';
  static const String offerDetail = '/api/workflows/offer-detail-load/start';
  static const String applicationStatus =
      '/api/workflows/application-status-handler/start';
  static const String newMessage = '/api/workflows/new-message/start';
  static const String offerPublished = '/api/workflows/offer-published/start';

  // Agents directs
  static const String cvAnalyze = '/api/agents/cv-analyzer-agent/generate';
  static const String matchingAgents = '/api/agents/matching-agents/generate';
  static const String careerStatus = '/api/agents/career-status-agent/generate';
  static const String applicationCoach =
      '/api/agents/application-coach-agent/generate';
  static const String offerDetailAgent =
      '/api/agents/recommendation-agent/generate';
  static const String messageAssistant =
      '/api/agents/message-assistant-agent/generate';
  static const String documentVerify =
      '/api/agents/document-verification-agent/generate';
  static const String offerOptimize =
      '/api/agents/offer-optimizer-agent/generate';
}
