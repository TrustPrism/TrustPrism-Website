-- =============================================================================
-- TrustPrism Migration: Friends System + Comparative Insights
-- =============================================================================

-- 1. Add pseudonym column to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS pseudonym VARCHAR(50) UNIQUE;

-- 2. Generate pseudonyms for existing users who don't have one
-- (will be handled by the application layer on first access)

-- 3. Create friendships table
CREATE TABLE IF NOT EXISTS friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_friendship UNIQUE (requester_id, addressee_id),
    CONSTRAINT no_self_friend CHECK (requester_id != addressee_id)
);

-- Indexes for efficient friend lookups
CREATE INDEX IF NOT EXISTS idx_friendships_requester ON friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addressee ON friendships(addressee_id);
CREATE INDEX IF NOT EXISTS idx_friendships_status ON friendships(status);

-- Index for pseudonym search
CREATE INDEX IF NOT EXISTS idx_users_pseudonym ON users(pseudonym);
