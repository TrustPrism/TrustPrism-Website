import { BrowserRouter, Routes, Route } from "react-router-dom";
import Login from "./pages/Login";
import Register from "./pages/Register";
import Admin from "./pages/Admin";
import Researcher from "./pages/Researcher";
import User from "./pages/User";
import Home from "./pages/Home";
import ProtectedRoute from "./components/protectedRoute";
import VerifyEmail from "./pages/VerifyEmail";
import AuthContext from "./context/AuthContext";
import ForgotPassword from "./pages/ForgotPassword";
import ResetPassword from "./pages/ResetPassword";
import { useContext, useEffect } from "react";
import SessionLock from "./components/SessionLock";
export default function App() {
    const { setAuth } = useContext(AuthContext);
    useEffect(() => {
    const isAuthenticated = localStorage.getItem("isAuthenticated");
    const role = localStorage.getItem("role");
    const id = localStorage.getItem("userId");

    if (isAuthenticated === 'true' && role) {
      setAuth({ isAuthenticated: true, role, id });
    }
  }, [setAuth]);

  // TACC §3.05 — Global fetch interceptor: 
  // 1. Dispatch session:invalidated on SESSION_INVALIDATED 401
  // 2. Automatically inject CSRF header for all non-GET requests
  useEffect(() => {
    const API_URL = import.meta.env.VITE_API_URL || "";
    const origFetch = window.fetch;
    window.fetch = async (...args) => {
      let [url, options] = args;
      options = options || {};

      let urlString = typeof url === "string" ? url : url.url;
      if (urlString.startsWith("/") && !urlString.startsWith("//") && !urlString.startsWith("http")) {
        urlString = API_URL + urlString;
      }

      if (url instanceof Request) {
        const requestHeaders = new Headers(url.headers);
        if (options.headers) {
          const customHeaders = new Headers(options.headers);
          customHeaders.forEach((value, key) => requestHeaders.set(key, value));
        }
        options = {
          ...options,
          method: options.method || url.method,
          body: options.body || url.body,
          headers: requestHeaders,
        };
      }

      const method = (options.method || "GET").toUpperCase();
      if (!["GET", "HEAD", "OPTIONS"].includes(method)) {
        const headers = new Headers(options.headers || {});
        headers.set("X-TrustPrism-CSRF", "1");
        headers.set("X-Requested-With", "XMLHttpRequest");
        options.headers = headers;
      }

      const response = await origFetch(urlString, options);

      if (response.status === 401) {
        const clone = response.clone();
        try {
          const body = await clone.json();
          if (body.code === "SESSION_INVALIDATED") {
            window.dispatchEvent(new CustomEvent("session:invalidated", { detail: body }));
          }
        } catch (err) { console.error("Session check error", err); }
      }
      return response;
    };
    return () => { window.fetch = origFetch; };
  }, []);
  return (
    
    
    
    <BrowserRouter>
      <SessionLock timeoutMinutes={30} />
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/verify-email" element={<VerifyEmail />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/reset-password" element={<ResetPassword />} />

        <Route
          path="/admin"
          element={
            <ProtectedRoute role="admin">
              <Admin />
            </ProtectedRoute>
          }
        />

        <Route
          path="/researcher"
          element={
            <ProtectedRoute role="researcher">
              <Researcher />
            </ProtectedRoute>
          }
        />

        <Route
          path="/user"
          element={
            <ProtectedRoute role="user">
              <User />
            </ProtectedRoute>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}
