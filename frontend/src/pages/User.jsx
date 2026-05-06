import { useState, useEffect, useContext } from "react";
import AuthContext from "../context/AuthContext";
import LogoutButton from "../components/LogoutButton";
import logo from "../assets/logo-removebg-preview.png";
import "./User.css";

import DashboardView from "./views/DashboardView";
import StudyHistoryView from "./views/StudyHistoryView";
import SettingsView from "./views/SettingsView";
import FriendsView from "./views/FriendsView";
import InsightsView from "./views/InsightsView";

export default function User() {
  const { auth, setAuth } = useContext(AuthContext);
  const [activeView, setActiveView] = useState("dashboard");
  const [stats, setStats] = useState({
    firstName: "Loading...",
    sessionsCompleted: 0,
    availableGames: 0,
  });
  const [showFilter, setShowFilter] = useState(false);
  const [sortOrder, setSortOrder] = useState("latest");


  useEffect(() => {
    if (!auth.isAuthenticated) return;

    fetch("http://localhost:5000/auth/profile-stats", {
      credentials: "include",
      headers: {
      },
    })
      .then((res) => {
        if (res.status === 401) {
          setAuth({});
          throw new Error("Unauthorized");
        }
        return res.json();
      })
      .then(setStats)
      .catch((err) => {
        if (err.message !== "Unauthorized") console.error(err);
      });
  }, [auth.isAuthenticated, setAuth]);

  const renderContent = () => {
    switch (activeView) {
      case "history":
        return <StudyHistoryView />;
      case "profile":
        return <SettingsView />;
      case "friends":
        return <FriendsView />;
      case "insights":
        return <InsightsView />;
      default:
        return (
          <DashboardView
            stats={stats}
            showFilter={showFilter}
            onToggleFilter={() => setShowFilter((p) => !p)}
            onSortLatest={() => {
              setSortOrder("latest");
              setShowFilter(false);
            }}
            onSortOldest={() => {
              setSortOrder("oldest");
              setShowFilter(false);
            }}
            onOpenSettings={() => setActiveView("profile")}
            userId={auth.id}
          />
        );
    }
  };
  return (
    <div className="dashboard-layout">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <img src={logo} alt="TrustPrism Logo" />
          <span>TrustPrism</span>
        </div>

        <nav className="sidebar-nav">
          <a className={activeView === "dashboard" ? "active" : ""} onClick={() => setActiveView("dashboard")}>
            <span className="material-icons-round">dashboard</span>
            Dashboard
          </a>

          <a className={activeView === "history" ? "active" : ""} onClick={() => setActiveView("history")}>
            <span className="material-icons-round">sports_esports</span>
            Games
          </a>

          <a className={activeView === "friends" ? "active" : ""} onClick={() => setActiveView("friends")}>
            <span className="material-icons-round">group</span>
            Friends
          </a>

          <a className={activeView === "insights" ? "active" : ""} onClick={() => setActiveView("insights")}>
            <span className="material-icons-round">insights</span>
            Insights
          </a>

          <a className={activeView === "profile" ? "active" : ""} onClick={() => setActiveView("profile")}>
            <span className="material-icons-round">person</span>
            Profile
          </a>
        </nav>

        <div className="sidebar-footer">
          <LogoutButton />
        </div>
      </aside>

      {renderContent()}
    </div>
  );
}
