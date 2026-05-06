import express from "express";
import { pool } from "../db.js";
import { requireAuth } from "../middleware/auth.js";

const router = express.Router();

// ── GET /friends/search?q=<term> — Search users by name ─────────────────────
router.get("/search", requireAuth, async (req, res) => {
  const { q } = req.query;
  if (!q || q.trim().length < 2) {
    return res.status(400).json({ error: "Search term must be at least 2 characters" });
  }

  try {
    const { rows } = await pool.query(
      `SELECT u.id, u.first_name, u.last_name
       FROM users u
       WHERE (u.first_name ILIKE $1 OR u.last_name ILIKE $1
              OR (u.first_name || ' ' || u.last_name) ILIKE $1)
         AND u.id != $2
         AND u.role = 'user'
         AND u.status = 'active'
       LIMIT 20`,
      [`%${q.trim()}%`, req.user.id]
    );

    res.json(rows);
  } catch (err) {
    console.error("Friend search error:", err);
    res.status(500).json({ error: "Search failed" });
  }
});

// ── GET /friends — Get friend list (accepted) ──────────────────────────────
router.get("/", requireAuth, async (req, res) => {
  const userId = req.user.id;

  try {
    const { rows } = await pool.query(
      `SELECT
         f.id AS friendship_id,
         CASE WHEN f.requester_id = $1 THEN f.addressee_id ELSE f.requester_id END AS friend_id,
         u.first_name,
         u.last_name,
         f.created_at AS friends_since
       FROM friendships f
       JOIN users u ON u.id = CASE WHEN f.requester_id = $1 THEN f.addressee_id ELSE f.requester_id END
       WHERE (f.requester_id = $1 OR f.addressee_id = $1)
         AND f.status = 'accepted'
       ORDER BY f.created_at DESC`,
      [userId]
    );

    res.json(rows);
  } catch (err) {
    console.error("Failed to fetch friends:", err);
    res.status(500).json({ error: "Failed to fetch friends" });
  }
});

// ── GET /friends/requests — Get pending friend requests (incoming) ──────────
router.get("/requests", requireAuth, async (req, res) => {
  const userId = req.user.id;

  try {
    const { rows } = await pool.query(
      `SELECT f.id, f.requester_id, u.first_name AS requester_first_name,
              u.last_name AS requester_last_name, f.created_at
       FROM friendships f
       JOIN users u ON u.id = f.requester_id
       WHERE f.addressee_id = $1 AND f.status = 'pending'
       ORDER BY f.created_at DESC`,
      [userId]
    );

    res.json(rows);
  } catch (err) {
    console.error("Failed to fetch requests:", err);
    res.status(500).json({ error: "Failed to fetch friend requests" });
  }
});

// ── GET /friends/sent — Get outgoing pending requests ───────────────────────
router.get("/sent", requireAuth, async (req, res) => {
  const userId = req.user.id;

  try {
    const { rows } = await pool.query(
      `SELECT f.id, f.addressee_id, u.first_name AS addressee_first_name,
              u.last_name AS addressee_last_name, f.created_at
       FROM friendships f
       JOIN users u ON u.id = f.addressee_id
       WHERE f.requester_id = $1 AND f.status = 'pending'
       ORDER BY f.created_at DESC`,
      [userId]
    );

    res.json(rows);
  } catch (err) {
    console.error("Failed to fetch sent requests:", err);
    res.status(500).json({ error: "Failed to fetch sent requests" });
  }
});

// ── POST /friends/request — Send a friend request ───────────────────────────
router.post("/request", requireAuth, async (req, res) => {
  const { addresseeId } = req.body;
  const requesterId = req.user.id;

  if (!addresseeId) {
    return res.status(400).json({ error: "addresseeId is required" });
  }

  if (addresseeId === requesterId) {
    return res.status(400).json({ error: "Cannot send a friend request to yourself" });
  }

  try {
    // Check if target user exists
    const userCheck = await pool.query(
      "SELECT id FROM users WHERE id = $1 AND role = 'user' AND status = 'active'",
      [addresseeId]
    );
    if (userCheck.rowCount === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    // Check for existing friendship in either direction
    const existing = await pool.query(
      `SELECT id, status FROM friendships
       WHERE (requester_id = $1 AND addressee_id = $2)
          OR (requester_id = $2 AND addressee_id = $1)`,
      [requesterId, addresseeId]
    );

    if (existing.rowCount > 0) {
      const f = existing.rows[0];
      if (f.status === "accepted") {
        return res.status(400).json({ error: "You are already friends" });
      }
      if (f.status === "pending") {
        return res.status(400).json({ error: "A friend request is already pending" });
      }
      if (f.status === "rejected") {
        // Allow re-sending by updating to pending
        await pool.query(
          "UPDATE friendships SET status = 'pending', requester_id = $1, addressee_id = $2, updated_at = NOW() WHERE id = $3",
          [requesterId, addresseeId, f.id]
        );

        // Log event
        await pool.query(
          `INSERT INTO activity_logs (user_id, action_type, description, metadata)
           VALUES ($1, $2, $3, $4)`,
          [requesterId, "friend_request_sent", "Friend request re-sent", { addresseeId, timestamp: new Date() }]
        );

        return res.json({ message: "Friend request sent" });
      }
    }

    // Create new friendship
    await pool.query(
      `INSERT INTO friendships (requester_id, addressee_id, status)
       VALUES ($1, $2, 'pending')`,
      [requesterId, addresseeId]
    );

    // Log event via existing activity_logs
    await pool.query(
      `INSERT INTO activity_logs (user_id, action_type, description, metadata)
       VALUES ($1, $2, $3, $4)`,
      [requesterId, "friend_request_sent", "Friend request sent", { addresseeId, timestamp: new Date() }]
    );

    res.status(201).json({ message: "Friend request sent" });
  } catch (err) {
    console.error("Friend request error:", err);
    if (err.code === "23505") {
      return res.status(400).json({ error: "Friend request already exists" });
    }
    res.status(500).json({ error: "Failed to send friend request" });
  }
});

// ── POST /friends/respond — Accept or reject a friend request ───────────────
router.post("/respond", requireAuth, async (req, res) => {
  const { friendshipId, action } = req.body;
  const userId = req.user.id;

  if (!friendshipId || !["accept", "reject"].includes(action)) {
    return res.status(400).json({ error: "friendshipId and action (accept/reject) are required" });
  }

  try {
    const status = action === "accept" ? "accepted" : "rejected";

    const result = await pool.query(
      `UPDATE friendships
       SET status = $1, updated_at = NOW()
       WHERE id = $2 AND addressee_id = $3 AND status = 'pending'
       RETURNING *`,
      [status, friendshipId, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Friend request not found or already responded" });
    }

    // Log event
    const eventType = action === "accept" ? "friend_request_accepted" : "friend_request_rejected";
    await pool.query(
      `INSERT INTO activity_logs (user_id, action_type, description, metadata)
       VALUES ($1, $2, $3, $4)`,
      [userId, eventType, `Friend request ${action}ed`, {
        friendshipId,
        requesterId: result.rows[0].requester_id,
        timestamp: new Date()
      }]
    );

    res.json({ message: `Friend request ${action}ed` });
  } catch (err) {
    console.error("Friend respond error:", err);
    res.status(500).json({ error: "Failed to respond to friend request" });
  }
});

// ── DELETE /friends/:friendshipId — Remove a friend ─────────────────────────
router.delete("/:friendshipId", requireAuth, async (req, res) => {
  const { friendshipId } = req.params;
  const userId = req.user.id;

  try {
    const result = await pool.query(
      `DELETE FROM friendships
       WHERE id = $1 AND (requester_id = $2 OR addressee_id = $2)
       RETURNING *`,
      [friendshipId, userId]
    );

    if (result.rowCount === 0) {
      return res.status(404).json({ error: "Friendship not found" });
    }

    res.json({ message: "Friend removed" });
  } catch (err) {
    console.error("Friend remove error:", err);
    res.status(500).json({ error: "Failed to remove friend" });
  }
});

// ── GET /friends/profile/:friendId — View friend profile ────────────────────
router.get("/profile/:friendId", requireAuth, async (req, res) => {
  const { friendId } = req.params;
  const userId = req.user.id;

  try {
    // Verify they are actually friends
    const friendCheck = await pool.query(
      `SELECT id FROM friendships
       WHERE ((requester_id = $1 AND addressee_id = $2) OR (requester_id = $2 AND addressee_id = $1))
         AND status = 'accepted'`,
      [userId, friendId]
    );

    if (friendCheck.rowCount === 0) {
      return res.status(403).json({ error: "You are not friends with this user" });
    }

    // Get user name
    const userRes = await pool.query(
      "SELECT first_name, last_name FROM users WHERE id = $1",
      [friendId]
    );

    if (userRes.rowCount === 0) {
      return res.status(404).json({ error: "User not found" });
    }

    // Get game stats
    const statsRes = await pool.query(
      `SELECT
         COUNT(*)::int AS total_sessions,
         COUNT(DISTINCT game_id)::int AS games_played,
         COUNT(*) FILTER (WHERE ended_at IS NOT NULL)::int AS completed_sessions,
         COALESCE(ROUND(AVG(score) FILTER (WHERE score IS NOT NULL))::int, 0) AS avg_score
       FROM game_sessions
       WHERE participant_id = $1`,
      [friendId]
    );

    // Get AI usage frequency (count of ai_interaction_logs)
    const aiRes = await pool.query(
      `SELECT COUNT(*)::int AS ai_interactions
       FROM ai_interaction_logs
       WHERE participant_id = $1`,
      [friendId]
    );

    // Get recent games played
    const recentRes = await pool.query(
      `SELECT g.name AS game_name, g.category, gs.started_at, gs.score
       FROM game_sessions gs
       JOIN games g ON g.id = gs.game_id
       WHERE gs.participant_id = $1 AND gs.ended_at IS NOT NULL
       ORDER BY gs.started_at DESC
       LIMIT 5`,
      [friendId]
    );

    // Log event
    await pool.query(
      `INSERT INTO activity_logs (user_id, action_type, description, metadata)
       VALUES ($1, $2, $3, $4)`,
      [userId, "friend_profile_viewed", "Viewed friend profile", {
        viewedFriendId: friendId,
        timestamp: new Date()
      }]
    );

    res.json({
      firstName: userRes.rows[0].first_name,
      lastName: userRes.rows[0].last_name,
      gamesPlayed: statsRes.rows[0].games_played,
      gamesCompleted: statsRes.rows[0].completed_sessions,
      averageScore: statsRes.rows[0].avg_score,
      totalSessions: statsRes.rows[0].total_sessions,
      aiInteractions: aiRes.rows[0].ai_interactions,
      recentGames: recentRes.rows.map(r => ({
        gameName: r.game_name,
        category: r.category,
        playedAt: r.started_at,
        score: r.score
      }))
    });
  } catch (err) {
    console.error("Friend profile error:", err);
    res.status(500).json({ error: "Failed to fetch friend profile" });
  }
});

export default router;
