import express from "express";
import { pool } from "../db.js";
import { requireAuth } from "../middleware/auth.js";

const router = express.Router();

/**
 * GET /analytics/user-percentiles
 * Compute overall percentiles for the authenticated user across ALL games.
 *
 * Returns:
 * {
 *   scorePercentile: 72,
 *   aiUsagePercentile: 81,
 *   speedPercentile: 43,
 *   userAvgScore: 85,
 *   globalAvgScore: 74,
 *   userAvgAiUsage: 12,
 *   globalAvgAiUsage: 10,
 *   userAvgSpeed: 320,
 *   globalAvgSpeed: 280,
 *   totalParticipants: 45
 * }
 */
router.get("/user-percentiles", requireAuth, async (req, res) => {
  const userId = req.user.id;

  try {
    // 1. Get user's average score
    const userScoreRes = await pool.query(
      `SELECT COALESCE(ROUND(AVG(score) FILTER (WHERE score IS NOT NULL))::int, 0) AS avg_score
       FROM game_sessions WHERE participant_id = $1 AND ended_at IS NOT NULL`,
      [userId]
    );
    const userAvgScore = userScoreRes.rows[0].avg_score;

    // 2. Get all participants' average scores for percentile calculation
    const allScoresRes = await pool.query(
      `SELECT participant_id,
              COALESCE(ROUND(AVG(score) FILTER (WHERE score IS NOT NULL))::int, 0) AS avg_score
       FROM game_sessions
       WHERE ended_at IS NOT NULL
       GROUP BY participant_id
       HAVING COUNT(*) FILTER (WHERE score IS NOT NULL) > 0`
    );

    // 3. Calculate score percentile
    const allScores = allScoresRes.rows.map(r => r.avg_score);
    const scorePercentile = calculatePercentile(userAvgScore, allScores);

    // 4. Get user's AI usage count
    const userAiRes = await pool.query(
      `SELECT COUNT(*)::int AS ai_count
       FROM ai_interaction_logs WHERE participant_id = $1`,
      [userId]
    );
    const userAiCount = userAiRes.rows[0].ai_count;

    // 5. Get all participants' AI usage for percentile
    const allAiRes = await pool.query(
      `SELECT participant_id, COUNT(*)::int AS ai_count
       FROM ai_interaction_logs
       GROUP BY participant_id`
    );
    const allAiCounts = allAiRes.rows.map(r => r.ai_count);
    const aiUsagePercentile = calculatePercentile(userAiCount, allAiCounts);

    // 6. Get user's average completion speed (seconds)
    const userSpeedRes = await pool.query(
      `SELECT COALESCE(
          ROUND(AVG(EXTRACT(EPOCH FROM (ended_at - started_at))))::int,
          0
       ) AS avg_speed
       FROM game_sessions
       WHERE participant_id = $1 AND ended_at IS NOT NULL`,
      [userId]
    );
    const userAvgSpeed = userSpeedRes.rows[0].avg_speed;

    // 7. Get all participants' average speeds for percentile
    const allSpeedsRes = await pool.query(
      `SELECT participant_id,
              COALESCE(ROUND(AVG(EXTRACT(EPOCH FROM (ended_at - started_at))))::int, 0) AS avg_speed
       FROM game_sessions
       WHERE ended_at IS NOT NULL
       GROUP BY participant_id`
    );
    // For speed, LOWER is better, so we invert the percentile
    const allSpeeds = allSpeedsRes.rows.map(r => r.avg_speed);
    const speedPercentile = calculatePercentileInverted(userAvgSpeed, allSpeeds);

    // 8. Global averages
    const globalAvgScore = allScores.length > 0
      ? Math.round(allScores.reduce((a, b) => a + b, 0) / allScores.length)
      : 0;
    const globalAvgAiUsage = allAiCounts.length > 0
      ? Math.round(allAiCounts.reduce((a, b) => a + b, 0) / allAiCounts.length)
      : 0;
    const globalAvgSpeed = allSpeeds.length > 0
      ? Math.round(allSpeeds.reduce((a, b) => a + b, 0) / allSpeeds.length)
      : 0;

    // Log event
    await pool.query(
      `INSERT INTO activity_logs (user_id, action_type, description, metadata)
       VALUES ($1, $2, $3, $4)`,
      [userId, "percentile_viewed", "User viewed comparative metrics", {
        scorePercentile,
        aiUsagePercentile,
        speedPercentile,
        timestamp: new Date()
      }]
    );

    res.json({
      scorePercentile,
      aiUsagePercentile,
      speedPercentile,
      userAvgScore,
      globalAvgScore,
      userAiUsage: userAiCount,
      globalAvgAiUsage,
      userAvgSpeed,
      globalAvgSpeed,
      totalParticipants: allScores.length || allSpeeds.length || 0
    });
  } catch (err) {
    console.error("Percentile calculation error:", err);
    res.status(500).json({ error: "Failed to compute percentiles" });
  }
});

/**
 * GET /analytics/user-percentiles/:gameId
 * Compute per-game percentiles for the authenticated user.
 */
router.get("/user-percentiles/:gameId", requireAuth, async (req, res) => {
  const userId = req.user.id;
  const { gameId } = req.params;

  try {
    // User's average score for this game
    const userScoreRes = await pool.query(
      `SELECT COALESCE(ROUND(AVG(score) FILTER (WHERE score IS NOT NULL))::int, 0) AS avg_score
       FROM game_sessions WHERE participant_id = $1 AND game_id = $2 AND ended_at IS NOT NULL`,
      [userId, gameId]
    );
    const userAvgScore = userScoreRes.rows[0].avg_score;

    // All participants' avg scores for this game
    const allScoresRes = await pool.query(
      `SELECT participant_id,
              COALESCE(ROUND(AVG(score) FILTER (WHERE score IS NOT NULL))::int, 0) AS avg_score
       FROM game_sessions
       WHERE game_id = $1 AND ended_at IS NOT NULL
       GROUP BY participant_id
       HAVING COUNT(*) FILTER (WHERE score IS NOT NULL) > 0`,
      [gameId]
    );
    const allScores = allScoresRes.rows.map(r => r.avg_score);
    const scorePercentile = calculatePercentile(userAvgScore, allScores);

    // User AI usage for this game
    const userAiRes = await pool.query(
      `SELECT COUNT(*)::int AS ai_count
       FROM ai_interaction_logs WHERE participant_id = $1 AND game_id = $2`,
      [userId, gameId]
    );
    const userAiCount = userAiRes.rows[0].ai_count;

    // All AI usage for this game
    const allAiRes = await pool.query(
      `SELECT participant_id, COUNT(*)::int AS ai_count
       FROM ai_interaction_logs WHERE game_id = $1
       GROUP BY participant_id`,
      [gameId]
    );
    const allAiCounts = allAiRes.rows.map(r => r.ai_count);
    const aiUsagePercentile = calculatePercentile(userAiCount, allAiCounts);

    // Speed for this game
    const userSpeedRes = await pool.query(
      `SELECT COALESCE(
          ROUND(AVG(EXTRACT(EPOCH FROM (ended_at - started_at))))::int, 0
       ) AS avg_speed
       FROM game_sessions
       WHERE participant_id = $1 AND game_id = $2 AND ended_at IS NOT NULL`,
      [userId, gameId]
    );
    const userAvgSpeed = userSpeedRes.rows[0].avg_speed;

    const allSpeedsRes = await pool.query(
      `SELECT participant_id,
              COALESCE(ROUND(AVG(EXTRACT(EPOCH FROM (ended_at - started_at))))::int, 0) AS avg_speed
       FROM game_sessions
       WHERE game_id = $1 AND ended_at IS NOT NULL
       GROUP BY participant_id`,
      [gameId]
    );
    const allSpeeds = allSpeedsRes.rows.map(r => r.avg_speed);
    const speedPercentile = calculatePercentileInverted(userAvgSpeed, allSpeeds);

    // Log event
    await pool.query(
      `INSERT INTO activity_logs (user_id, action_type, description, metadata)
       VALUES ($1, $2, $3, $4)`,
      [userId, "comparative_stats_viewed", "User viewed game-specific comparative stats", {
        gameId,
        scorePercentile,
        aiUsagePercentile,
        timestamp: new Date()
      }]
    );

    res.json({
      scorePercentile,
      aiUsagePercentile,
      speedPercentile,
      userAvgScore,
      userAiUsage: userAiCount,
      userAvgSpeed,
      totalParticipants: allScores.length
    });
  } catch (err) {
    console.error("Per-game percentile error:", err);
    res.status(500).json({ error: "Failed to compute game percentiles" });
  }
});

// ── Helper: calculate what percentage of values are below the given value ────
function calculatePercentile(value, allValues) {
  if (allValues.length === 0) return 0;
  const belowCount = allValues.filter(v => v < value).length;
  return Math.round((belowCount / allValues.length) * 100);
}

// ── Helper: inverted percentile (for metrics where lower is better) ─────────
function calculatePercentileInverted(value, allValues) {
  if (allValues.length === 0) return 0;
  const aboveCount = allValues.filter(v => v > value).length;
  return Math.round((aboveCount / allValues.length) * 100);
}

export default router;
