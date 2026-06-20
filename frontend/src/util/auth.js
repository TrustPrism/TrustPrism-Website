export const getAuthRole = () => {
  return localStorage.getItem("role");
};

export const logout = async () => {
  try {
    const API_URL = import.meta.env.VITE_API_URL || "";
    await fetch(`${API_URL}/auth/logout`, {
      method: "POST",
      credentials: "include",
    });
  } catch (err) {
    console.error("Logout failed", err);
  }
  localStorage.removeItem("isAuthenticated");
  localStorage.removeItem("role");
  localStorage.removeItem("token");
  window.location.href = "/login";
};

export async function authFetch(url, options = {}) {
  const API_URL = import.meta.env.VITE_API_URL || "";
  if (typeof url === "string" && url.startsWith("/") && !url.startsWith("//")) {
    url = API_URL + url;
  }
  return fetch(url, {
    ...options,
    credentials: "include",
    headers: {
      ...options.headers,
      "Content-Type": "application/json"
    }
  });
}
