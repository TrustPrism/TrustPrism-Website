import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), "")
  // Use empty string for relative paths (same domain) in production
  // For development, use environment variable or default to localhost
  const apiUrl = mode === 'production' 
    ? (env.VITE_API_URL || "") 
    : (env.VITE_API_URL || "http://localhost:5000")

  return {
    plugins: [react()],
    server: {
      proxy: {
        "/auth": { target: apiUrl || "http://localhost:5000", changeOrigin: true },
        "/api": { target: apiUrl || "http://localhost:5000", changeOrigin: true },
        "/dashboard": { target: apiUrl || "http://localhost:5000", changeOrigin: true },
        "/groups": { target: apiUrl || "http://localhost:5000", changeOrigin: true },
        "/notifications": { target: apiUrl || "http://localhost:5000", changeOrigin: true },
        "/admin": { target: apiUrl || "http://localhost:5000", changeOrigin: true },
        "/participant": { target: apiUrl || "http://localhost:5000", changeOrigin: true },
        "/friends": { target: apiUrl || "http://localhost:5000", changeOrigin: true },
        "/projects": { target: apiUrl || "http://localhost:5000", changeOrigin: true },
        "/insights": { target: apiUrl || "http://localhost:5000", changeOrigin: true },
        "/socket.io": { target: apiUrl || "http://localhost:5000", ws: true, changeOrigin: true }
      }
    }
  }
})
