const API_URL = import.meta.env.VITE_API_URL || "";

export async function startSession(token, experimentType) {
  const res = await fetch(`${API_URL}/sessions`, {
      credentials: "include",
    method: "POST",
    headers: { 
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}` 
    },
    body: JSON.stringify({ experimentType }),
  });
  return res.json();
}

export async function logInteraction(token, interactionData) {
  const res = await fetch(`${API_URL}/sessions/interactions`, {
      credentials: "include",
    method: "POST",
    headers: { 
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`
    },
    body: JSON.stringify(interactionData),
  });
  return res.json();
}