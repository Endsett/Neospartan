# AI Services Configuration

## Overview
All AI services in the Neospartan app use Google's Gemini 2.5 Flash API. No Firebase AI services are used.

## API Key
The Gemini API key is centrally configured in `lib/config/ai_config.dart`:
- API Key: `AIzaSyAp1gkplk30KQOPGenhjzcVnm_YQvz3Wyk`
- Model: `gemini-2.0-flash-exp`

## AI Services Using Gemini

### 1. AIPlanService (`lib/services/ai_plan_service.dart`)
- **Purpose**: Generates personalized training plans
- **Uses**: Gemini for plan generation and adjustments
- **Memory**: Integrates with AI memory system for context-aware plans

### 2. ContextIngestionService (`lib/services/context_ingestion_service.dart`)
- **Purpose**: Manages context injection into Gemini prompts
- **Uses**: Gemini for memory summarization
- **Features**: Intelligent context gathering and token management

### 3. AIMemoryService (`lib/services/ai_memory_service.dart`)
- **Purpose**: Stores and retrieves AI context data
- **Storage**: Firebase (authenticated) or SharedPreferences (guest)
- **Note**: Only stores data, no AI processing

## Firebase Usage
Firebase is used ONLY for:
- User authentication
- Data storage/sync (workouts, profiles, memories)
- Analytics and crash reporting

**NO Firebase AI services are used.**

## Dependencies
- `google_generative_ai: ^0.4.0` - Direct Gemini SDK
- NO Firebase ML Kit
- NO Vertex AI
- NO Firebase AI dependencies

## Security
- API key is hardcoded in the app (consider moving to environment variables for production)
- All AI requests go directly to Google's Gemini API
- No AI processing happens through Firebase
