const API_URL = import.meta.env.VITE_API_URL || "";

export async function getMyGroups() {
  const res = await fetch(`${API_URL}/groups/my-groups`, {
    credentials: "include",
  });
  return res.json();
}