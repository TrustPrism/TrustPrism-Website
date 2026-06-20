import { useState, useEffect, useContext } from "react";
import AuthContext from "../../context/AuthContext";

const API = import.meta.env.VITE_API_URL || "";

export default function FriendsView() {
  const { auth } = useContext(AuthContext);
  const [friends, setFriends] = useState([]);
  const [requests, setRequests] = useState([]);
  const [sentRequests, setSentRequests] = useState([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [searchResults, setSearchResults] = useState([]);
  const [searching, setSearching] = useState(false);
  const [loading, setLoading] = useState(true);
  const [selectedFriend, setSelectedFriend] = useState(null);
  const [friendProfile, setFriendProfile] = useState(null);
  const [profileLoading, setProfileLoading] = useState(false);
  const [activeTab, setActiveTab] = useState("friends"); // friends | requests

  useEffect(() => {
    if (!auth.isAuthenticated) return;
    loadAll();
  }, [auth.isAuthenticated]);

  const loadAll = async () => {
    setLoading(true);
    try {
      const [friendsRes, requestsRes, sentRes] = await Promise.all([
        fetch(`${API}/friends`, { credentials: "include" }),
        fetch(`${API}/friends/requests`, { credentials: "include" }),
        fetch(`${API}/friends/sent`, { credentials: "include" }),
      ]);

      if (friendsRes.ok) setFriends(await friendsRes.json());
      if (requestsRes.ok) setRequests(await requestsRes.json());
      if (sentRes.ok) setSentRequests(await sentRes.json());
    } catch (err) {
      console.error("Failed to load friends data:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async () => {
    if (searchTerm.trim().length < 2) return;
    setSearching(true);
    try {
      const res = await fetch(
        `${API}/friends/search?q=${encodeURIComponent(searchTerm.trim())}`,
        { credentials: "include" }
      );
      if (res.ok) setSearchResults(await res.json());
    } catch (err) {
      console.error("Search error:", err);
    } finally {
      setSearching(false);
    }
  };

  const sendRequest = async (addresseeId) => {
    try {
      const res = await fetch(`${API}/friends/request`, {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ addresseeId }),
      });
      const data = await res.json();
      if (res.ok) {
        setSearchResults((prev) => prev.filter((u) => u.id !== addresseeId));
        loadAll();
      } else {
        alert(data.error || "Failed to send request");
      }
    } catch (err) {
      console.error("Send request error:", err);
    }
  };

  const respondToRequest = async (friendshipId, action) => {
    try {
      const res = await fetch(`${API}/friends/respond`, {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ friendshipId, action }),
      });
      if (res.ok) loadAll();
    } catch (err) {
      console.error("Respond error:", err);
    }
  };

  const removeFriend = async (friendshipId) => {
    if (!confirm("Remove this friend?")) return;
    try {
      const res = await fetch(`${API}/friends/${friendshipId}`, {
        method: "DELETE",
        credentials: "include",
      });
      if (res.ok) {
        setFriends((prev) => prev.filter((f) => f.friendship_id !== friendshipId));
        setSelectedFriend(null);
        setFriendProfile(null);
      }
    } catch (err) {
      console.error("Remove error:", err);
    }
  };

  const viewProfile = async (friendId) => {
    setSelectedFriend(friendId);
    setProfileLoading(true);
    try {
      const res = await fetch(`${API}/friends/profile/${friendId}`, {
        credentials: "include",
      });
      if (res.ok) setFriendProfile(await res.json());
    } catch (err) {
      console.error("Profile error:", err);
    } finally {
      setProfileLoading(false);
    }
  };

  const isFriendOrPending = (userId) => {
    return (
      friends.some((f) => f.friend_id === userId) ||
      sentRequests.some((s) => s.addressee_id === userId) ||
      requests.some((r) => r.requester_id === userId)
    );
  };

  /** Helper: get display name from a user object that has first_name + last_name */
  const displayName = (firstName, lastName) => {
    return [firstName, lastName].filter(Boolean).join(" ") || "User";
  };

  if (loading) {
    return (
      <main className="dashboard-main">
        <div className="games-loading">
          <span className="material-icons-round spin">autorenew</span>
          <p>Loading friends...</p>
        </div>
      </main>
    );
  }

  return (
    <main className="dashboard-main">
      <header className="topbar">
        <h1>Friends</h1>
      </header>

      <div className="friends-layout">
        {/* Left Panel */}
        <aside className="friends-panel">
          {/* Search */}
          <div className="friends-search-section">
            <h4 className="friends-panel-title">
              <span className="material-icons-round">person_search</span>
              Find People
            </h4>
            <div className="friends-search-bar">
              <input
                type="text"
                placeholder="Search by name..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSearch()}
              />
              <button onClick={handleSearch} disabled={searching}>
                <span className="material-icons-round">
                  {searching ? "autorenew" : "search"}
                </span>
              </button>
            </div>

            {searchResults.length > 0 && (
              <ul className="friends-search-results">
                {searchResults.map((user) => (
                  <li key={user.id} className="friends-search-item">
                    <div className="friends-search-info">
                      <span className="friends-avatar-mini">
                        {user.first_name?.[0] || "?"}
                      </span>
                      <span className="friends-search-name">
                        {displayName(user.first_name, user.last_name)}
                      </span>
                    </div>
                    {isFriendOrPending(user.id) ? (
                      <span className="friends-status-chip">
                        <span className="material-icons-round" style={{ fontSize: "14px" }}>check</span>
                        Added
                      </span>
                    ) : (
                      <button
                        className="friends-add-btn"
                        onClick={() => sendRequest(user.id)}
                      >
                        <span className="material-icons-round" style={{ fontSize: "16px" }}>person_add</span>
                      </button>
                    )}
                  </li>
                ))}
              </ul>
            )}
          </div>

          {/* Tabs: Friends / Requests */}
          <div className="friends-tabs">
            <button
              className={`friends-tab ${activeTab === "friends" ? "active" : ""}`}
              onClick={() => setActiveTab("friends")}
            >
              Friends
              {friends.length > 0 && <span className="friends-count">{friends.length}</span>}
            </button>
            <button
              className={`friends-tab ${activeTab === "requests" ? "active" : ""}`}
              onClick={() => setActiveTab("requests")}
            >
              Requests
              {requests.length > 0 && (
                <span className="friends-count pulse">{requests.length}</span>
              )}
            </button>
          </div>

          {/* Pending Requests */}
          {activeTab === "requests" && (
            <div className="friends-requests-list">
              {requests.length === 0 && sentRequests.length === 0 ? (
                <div className="friends-empty-panel">
                  <span className="material-icons-round">mail_outline</span>
                  <p>No pending requests</p>
                </div>
              ) : (
                <>
                  {requests.map((req) => (
                    <div key={req.id} className="friends-request-card">
                      <div className="friends-request-info">
                        <span className="friends-avatar-mini">
                          {req.requester_first_name?.[0] || "?"}
                        </span>
                        <div>
                          <strong>{displayName(req.requester_first_name, req.requester_last_name)}</strong>
                          <small>
                            {new Date(req.created_at).toLocaleDateString()}
                          </small>
                        </div>
                      </div>
                      <div className="friends-request-actions">
                        <button
                          className="friends-accept-btn"
                          onClick={() => respondToRequest(req.id, "accept")}
                        >
                          <span className="material-icons-round" style={{ fontSize: "16px" }}>check</span>
                        </button>
                        <button
                          className="friends-reject-btn"
                          onClick={() => respondToRequest(req.id, "reject")}
                        >
                          <span className="material-icons-round" style={{ fontSize: "16px" }}>close</span>
                        </button>
                      </div>
                    </div>
                  ))}
                  {sentRequests.length > 0 && (
                    <>
                      <p className="friends-sent-label">Sent Requests</p>
                      {sentRequests.map((s) => (
                        <div key={s.id} className="friends-request-card sent">
                          <div className="friends-request-info">
                            <span className="friends-avatar-mini">
                              {s.addressee_first_name?.[0] || "?"}
                            </span>
                            <div>
                              <strong>{displayName(s.addressee_first_name, s.addressee_last_name)}</strong>
                              <small>Pending</small>
                            </div>
                          </div>
                          <span className="friends-status-chip">Awaiting</span>
                        </div>
                      ))}
                    </>
                  )}
                </>
              )}
            </div>
          )}

          {/* Friends List (sidebar) */}
          {activeTab === "friends" && (
            <div className="friends-sidebar-list">
              {friends.length === 0 ? (
                <div className="friends-empty-panel">
                  <span className="material-icons-round">group_off</span>
                  <p>No friends yet</p>
                  <small>Search for people above!</small>
                </div>
              ) : (
                friends.map((friend) => (
                  <div
                    key={friend.friendship_id}
                    className={`friends-sidebar-item ${selectedFriend === friend.friend_id ? "selected" : ""}`}
                    onClick={() => viewProfile(friend.friend_id)}
                  >
                    <span className="friends-avatar-mini">
                      {friend.first_name?.[0] || "?"}
                    </span>
                    <div className="friends-sidebar-item-info">
                      <strong>{displayName(friend.first_name, friend.last_name)}</strong>
                      <small>
                        Since {new Date(friend.friends_since).toLocaleDateString()}
                      </small>
                    </div>
                  </div>
                ))
              )}
            </div>
          )}
        </aside>

        {/* Main Panel — Friend Profile */}
        <section className="friends-main">
          {!selectedFriend ? (
            <div className="friends-main-empty">
              <span className="material-icons-round" style={{ fontSize: "4rem", color: "#cbd5e1" }}>
                group
              </span>
              <h3>Select a friend to view their profile</h3>
              <p>Friend profiles show game statistics and activity</p>
            </div>
          ) : profileLoading ? (
            <div className="games-loading">
              <span className="material-icons-round spin">autorenew</span>
              <p>Loading profile...</p>
            </div>
          ) : friendProfile ? (
            <div className="friend-profile">
              {/* Profile Header */}
              <div className="friend-profile-header">
                <div className="friend-profile-avatar">
                  {friendProfile.firstName?.[0] || "?"}
                </div>
                <div className="friend-profile-identity">
                  <h2>{displayName(friendProfile.firstName, friendProfile.lastName)}</h2>
                  <p>Player Profile</p>
                </div>
                <button
                  className="friends-remove-btn"
                  onClick={() => {
                    const f = friends.find((f) => f.friend_id === selectedFriend);
                    if (f) removeFriend(f.friendship_id);
                  }}
                >
                  <span className="material-icons-round" style={{ fontSize: "16px" }}>person_remove</span>
                  Remove
                </button>
              </div>

              {/* Stats Grid */}
              <div className="friend-profile-stats">
                <div className="friend-stat-card">
                  <span className="material-icons-round" style={{ color: "#0ea5e9" }}>sports_esports</span>
                  <div>
                    <h4>{friendProfile.gamesPlayed}</h4>
                    <p>Games Played</p>
                  </div>
                </div>
                <div className="friend-stat-card">
                  <span className="material-icons-round" style={{ color: "#22c55e" }}>check_circle</span>
                  <div>
                    <h4>{friendProfile.gamesCompleted}</h4>
                    <p>Completed</p>
                  </div>
                </div>
                <div className="friend-stat-card">
                  <span className="material-icons-round" style={{ color: "#f59e0b" }}>emoji_events</span>
                  <div>
                    <h4>{friendProfile.averageScore}</h4>
                    <p>Avg Score</p>
                  </div>
                </div>
                <div className="friend-stat-card">
                  <span className="material-icons-round" style={{ color: "#8b5cf6" }}>smart_toy</span>
                  <div>
                    <h4>{friendProfile.aiInteractions}</h4>
                    <p>AI Interactions</p>
                  </div>
                </div>
              </div>

              {/* Recent Games */}
              {friendProfile.recentGames?.length > 0 && (
                <div className="friend-recent-games">
                  <h3>
                    <span className="material-icons-round" style={{ fontSize: "20px" }}>history</span>
                    Recent Activity
                  </h3>
                  <div className="friend-recent-list">
                    {friendProfile.recentGames.map((game, i) => (
                      <div key={i} className="friend-recent-item">
                        <div className="friend-recent-info">
                          <strong>{game.gameName}</strong>
                          <small>{game.category}</small>
                        </div>
                        <div className="friend-recent-meta">
                          {game.score !== null && (
                            <span className="friend-recent-score">
                              <span className="material-icons-round" style={{ fontSize: "14px" }}>emoji_events</span>
                              {game.score}
                            </span>
                          )}
                          <small>
                            {new Date(game.playedAt).toLocaleDateString()}
                          </small>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          ) : null}
        </section>
      </div>
    </main>
  );
}
