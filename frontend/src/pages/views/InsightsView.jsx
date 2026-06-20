import { useState, useEffect, useContext } from "react";
import AuthContext from "../../context/AuthContext";

const API = import.meta.env.VITE_API_URL || "";

export default function InsightsView() {
  const { auth } = useContext(AuthContext);
  const [percentiles, setPercentiles] = useState(null);
  const [loading, setLoading] = useState(true);
  const [myStats, setMyStats] = useState(null);

  useEffect(() => {
    if (!auth.isAuthenticated) return;
    loadInsights();
  }, [auth.isAuthenticated]);

  const loadInsights = async () => {
    setLoading(true);
    try {
      const [percRes, statsRes] = await Promise.all([
        fetch(`${API}/analytics/user-percentiles`, { credentials: "include" }),
        fetch(`${API}/participant/my-stats`, { credentials: "include" }),
      ]);

      if (percRes.ok) setPercentiles(await percRes.json());
      if (statsRes.ok) setMyStats(await statsRes.json());
    } catch (err) {
      console.error("Failed to load insights:", err);
    } finally {
      setLoading(false);
    }
  };

  const formatTime = (seconds) => {
    if (!seconds) return "0m";
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
  };

  const getPercentileColor = (percentile) => {
    if (percentile >= 75) return "#22c55e";
    if (percentile >= 50) return "#0ea5e9";
    if (percentile >= 25) return "#f59e0b";
    return "#ef4444";
  };

  const getPercentileLabel = (percentile) => {
    if (percentile >= 90) return "Exceptional";
    if (percentile >= 75) return "Above Average";
    if (percentile >= 50) return "Average";
    if (percentile >= 25) return "Below Average";
    return "Getting Started";
  };

  const getTrendIcon = (percentile) => {
    if (percentile >= 50) return "trending_up";
    return "trending_down";
  };

  if (loading) {
    return (
      <main className="dashboard-main">
        <div className="games-loading">
          <span className="material-icons-round spin">autorenew</span>
          <p>Loading your insights...</p>
        </div>
      </main>
    );
  }

  const noData = !percentiles || percentiles.totalParticipants === 0;

  return (
    <main className="dashboard-main">
      <header className="topbar">
        <h1>My Insights</h1>
      </header>

      {noData ? (
        <div className="insights-empty">
          <span className="material-icons-round" style={{ fontSize: "4rem", color: "#cbd5e1" }}>
            insights
          </span>
          <h3>No Data Yet</h3>
          <p>
            Play some games to see how you compare with other participants!
            <br />
            Your performance percentiles will appear here once there's enough
            data.
          </p>
        </div>
      ) : (
        <>
          {/* Hero Percentile Card */}
          <div className="insights-hero">
            <div className="insights-hero-inner">
              <div className="insights-hero-circle">
                <svg viewBox="0 0 120 120" className="insights-ring">
                  <circle
                    cx="60" cy="60" r="52"
                    fill="none"
                    stroke="#e2e8f0"
                    strokeWidth="8"
                  />
                  <circle
                    cx="60" cy="60" r="52"
                    fill="none"
                    stroke={getPercentileColor(percentiles.scorePercentile)}
                    strokeWidth="8"
                    strokeDasharray={`${(percentiles.scorePercentile / 100) * 327} 327`}
                    strokeLinecap="round"
                    transform="rotate(-90 60 60)"
                    className="insights-ring-fill"
                  />
                </svg>
                <div className="insights-hero-value">
                  <span className="insights-hero-number">
                    {percentiles.scorePercentile}
                  </span>
                  <span className="insights-hero-suffix">%ile</span>
                </div>
              </div>
              <div className="insights-hero-text">
                <h2>
                  You performed better than{" "}
                  <span style={{ color: getPercentileColor(percentiles.scorePercentile) }}>
                    {percentiles.scorePercentile}%
                  </span>{" "}
                  of participants
                </h2>
                <p className="insights-hero-sub">
                  Based on your average score across all games
                </p>
                <div className="insights-hero-comparison">
                  <div className="insights-compare-chip">
                    <span>Your Avg Score</span>
                    <strong>{percentiles.userAvgScore}</strong>
                  </div>
                  <span className="material-icons-round" style={{ color: "#94a3b8", fontSize: "20px" }}>
                    compare_arrows
                  </span>
                  <div className="insights-compare-chip">
                    <span>Global Avg</span>
                    <strong>{percentiles.globalAvgScore}</strong>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Metric Cards Grid */}
          <div className="insights-grid">
            {/* Score Percentile */}
            <div className="insights-card">
              <div className="insights-card-header">
                <div className="insights-card-icon" style={{ background: "#0ea5e915", color: "#0ea5e9" }}>
                  <span className="material-icons-round">emoji_events</span>
                </div>
                <span
                  className="insights-trend"
                  style={{ color: getPercentileColor(percentiles.scorePercentile) }}
                >
                  <span className="material-icons-round" style={{ fontSize: "18px" }}>
                    {getTrendIcon(percentiles.scorePercentile)}
                  </span>
                  {getPercentileLabel(percentiles.scorePercentile)}
                </span>
              </div>
              <h3 className="insights-card-title">Score Percentile</h3>
              <div className="insights-bar-container">
                <div
                  className="insights-bar-fill"
                  style={{
                    width: `${percentiles.scorePercentile}%`,
                    background: `linear-gradient(90deg, ${getPercentileColor(percentiles.scorePercentile)}80, ${getPercentileColor(percentiles.scorePercentile)})`,
                  }}
                />
              </div>
              <div className="insights-card-detail">
                <span>Your Avg: <strong>{percentiles.userAvgScore}</strong></span>
                <span>Global Avg: <strong>{percentiles.globalAvgScore}</strong></span>
              </div>
            </div>

            {/* AI Usage Percentile */}
            <div className="insights-card">
              <div className="insights-card-header">
                <div className="insights-card-icon" style={{ background: "#8b5cf615", color: "#8b5cf6" }}>
                  <span className="material-icons-round">smart_toy</span>
                </div>
                <span
                  className="insights-trend"
                  style={{ color: getPercentileColor(percentiles.aiUsagePercentile) }}
                >
                  <span className="material-icons-round" style={{ fontSize: "18px" }}>
                    {getTrendIcon(percentiles.aiUsagePercentile)}
                  </span>
                  {(() => {
                    const diff = percentiles.userAiUsage - percentiles.globalAvgAiUsage;
                    const pctDiff = percentiles.globalAvgAiUsage > 0
                      ? Math.abs(Math.round((diff / percentiles.globalAvgAiUsage) * 100))
                      : 0;
                    if (diff > 0) return `${pctDiff}% above avg`;
                    if (diff < 0) return `${pctDiff}% below avg`;
                    return "At average";
                  })()}
                </span>
              </div>
              <h3 className="insights-card-title">AI Reliance</h3>
              <div className="insights-bar-container">
                <div
                  className="insights-bar-fill"
                  style={{
                    width: `${percentiles.aiUsagePercentile}%`,
                    background: `linear-gradient(90deg, #8b5cf680, #8b5cf6)`,
                  }}
                />
              </div>
              <div className="insights-card-detail">
                <span>Your Uses: <strong>{percentiles.userAiUsage}</strong></span>
                <span>Global Avg: <strong>{percentiles.globalAvgAiUsage}</strong></span>
              </div>
            </div>

            {/* Speed Percentile */}
            <div className="insights-card">
              <div className="insights-card-header">
                <div className="insights-card-icon" style={{ background: "#14b8a615", color: "#14b8a6" }}>
                  <span className="material-icons-round">speed</span>
                </div>
                <span
                  className="insights-trend"
                  style={{ color: getPercentileColor(percentiles.speedPercentile) }}
                >
                  <span className="material-icons-round" style={{ fontSize: "18px" }}>
                    {getTrendIcon(percentiles.speedPercentile)}
                  </span>
                  {getPercentileLabel(percentiles.speedPercentile)}
                </span>
              </div>
              <h3 className="insights-card-title">Completion Speed</h3>
              <div className="insights-bar-container">
                <div
                  className="insights-bar-fill"
                  style={{
                    width: `${percentiles.speedPercentile}%`,
                    background: `linear-gradient(90deg, #14b8a680, #14b8a6)`,
                  }}
                />
              </div>
              <div className="insights-card-detail">
                <span>Your Avg: <strong>{formatTime(percentiles.userAvgSpeed)}</strong></span>
                <span>Global Avg: <strong>{formatTime(percentiles.globalAvgSpeed)}</strong></span>
              </div>
            </div>

            {/* Activity Summary */}
            <div className="insights-card">
              <div className="insights-card-header">
                <div className="insights-card-icon" style={{ background: "#f59e0b15", color: "#f59e0b" }}>
                  <span className="material-icons-round">bar_chart</span>
                </div>
              </div>
              <h3 className="insights-card-title">Your Activity</h3>
              {myStats && (
                <div className="insights-activity-stats">
                  <div className="insights-activity-row">
                    <span>Total Sessions</span>
                    <strong>{myStats.total_sessions}</strong>
                  </div>
                  <div className="insights-activity-row">
                    <span>Games Played</span>
                    <strong>{myStats.games_played}</strong>
                  </div>
                  <div className="insights-activity-row">
                    <span>Completed</span>
                    <strong>{myStats.completed_sessions}</strong>
                  </div>
                  <div className="insights-activity-row">
                    <span>Best Score</span>
                    <strong>{myStats.best_score}</strong>
                  </div>
                  <div className="insights-activity-row">
                    <span>Play Time</span>
                    <strong>{formatTime(myStats.total_play_time_seconds)}</strong>
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Participants Note */}
          <div className="insights-note">
            <span className="material-icons-round" style={{ fontSize: "16px", color: "#94a3b8" }}>info</span>
            <span>
              Percentiles are computed across{" "}
              <strong>{percentiles.totalParticipants}</strong> participants.
              These are anonymized comparative metrics — no individual data is exposed.
            </span>
          </div>
        </>
      )}
    </main>
  );
}
