export async function getMyGroups() {
   // assuming JWT auth
  const res = await fetch("http://localhost:5000/groups/my-groups", {
    credentials: "include",
  });
  return res.json();
}