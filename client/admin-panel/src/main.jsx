import React from 'react';
import ReactDOM from 'react-dom/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import './index.css';

// Suppress known console warnings from third-party libraries (zustand, radix-ui)
const originalWarn = console.warn;
const originalError = console.error;

console.warn = (...args) => {
  const message = args[0]?.toString() || '';
  if (
    message.includes('Default export is deprecated') ||
    message.includes('DialogContent') ||
    message.includes('DialogTitle') ||
    message.includes('aria-describedby') ||
    message.includes('zustand')
  ) {
    return;
  }
  originalWarn.apply(console, args);
};

console.error = (...args) => {
  const message = args[0]?.toString() || '';
  // Suppress non-critical errors that clutter the console
  if (
    message.includes('DialogContent') ||
    message.includes('DialogTitle')
  ) {
    return;
  }
  originalError.apply(console, args);
};

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 1,
    },
  },
});

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </QueryClientProvider>
  </React.StrictMode>
);

