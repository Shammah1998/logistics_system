// API Configuration for production deployment
// In development: uses Vite proxy (/api -> localhost:3000)
// In production: uses VITE_API_URL environment variable (Render backend URL)

export const getApiUrl = () => {
  // In production, use the full backend URL from environment variable
  const apiUrl = import.meta.env.VITE_API_URL;
  
  if (apiUrl) {
    // Remove trailing slash if present
    return apiUrl.replace(/\/$/, '');
  }
  
  // In development, use relative path (Vite proxy handles it)
  return '/api';
};

// Helper function to make API calls with proper URL
export const apiCall = async (endpoint, options = {}) => {
  const baseUrl = getApiUrl();
  const url = `${baseUrl}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;
  
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });
  
  return response;
};

export default getApiUrl;


