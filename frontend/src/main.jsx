import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import { AuthProvider } from "./context/AuthContext.jsx";
import "./index.css"; 
import * as Sentry from "@sentry/react";
import posthog from 'posthog-js';

// --- MONITORING & OBSERVABILITY ---

// 1. Error Tracking (Sentry)
// In production, replace the DSN with your actual Sentry DSN.
Sentry.init({
  dsn: import.meta.env.VITE_SENTRY_DSN || "", // e.g., "https://examplePublicKey@o0.ingest.sentry.io/0"
  integrations: [
    Sentry.browserTracingIntegration(),
    Sentry.replayIntegration(),
  ],
  tracesSampleRate: 1.0, 
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
});

// 2. Analytics (PostHog)
// Tracks active users, dropoffs, and broken flows.
posthog.init(import.meta.env.VITE_POSTHOG_KEY || 'dummy-key-for-dev', {
  api_host: import.meta.env.VITE_POSTHOG_HOST || 'https://app.posthog.com',
  autocapture: true, // Automatically tracks button clicks and pageviews
});

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <Sentry.ErrorBoundary fallback={<p>An error has occurred.</p>}>
      <AuthProvider>
        <App />
      </AuthProvider>
    </Sentry.ErrorBoundary>
  </React.StrictMode>
);