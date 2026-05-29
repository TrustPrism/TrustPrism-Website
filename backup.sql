--
-- PostgreSQL database dump
--

\restrict qm5Bji1nidYOAdfkbxs5cq0ef0bcfZUS8euIXHTCpVzlTQUnhBji1cjYnOc7MtD

-- Dumped from database version 15.15 (Debian 15.15-1.pgdg13+1)
-- Dumped by pg_dump version 15.15 (Debian 15.15-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.activity_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    action_type text NOT NULL,
    description text,
    metadata jsonb,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.activity_logs OWNER TO trustuser;

--
-- Name: admins; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.admins (
    user_id uuid NOT NULL,
    super_admin boolean DEFAULT false
);


ALTER TABLE public.admins OWNER TO trustuser;

--
-- Name: ai_interaction_logs; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.ai_interaction_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    game_id uuid NOT NULL,
    session_id uuid NOT NULL,
    participant_id uuid,
    researcher_id uuid,
    event_type text NOT NULL,
    ai_model text,
    payload jsonb,
    metadata jsonb,
    created_at timestamp without time zone DEFAULT now(),
    ai_provider text,
    ai_model_version text,
    prompt_tokens integer,
    completion_tokens integer,
    latency_ms integer,
    flagged boolean DEFAULT false,
    flag_reason text
);


ALTER TABLE public.ai_interaction_logs OWNER TO trustuser;

--
-- Name: api_keys; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.api_keys (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    game_id uuid NOT NULL,
    key_hash text NOT NULL,
    key_prefix text NOT NULL,
    environment text DEFAULT 'development'::text NOT NULL,
    is_active boolean DEFAULT true,
    created_by uuid,
    created_at timestamp without time zone DEFAULT now(),
    last_used_at timestamp without time zone,
    revoked_at timestamp without time zone,
    CONSTRAINT api_keys_environment_check CHECK ((environment = ANY (ARRAY['development'::text, 'production'::text])))
);


ALTER TABLE public.api_keys OWNER TO trustuser;

--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid,
    action character varying(50) NOT NULL,
    target_id uuid,
    target_type character varying(20),
    details jsonb DEFAULT '{}'::jsonb,
    ip_address character varying(45),
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.audit_logs OWNER TO trustuser;

--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.chat_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    game_id uuid,
    group_id uuid,
    sender_id uuid NOT NULL,
    message text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT check_chat_context CHECK ((((game_id IS NOT NULL) AND (group_id IS NULL)) OR ((game_id IS NULL) AND (group_id IS NOT NULL))))
);


ALTER TABLE public.chat_messages OWNER TO trustuser;

--
-- Name: friendships; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.friendships (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    requester_id uuid NOT NULL,
    addressee_id uuid NOT NULL,
    status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    CONSTRAINT friendships_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'accepted'::character varying, 'rejected'::character varying])::text[]))),
    CONSTRAINT no_self_friend CHECK ((requester_id <> addressee_id))
);


ALTER TABLE public.friendships OWNER TO trustuser;

--
-- Name: game_sessions; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.game_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    game_id uuid NOT NULL,
    participant_id uuid NOT NULL,
    started_at timestamp without time zone DEFAULT now(),
    ended_at timestamp without time zone,
    score integer
);


ALTER TABLE public.game_sessions OWNER TO trustuser;

--
-- Name: games; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.games (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    game_type text NOT NULL,
    researcher_id uuid NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    description text,
    experimental_conditions jsonb,
    consent_form_url text,
    target_sample_size integer,
    irb_approval boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now(),
    group_id uuid,
    category text,
    age_group text,
    research_tags text[],
    ai_usage_type text DEFAULT 'none'::text,
    staging_url text,
    production_url text,
    demographic_filters jsonb,
    data_collection_config jsonb,
    irb_required boolean DEFAULT false,
    irb_number text,
    irb_document_url text,
    irb_approved boolean DEFAULT false,
    CONSTRAINT games_ai_usage_type_check CHECK ((ai_usage_type = ANY (ARRAY['none'::text, 'assistive'::text, 'adversarial'::text, 'adaptive'::text, 'generative'::text])))
);


ALTER TABLE public.games OWNER TO trustuser;

--
-- Name: login_attempts; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.login_attempts (
    id integer NOT NULL,
    email text NOT NULL,
    ip_address text,
    success boolean DEFAULT false,
    attempted_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.login_attempts OWNER TO trustuser;

--
-- Name: login_attempts_id_seq; Type: SEQUENCE; Schema: public; Owner: trustuser
--

CREATE SEQUENCE public.login_attempts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.login_attempts_id_seq OWNER TO trustuser;

--
-- Name: login_attempts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: trustuser
--

ALTER SEQUENCE public.login_attempts_id_seq OWNED BY public.login_attempts.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    type character varying(50) NOT NULL,
    message text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT now(),
    metadata jsonb
);


ALTER TABLE public.notifications OWNER TO trustuser;

--
-- Name: project_messages; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.project_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    project_id uuid NOT NULL,
    sender_id uuid NOT NULL,
    message text NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.project_messages OWNER TO trustuser;

--
-- Name: researcher_group_members; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.researcher_group_members (
    researcher_id uuid NOT NULL,
    group_id uuid NOT NULL,
    role text DEFAULT 'member'::text,
    joined_at timestamp without time zone DEFAULT now(),
    CONSTRAINT researcher_group_members_role_check CHECK ((role = ANY (ARRAY['member'::text, 'owner'::text])))
);


ALTER TABLE public.researcher_group_members OWNER TO trustuser;

--
-- Name: researcher_groups; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.researcher_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    description text,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.researcher_groups OWNER TO trustuser;

--
-- Name: researchers; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.researchers (
    user_id uuid NOT NULL,
    verified boolean DEFAULT false,
    access_scopes jsonb DEFAULT '{}'::jsonb
);


ALTER TABLE public.researchers OWNER TO trustuser;

--
-- Name: siem_logs; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.siem_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    event_type character varying(100) NOT NULL,
    ip_address character varying(45),
    details jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now(),
    category character varying(60) DEFAULT 'UNCATEGORIZED'::character varying
);


ALTER TABLE public.siem_logs OWNER TO trustuser;

--
-- Name: system_notices; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.system_notices (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    admin_id uuid,
    title character varying(255) NOT NULL,
    message text NOT NULL,
    type character varying(20) DEFAULT 'info'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    expires_at timestamp without time zone
);


ALTER TABLE public.system_notices OWNER TO trustuser;

--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.system_settings (
    id integer DEFAULT 1 NOT NULL,
    settings jsonb DEFAULT '{"mfaEnabled": false, "apiRateLimit": 100, "apiRateWindow": 60, "autoRevokeDays": 90, "sessionTimeout": 30, "lockoutDuration": 15, "maxLoginAttempts": 5, "maxApiKeysPerGame": 3, "passwordMinLength": 8, "dataExportApproval": false, "consentFormRequired": true, "irbApprovalRequired": true, "auditLogRetentionDays": 365, "passwordRequireNumber": true, "autoRevokeInactiveKeys": true, "passwordRequireSpecial": true, "passwordRequireUppercase": true}'::jsonb NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    updated_by uuid,
    CONSTRAINT system_settings_id_check CHECK ((id = 1))
);


ALTER TABLE public.system_settings OWNER TO trustuser;

--
-- Name: ticket_messages; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.ticket_messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    ticket_id uuid NOT NULL,
    sender_id uuid NOT NULL,
    sender_role character varying(20) NOT NULL,
    message text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    CONSTRAINT ticket_messages_sender_role_check CHECK (((sender_role)::text = ANY ((ARRAY['researcher'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.ticket_messages OWNER TO trustuser;

--
-- Name: tickets; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.tickets (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    title character varying(255) NOT NULL,
    description text NOT NULL,
    game_id uuid,
    created_by uuid NOT NULL,
    priority character varying(20) DEFAULT 'medium'::character varying NOT NULL,
    category character varying(30) DEFAULT 'other'::character varying NOT NULL,
    status character varying(20) DEFAULT 'open'::character varying NOT NULL,
    assigned_to uuid,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    is_change_request boolean DEFAULT false NOT NULL,
    change_type character varying(30),
    security_impact text,
    approval_status character varying(20),
    approved_by uuid,
    approved_at timestamp with time zone,
    approval_notes text,
    CONSTRAINT tickets_approval_status_check CHECK (((approval_status)::text = ANY ((ARRAY['pending'::character varying, 'approved'::character varying, 'disapproved'::character varying])::text[]))),
    CONSTRAINT tickets_category_check CHECK (((category)::text = ANY ((ARRAY['bug'::character varying, 'feature_request'::character varying, 'data_issue'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT tickets_change_type_check CHECK (((change_type)::text = ANY ((ARRAY['security_config'::character varying, 'access_rights'::character varying, 'system_config'::character varying, 'game_lifecycle'::character varying, 'account_management'::character varying, 'infrastructure'::character varying])::text[]))),
    CONSTRAINT tickets_priority_check CHECK (((priority)::text = ANY ((ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying])::text[]))),
    CONSTRAINT tickets_status_check CHECK (((status)::text = ANY ((ARRAY['open'::character varying, 'in_progress'::character varying, 'resolved'::character varying, 'closed'::character varying])::text[])))
);


ALTER TABLE public.tickets OWNER TO trustuser;

--
-- Name: user_consents; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.user_consents (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    game_id uuid NOT NULL,
    consent_form_url text,
    accepted_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.user_consents OWNER TO trustuser;

--
-- Name: user_emails; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.user_emails (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    email text NOT NULL,
    is_primary boolean DEFAULT false,
    is_verified boolean DEFAULT false,
    verification_token text,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.user_emails OWNER TO trustuser;

--
-- Name: users; Type: TABLE; Schema: public; Owner: trustuser
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email text NOT NULL,
    password_hash text NOT NULL,
    role text NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    first_name text,
    last_name text,
    dob date,
    is_verified boolean DEFAULT false,
    verification_token text,
    reset_token text,
    reset_token_expires timestamp with time zone,
    affiliation character varying(255),
    research_interests text[],
    api_key character varying(255),
    notification_prefs jsonb DEFAULT '{}'::jsonb,
    status character varying(20) DEFAULT 'active'::character varying,
    terms_accepted_at timestamp without time zone,
    demographics jsonb,
    last_login_at timestamp with time zone DEFAULT now(),
    country character varying(2) DEFAULT 'US'::character varying,
    is_tiso boolean DEFAULT false,
    mfa_token character varying(255),
    mfa_token_expires timestamp with time zone,
    session_version integer DEFAULT 1 NOT NULL,
    mfa_required boolean DEFAULT false NOT NULL,
    pseudonym character varying(50),
    CONSTRAINT users_role_check CHECK ((role = ANY (ARRAY['user'::text, 'researcher'::text, 'admin'::text])))
);


ALTER TABLE public.users OWNER TO trustuser;

--
-- Name: login_attempts id; Type: DEFAULT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.login_attempts ALTER COLUMN id SET DEFAULT nextval('public.login_attempts_id_seq'::regclass);


--
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.activity_logs (id, user_id, action_type, description, metadata, created_at) FROM stdin;
5621ec0c-5574-4611-a92d-0033f18d24be	928f1bb2-b360-44e0-a224-0d4d2271e9e4	create_project	Created project: test	{"projectId": "e75b3f36-d88d-4aef-9c68-da14be4ceea1"}	2026-02-02 15:04:31.719859
38cafa58-ac24-4a7b-bf03-0e4f9deb3d24	928f1bb2-b360-44e0-a224-0d4d2271e9e4	create_project	Created project: test1	{"projectId": "d56f7606-0485-478b-bd76-ef61b939dcc4"}	2026-02-04 20:51:12.490559
b0b2ff89-9c14-4825-addb-546c96eec1a3	928f1bb2-b360-44e0-a224-0d4d2271e9e4	create_project	Created project: test2	{"projectId": "bda9a2ba-3fe9-4cd5-a508-c9ed757faeef"}	2026-02-04 21:34:45.737431
735b6acd-aef5-4d30-9bba-59bb264a0dab	928f1bb2-b360-44e0-a224-0d4d2271e9e4	create_project	Created project: The dilemma	{"projectId": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b"}	2026-02-17 16:37:38.83936
ffda05e0-bb45-4e31-a357-c3505f86b1fb	3989bf59-8656-4b9f-a232-013e218cb610	hint_shown	Game event: hint_shown	{"source": "sdk", "game_id": "e75b3f36-d88d-4aef-9c68-da14be4ceea1", "event_data": {"level": 3, "hint_type": "directional", "ai_confidence": 0.85}, "session_id": "cd6b1a48-f4ec-410e-9959-785aa06afeaf"}	2026-02-18 02:26:33.842657
4f607562-52f8-43d4-9743-8c21bc75d5f2	3989bf59-8656-4b9f-a232-013e218cb610	hint_shown	Game event: hint_shown	{"source": "sdk", "game_id": "e75b3f36-d88d-4aef-9c68-da14be4ceea1", "event_data": {"level": 3}, "session_id": "eaf5f881-382a-4c95-8a01-3d6b42073a15"}	2026-02-18 02:26:58.092297
7d433bee-abe7-43d4-b8aa-36a833ea533a	3989bf59-8656-4b9f-a232-013e218cb610	hint_shown	Game event: hint_shown	{"source": "sdk", "game_id": "e75b3f36-d88d-4aef-9c68-da14be4ceea1", "event_data": {"level": 3}, "session_id": "b3f5d661-32cf-49bc-af12-c1778b6c9542"}	2026-02-18 02:27:27.059539
f11eb078-56fa-4f1c-96f3-dfc972834a1f	3989bf59-8656-4b9f-a232-013e218cb610	level_started	Game event: level_started	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"level": 1, "difficulty": "medium"}, "session_id": "4435b149-d6a3-43ee-ada3-f9c0bb5c623b"}	2026-02-18 02:55:45.445638
66b45f2f-7c49-4341-a094-b0c79d4f42d7	3989bf59-8656-4b9f-a232-013e218cb610	hint_shown	Game event: hint_shown	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"hint_type": "directional", "ai_confidence": 0.85, "player_position": {"x": 100, "y": 200}}, "session_id": "4435b149-d6a3-43ee-ada3-f9c0bb5c623b"}	2026-02-18 02:55:45.551315
1e4ba0b8-a46d-4313-81a0-6e4aca95a0cc	3989bf59-8656-4b9f-a232-013e218cb610	user_decision	Game event: user_decision	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"choice": "cooperate", "context": "prisoner_dilemma_round_3", "reaction_time_ms": 2340}, "session_id": "4435b149-d6a3-43ee-ada3-f9c0bb5c623b"}	2026-02-18 02:55:45.651864
58d9e6b6-bcb8-44a8-85fe-8c920403145b	3989bf59-8656-4b9f-a232-013e218cb610	level_started	Game event: level_started	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"level": 1, "difficulty": "medium"}, "session_id": "46bfb796-4d2d-4935-bfea-514c3ab978c0"}	2026-02-18 02:58:53.831303
f052d47f-db85-4270-9905-abab0bf49847	3989bf59-8656-4b9f-a232-013e218cb610	hint_shown	Game event: hint_shown	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"hint_type": "directional", "ai_confidence": 0.85, "player_position": {"x": 100, "y": 200}}, "session_id": "46bfb796-4d2d-4935-bfea-514c3ab978c0"}	2026-02-18 02:58:53.949925
63d573ab-9a79-4c42-b82d-fa00b875cffd	3989bf59-8656-4b9f-a232-013e218cb610	user_decision	Game event: user_decision	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"choice": "cooperate", "context": "prisoner_dilemma_round_3", "reaction_time_ms": 2340}, "session_id": "46bfb796-4d2d-4935-bfea-514c3ab978c0"}	2026-02-18 02:58:54.057879
f951ea4d-37ef-41b5-acd6-b9bc5b11f2d6	bdba264e-4a83-428d-9764-dc6d4a92c1d3	create_project	Created project: Workflow Test Project	{"projectId": "4fd4725d-b79b-4153-ab4f-9de997a4e21e"}	2026-02-23 00:39:41.020748
38cb4477-0d97-48ee-8233-7d5659c4088a	c076cb7a-e12a-49dd-ab07-03dec8b7addb	update_status	Project 4fd4725d-b79b-4153-ab4f-9de997a4e21e status changed to published	{"newStatus": "published", "oldStatus": "draft", "projectId": "4fd4725d-b79b-4153-ab4f-9de997a4e21e"}	2026-02-23 00:39:41.103292
dadc1629-87fa-4ebe-b850-432d9df91168	bdba264e-4a83-428d-9764-dc6d4a92c1d3	create_project	Created project: Workflow Test Project	{"projectId": "5b0ceca8-b761-442f-8918-91a2da63edfd"}	2026-02-23 00:40:05.728216
7f13aafa-ee28-4b88-9aaa-936ce54c248e	c076cb7a-e12a-49dd-ab07-03dec8b7addb	update_status	Project 5b0ceca8-b761-442f-8918-91a2da63edfd status changed to pending_review	{"newStatus": "pending_review", "oldStatus": "draft", "projectId": "5b0ceca8-b761-442f-8918-91a2da63edfd"}	2026-02-23 00:40:05.76219
6ba03b3a-4a6a-4cbb-a5a1-bad729876a9f	bdba264e-4a83-428d-9764-dc6d4a92c1d3	update_status	Project 5b0ceca8-b761-442f-8918-91a2da63edfd status changed to draft	{"newStatus": "draft", "oldStatus": "pending_review", "projectId": "5b0ceca8-b761-442f-8918-91a2da63edfd"}	2026-02-23 00:40:05.789568
e5578de5-86fa-4062-b89c-dca027e6be11	c076cb7a-e12a-49dd-ab07-03dec8b7addb	update_status	Project 5b0ceca8-b761-442f-8918-91a2da63edfd status changed to pending_review	{"newStatus": "pending_review", "oldStatus": "draft", "projectId": "5b0ceca8-b761-442f-8918-91a2da63edfd"}	2026-02-23 00:40:05.817698
1cc01e77-8130-4574-a37c-04181e638ca2	bdba264e-4a83-428d-9764-dc6d4a92c1d3	update_status	Project 5b0ceca8-b761-442f-8918-91a2da63edfd status changed to publish_requested	{"newStatus": "publish_requested", "oldStatus": "pending_review", "projectId": "5b0ceca8-b761-442f-8918-91a2da63edfd"}	2026-02-23 00:40:05.843781
c5f5f9dd-acda-4339-b839-f6b8a830962a	c076cb7a-e12a-49dd-ab07-03dec8b7addb	update_status	Project 5b0ceca8-b761-442f-8918-91a2da63edfd status changed to published	{"newStatus": "published", "oldStatus": "publish_requested", "projectId": "5b0ceca8-b761-442f-8918-91a2da63edfd"}	2026-02-23 00:40:05.869575
ae090a38-a9f4-4051-bb23-95440b71c220	928f1bb2-b360-44e0-a224-0d4d2271e9e4	update_status	Project afdcf866-2f7c-477e-8d19-7ef47d7bc92b status changed to draft	{"newStatus": "draft", "oldStatus": "pending_review", "projectId": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b"}	2026-02-23 00:50:09.451585
0e1aebfd-52b3-4603-9e9b-289ffa8d577a	928f1bb2-b360-44e0-a224-0d4d2271e9e4	update_status	Project afdcf866-2f7c-477e-8d19-7ef47d7bc92b status changed to publish_requested	{"newStatus": "publish_requested", "oldStatus": "pending_review", "projectId": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b"}	2026-02-23 00:50:39.171513
7454381e-671a-4793-84a9-bf220226d59c	3989bf59-8656-4b9f-a232-013e218cb610	round_started	Game event: round_started	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"round": 1}, "session_id": "c138828d-a887-4c60-9d19-b5541b85b4ce"}	2026-02-24 12:54:37.876941
51c0833c-8e93-48e4-ac6d-120593b74324	3989bf59-8656-4b9f-a232-013e218cb610	round_started	Game event: round_started	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"round": 1}, "session_id": "ba01b2a3-a69f-4303-bdb7-10f7f27ffe3a"}	2026-02-24 13:00:35.748318
a51485e7-0fda-4f85-9cff-2be733e4d8b0	3989bf59-8656-4b9f-a232-013e218cb610	round_started	Game event: round_started	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"round": 1}, "session_id": "88e46f05-b629-4f44-9f51-2f7d59465e1e"}	2026-02-24 13:07:35.491031
7ca8901d-eb45-492c-aad7-d07aea27cc50	3989bf59-8656-4b9f-a232-013e218cb610	round_started	Game event: round_started	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"round": 1}, "session_id": "fe78ab4c-a5d4-46a5-b177-042984534d07"}	2026-02-24 13:21:31.975789
06a0d396-e898-44ac-a4af-2c897ca3d000	3989bf59-8656-4b9f-a232-013e218cb610	round_started	Game event: round_started	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"round": 1}, "session_id": "312b20d9-c4d4-4eb0-bc84-bf0ebfcc8058"}	2026-02-24 13:23:24.060228
7e27a6d3-bc5f-4d02-a9dd-6c0f6cfbe07e	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	round_started	Game event: round_started	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"round": 1}, "session_id": "66a36ce2-abe7-4d37-adfd-e12462617f09"}	2026-02-24 15:20:58.943257
3c1f9633-aa17-460e-a7d9-83e5b26a8abd	928f1bb2-b360-44e0-a224-0d4d2271e9e4	create_project	Created project: 	{"projectId": "0fb8229d-f187-4bfc-ac65-53cfd78003d8"}	2026-03-04 17:46:21.953917
ebef1938-fecc-46a5-9e3b-37c5dc2dd095	928f1bb2-b360-44e0-a224-0d4d2271e9e4	create_project	Created project: Tanvi Agrawal	{"projectId": "d5168fd1-6813-452b-b0b3-42c545cc00b6"}	2026-03-04 17:47:18.524636
55311079-ff7a-432b-882a-9ddeb9e36287	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	round_started	Game event: round_started	{"source": "sdk", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "event_data": {"round": 1}, "session_id": "d1a3be4c-80fa-4b35-887c-f5805b4c604f"}	2026-03-04 22:46:31.5614
372ed63d-84f3-42d3-8b08-a85eb098aa58	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T18:16:38.163Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 18:16:38.164779
35df2708-cc90-4b8b-ab7d-77e58ae053f1	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T18:16:38.204Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 18:16:38.205402
7312d9f0-74d1-438e-bc65-a4039d358672	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T18:29:42.041Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 18:29:42.041893
0fe1eb22-14c8-4178-af43-8ce458e6f433	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T18:29:42.082Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 18:29:42.082818
f8119b24-3a2a-4cf6-bffd-b2f9715f3916	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T18:30:18.002Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 18:30:18.002565
44982146-d0ba-45db-bb50-df734e51cc79	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T18:30:18.035Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 18:30:18.036285
47dc56c9-d612-42d1-911f-aa052c173c6b	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T18:30:25.033Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 18:30:25.033503
5bbfc3ed-fbb4-40ef-9176-741da0646098	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T18:30:25.066Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 18:30:25.067304
c45e187a-bbef-4cf2-8913-94af036f9786	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T19:09:37.313Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 19:09:37.314001
0e7a789e-9198-43e9-a041-98e60747bfba	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T19:09:37.351Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 19:09:37.352262
657da8b6-10b7-4080-bd50-a2544d0c434c	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	friend_request_sent	Friend request sent	{"timestamp": "2026-05-06T19:11:57.994Z", "addresseeId": "3989bf59-8656-4b9f-a232-013e218cb610"}	2026-05-06 19:11:57.995051
45951c5a-d4bd-4228-be3e-de41f456e393	c21e502b-5557-4231-9b5f-662fa0cb455b	friend_request_sent	Friend request sent	{"timestamp": "2026-05-06T19:24:08.695Z", "addresseeId": "b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb"}	2026-05-06 19:24:08.695629
3fdc0732-d86e-468e-b05d-f8148c02cc3b	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	friend_request_accepted	Friend request accepted	{"timestamp": "2026-05-06T19:24:38.324Z", "requesterId": "c21e502b-5557-4231-9b5f-662fa0cb455b", "friendshipId": "7abb5546-7f77-4d11-8aa0-c01d8989392b"}	2026-05-06 19:24:38.32572
e41cb23f-a8e3-44b7-8ed0-c5be12bbb3c9	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	friend_profile_viewed	Viewed friend profile	{"timestamp": "2026-05-06T19:24:40.113Z", "viewedFriendId": "c21e502b-5557-4231-9b5f-662fa0cb455b"}	2026-05-06 19:24:40.114007
06adf0b2-aeb1-4d77-9044-4423190d4846	c21e502b-5557-4231-9b5f-662fa0cb455b	friend_profile_viewed	Viewed friend profile	{"timestamp": "2026-05-06T19:24:51.424Z", "viewedFriendId": "b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb"}	2026-05-06 19:24:51.424864
c1cc933f-93a2-42cd-9bef-98a45b26539c	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T19:25:01.336Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 19:25:01.337261
81990681-b298-478e-b943-94c600006d47	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T19:25:01.378Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 19:25:01.378982
0dc04747-6140-435c-9e3c-78092c1ea1ee	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T19:25:08.164Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 19:25:08.164993
ab22650a-d6d0-495b-aba7-ebfd4e693e21	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T19:25:08.196Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 19:25:08.197041
eae749e4-1072-468e-94d2-9060a3129bc1	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T21:02:26.488Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 21:02:26.489518
1117a205-eb01-4371-bf66-bd9ef9eb6f4a	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-06T21:02:26.523Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-06 21:02:26.524543
712a492d-2e44-4032-b5f8-f0ce120c512f	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	friend_profile_viewed	Viewed friend profile	{"timestamp": "2026-05-09T14:43:28.330Z", "viewedFriendId": "c21e502b-5557-4231-9b5f-662fa0cb455b"}	2026-05-09 14:43:28.331343
7e00b91e-3645-4226-bec4-a20a65344969	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-09T14:43:36.643Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-09 14:43:36.643938
05d5c916-3eae-4922-9d51-82110ead7652	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-09T14:43:36.674Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-09 14:43:36.675387
0e7d7a0f-4e2d-4a96-9f29-b2564575993f	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	friend_profile_viewed	Viewed friend profile	{"timestamp": "2026-05-09T14:44:07.806Z", "viewedFriendId": "c21e502b-5557-4231-9b5f-662fa0cb455b"}	2026-05-09 14:44:07.807111
53266441-06c8-4cc3-a818-da4d2680a4e4	c21e502b-5557-4231-9b5f-662fa0cb455b	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-09T14:44:43.799Z", "scorePercentile": 50, "speedPercentile": 100, "aiUsagePercentile": 0}	2026-05-09 14:44:43.800051
e80e1e27-4009-4b59-93f5-3ec2ae7db43b	c21e502b-5557-4231-9b5f-662fa0cb455b	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-09T14:44:43.834Z", "scorePercentile": 50, "speedPercentile": 100, "aiUsagePercentile": 0}	2026-05-09 14:44:43.835505
114d7887-4538-4cb0-aaec-721336fec057	c21e502b-5557-4231-9b5f-662fa0cb455b	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-09T14:44:45.152Z", "scorePercentile": 50, "speedPercentile": 100, "aiUsagePercentile": 0}	2026-05-09 14:44:45.153627
f5eb1474-ed4b-4724-91bb-3c6f098af194	c21e502b-5557-4231-9b5f-662fa0cb455b	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-09T14:44:45.185Z", "scorePercentile": 50, "speedPercentile": 100, "aiUsagePercentile": 0}	2026-05-09 14:44:45.185684
c0002895-cdea-4f70-9abe-efd549b490e2	c21e502b-5557-4231-9b5f-662fa0cb455b	friend_profile_viewed	Viewed friend profile	{"timestamp": "2026-05-09T14:44:58.374Z", "viewedFriendId": "b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb"}	2026-05-09 14:44:58.375589
7898d878-f6b5-4876-9719-66cf392624db	c21e502b-5557-4231-9b5f-662fa0cb455b	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-09T14:45:17.718Z", "scorePercentile": 50, "speedPercentile": 100, "aiUsagePercentile": 0}	2026-05-09 14:45:17.719041
7d1a738b-e1ec-4c54-9444-cdeef9e901fe	c21e502b-5557-4231-9b5f-662fa0cb455b	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-09T14:45:17.737Z", "scorePercentile": 50, "speedPercentile": 100, "aiUsagePercentile": 0}	2026-05-09 14:45:17.73784
17f0a5cc-0029-4b98-bf2e-52da0db543b7	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-09T14:45:28.504Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-09 14:45:28.504658
f3458c71-6fca-4e1e-b897-2baf79fee8e9	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	percentile_viewed	User viewed comparative metrics	{"timestamp": "2026-05-09T14:45:28.539Z", "scorePercentile": 0, "speedPercentile": 0, "aiUsagePercentile": 0}	2026-05-09 14:45:28.539673
\.


--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.admins (user_id, super_admin) FROM stdin;
c076cb7a-e12a-49dd-ab07-03dec8b7addb	t
\.


--
-- Data for Name: ai_interaction_logs; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.ai_interaction_logs (id, game_id, session_id, participant_id, researcher_id, event_type, ai_model, payload, metadata, created_at, ai_provider, ai_model_version, prompt_tokens, completion_tokens, latency_ms, flagged, flag_reason) FROM stdin;
12535e32-63d7-4443-b13d-04480db7e920	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	4435b149-d6a3-43ee-ada3-f9c0bb5c623b	3989bf59-8656-4b9f-a232-013e218cb610	\N	ai_error	gpt-4	{"prompt": "The player is stuck on level 3. Give a subtle hint without spoilers.", "response": null}	{}	2026-02-18 02:55:45.96257	openai	\N	0	0	171	t	LLM call failed: OpenAI API error 401: {\n  "error": {\n    "message": "Incorrect API key provided: sk-your-***************here. You can find your API key at https://platform.openai.com/account/api-keys.",\n    "type": "invalid_request_error",\n    "code": "invalid_api_key",\n    "param": null\n  },\n  "status": 401\n}
5bc5d3dd-58fe-4e28-bfc4-0d5fca3d5431	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	46bfb796-4d2d-4935-bfea-514c3ab978c0	3989bf59-8656-4b9f-a232-013e218cb610	\N	ai_error	gpt-4	{"prompt": "The player is stuck on level 3. Give a subtle hint without spoilers.", "response": null}	{}	2026-02-18 02:58:54.285887	openai	\N	0	0	129	t	LLM call failed: OpenAI API error 401: {\n  "error": {\n    "message": "Incorrect API key provided: sk-your-***************here. You can find your API key at https://platform.openai.com/account/api-keys.",\n    "type": "invalid_request_error",\n    "code": "invalid_api_key",\n    "param": null\n  },\n  "status": 401\n}
6fc7a2d8-0278-4220-bbc8-d5e4b4b18a00	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	c138828d-a887-4c60-9d19-b5541b85b4ce	3989bf59-8656-4b9f-a232-013e218cb610	\N	ai_error	gpt-4	{"prompt": "What is the sum of: 13, 11, 17, 2, 16?", "response": null}	{}	2026-02-24 12:54:38.139596	openai	\N	0	0	192	t	LLM call failed: OpenAI API error 401: {\n  "error": {\n    "message": "Incorrect API key provided: sk-your-***************here. You can find your API key at https://platform.openai.com/account/api-keys.",\n    "type": "invalid_request_error",\n    "code": "invalid_api_key",\n    "param": null\n  },\n  "status": 401\n}
3e4d81ed-4534-4534-8748-446e542195c0	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	ba01b2a3-a69f-4303-bdb7-10f7f27ffe3a	3989bf59-8656-4b9f-a232-013e218cb610	\N	ai_error	gpt-4	{"prompt": "What is the sum of: 14, 4, 20, 1, 6?", "response": null}	{}	2026-02-24 13:00:35.948359	openai	\N	0	0	131	t	LLM call failed: OpenAI API error 401: {\n  "error": {\n    "message": "Incorrect API key provided: sk-your-***************here. You can find your API key at https://platform.openai.com/account/api-keys.",\n    "type": "invalid_request_error",\n    "code": "invalid_api_key",\n    "param": null\n  },\n  "status": 401\n}
6747b4de-d744-4a74-94e9-13de26674ca8	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	88e46f05-b629-4f44-9f51-2f7d59465e1e	3989bf59-8656-4b9f-a232-013e218cb610	\N	ai_error	gpt-4	{"prompt": "What is the sum of: 9, 7, 7, 3, 2?", "response": null}	{}	2026-02-24 13:07:35.74031	openai	\N	0	0	169	t	LLM call failed: AI API error 404: [{\n  "error": {\n    "code": 404,\n    "message": "models/gemini-1.5-flash is not found for API version v1main, or is not supported for generateContent. Call ListModels to see the list of available models and their supported methods.",\n    "status": "NOT_FOUND"\n  }\n}\n]
52d2cce3-c24e-4458-977f-e350115d4d80	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	312b20d9-c4d4-4eb0-bc84-bf0ebfcc8058	3989bf59-8656-4b9f-a232-013e218cb610	\N	ai_suggestion	gemini-2.5-flash-lite	{"prompt": "What is the sum of: 14, 7, 15, 16, 16?", "response": "To find the sum of the numbers 14, 7, 15, 16, and 16, you need to add them all together.\\n\\nSum = 14 + 7 + 15 + 16 + 16\\n\\nYou can add them step-by-step:\\n14 + 7 = 21\\n21 + 15 = 36\\n36 + 16 = 52\\n52 + 16 = 68\\n\\nAlternatively, you can group the numbers for easier addition:\\n(14 + 16) + (7 + 15) + 16\\n30 + 22 + 16\\n52 + 16\\n68\\n\\nThe sum of 14, 7, 15, 16, and 16 is **68**."}	{"max_tokens": 300, "temperature": 0.7, "system_prompt": null}	2026-02-24 13:23:25.121128	gemini	gemini-2.5-flash-lite	26	192	994	f	\N
bfef47b4-410d-4a39-a130-b9284499f69c	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	66a36ce2-abe7-4d37-adfd-e12462617f09	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	\N	ai_suggestion	gemini-2.5-flash-lite	{"prompt": "What is the sum of: 12, 13, 10, 12, 10?", "response": "To find the sum of the numbers 12, 13, 10, 12, and 10, you simply add them all together:\\n\\n12 + 13 + 10 + 12 + 10 = 57\\n\\nThe sum is **57**."}	{"max_tokens": 300, "temperature": 0.7, "system_prompt": null}	2026-02-24 15:20:59.861885	gemini	gemini-2.5-flash-lite	27	66	855	f	\N
8026bc17-31b5-4cb5-a1c7-8cb65297cc51	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	d1a3be4c-80fa-4b35-887c-f5805b4c604f	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	\N	ai_error	gemini-2.5-flash-lite	{"prompt": "What is the sum of: 19, 12, 13, 10, 12?", "response": null}	{}	2026-03-04 22:46:31.909428	gemini	\N	0	0	233	t	LLM call failed: AI API error 429: [{\n  "error": {\n    "code": 429,\n    "message": "You exceeded your current quota, please check your plan and billing details. For more information on this error, head to: https://ai.google.dev/gemini-api/docs/rate-limits. To monitor your current usage, head to: https://ai.dev/rate-limit. ",\n    "status": "RESOURCE_EXHAUSTED"\n  }\n}\n]
\.


--
-- Data for Name: api_keys; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.api_keys (id, game_id, key_hash, key_prefix, environment, is_active, created_by, created_at, last_used_at, revoked_at) FROM stdin;
58fee863-14b7-4cb7-862f-abf4f13fd145	d56f7606-0485-478b-bd76-ef61b939dcc4	$2b$10$sn1VajBXYLyQ949uNjKJcOAm.aYIDONFG47GS/60WO.v7AavJNlDG	tp_dev_26fe4ae1	development	t	c076cb7a-e12a-49dd-ab07-03dec8b7addb	2026-02-17 16:43:46.323382	\N	\N
93686a2e-6bc1-41df-94f0-ac80d49c3128	e75b3f36-d88d-4aef-9c68-da14be4ceea1	$2b$10$0ifd8RHkOealIRdPrPV2HONyqeevoW8bHu.tADTdhZvuPBX2w5ML2	tp_dev_4a85f1c9	development	t	c076cb7a-e12a-49dd-ab07-03dec8b7addb	2026-02-18 02:26:01.028934	2026-02-18 02:27:27.322119	\N
2ae85638-88e4-4ce9-a636-6a5e37a1d6ef	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	$2b$10$unr5zLSlzGnOnQlfKiVuge1WbdmkfP4bagtdOd41Pqxseflv.Dv5K	tp_dev_f116cdbb	development	t	928f1bb2-b360-44e0-a224-0d4d2271e9e4	2026-02-17 16:37:38.83537	2026-03-04 22:46:31.674581	\N
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.audit_logs (id, admin_id, action, target_id, target_type, details, ip_address, created_at) FROM stdin;
\.


--
-- Data for Name: chat_messages; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.chat_messages (id, game_id, group_id, sender_id, message, created_at) FROM stdin;
\.


--
-- Data for Name: friendships; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.friendships (id, requester_id, addressee_id, status, created_at, updated_at) FROM stdin;
d5408caa-bc1a-4cfa-87e8-d2cb8d03e2df	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	3989bf59-8656-4b9f-a232-013e218cb610	pending	2026-05-06 19:11:57.967298	2026-05-06 19:11:57.967298
7abb5546-7f77-4d11-8aa0-c01d8989392b	c21e502b-5557-4231-9b5f-662fa0cb455b	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	accepted	2026-05-06 19:24:08.691756	2026-05-06 19:24:38.316072
\.


--
-- Data for Name: game_sessions; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.game_sessions (id, game_id, participant_id, started_at, ended_at, score) FROM stdin;
cd6b1a48-f4ec-410e-9959-785aa06afeaf	e75b3f36-d88d-4aef-9c68-da14be4ceea1	3989bf59-8656-4b9f-a232-013e218cb610	2026-02-18 02:26:33.428318	2026-02-18 02:26:34.017492	42
eaf5f881-382a-4c95-8a01-3d6b42073a15	e75b3f36-d88d-4aef-9c68-da14be4ceea1	3989bf59-8656-4b9f-a232-013e218cb610	2026-02-18 02:26:57.862091	2026-02-18 02:26:58.256417	42
b3f5d661-32cf-49bc-af12-c1778b6c9542	e75b3f36-d88d-4aef-9c68-da14be4ceea1	3989bf59-8656-4b9f-a232-013e218cb610	2026-02-18 02:27:26.714691	2026-02-18 02:27:27.322355	42
4435b149-d6a3-43ee-ada3-f9c0bb5c623b	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	3989bf59-8656-4b9f-a232-013e218cb610	2026-02-18 02:55:45.313769	2026-02-18 02:55:46.101375	1250
46bfb796-4d2d-4935-bfea-514c3ab978c0	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	3989bf59-8656-4b9f-a232-013e218cb610	2026-02-18 02:58:53.696773	2026-02-18 02:58:54.42233	1250
c138828d-a887-4c60-9d19-b5541b85b4ce	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	3989bf59-8656-4b9f-a232-013e218cb610	2026-02-24 12:54:37.798158	\N	\N
ba01b2a3-a69f-4303-bdb7-10f7f27ffe3a	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	3989bf59-8656-4b9f-a232-013e218cb610	2026-02-24 13:00:35.664487	\N	\N
88e46f05-b629-4f44-9f51-2f7d59465e1e	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	3989bf59-8656-4b9f-a232-013e218cb610	2026-02-24 13:07:35.398749	\N	\N
fe78ab4c-a5d4-46a5-b177-042984534d07	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	3989bf59-8656-4b9f-a232-013e218cb610	2026-02-24 13:21:31.899791	\N	\N
312b20d9-c4d4-4eb0-bc84-bf0ebfcc8058	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	3989bf59-8656-4b9f-a232-013e218cb610	2026-02-24 13:23:23.989349	2026-02-24 13:23:25.191515	-5
66a36ce2-abe7-4d37-adfd-e12462617f09	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	2026-02-24 15:20:58.866791	2026-02-24 15:20:59.924092	-5
d1a3be4c-80fa-4b35-887c-f5805b4c604f	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	2026-03-04 22:46:31.456025	\N	\N
\.


--
-- Data for Name: games; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.games (id, name, game_type, researcher_id, status, created_at, description, experimental_conditions, consent_form_url, target_sample_size, irb_approval, updated_at, group_id, category, age_group, research_tags, ai_usage_type, staging_url, production_url, demographic_filters, data_collection_config, irb_required, irb_number, irb_document_url, irb_approved) FROM stdin;
d56f7606-0485-478b-bd76-ef61b939dcc4	test1	decision_task	928f1bb2-b360-44e0-a224-0d4d2271e9e4	draft	2026-02-04 20:51:12.467179		{"ai_model": "gpt-4", "features": {"hints": true, "explanations": false, "recommendations": true, "confidenceScores": false}, "reliability": 0.8}	/uploads/consent_forms/1770238272394-ACL-2023-Econ-Impact.pdf	100	f	2026-02-18 13:08:49.160783	32790e09-9ba0-4eb6-8306-de615b100b42	\N	\N	\N	none	https://google.com	\N	\N	\N	f	\N	\N	f
e75b3f36-d88d-4aef-9c68-da14be4ceea1	test	decision_task	928f1bb2-b360-44e0-a224-0d4d2271e9e4	draft	2026-02-02 15:04:31.705308	bleh 	{"ai_model": "gpt-4", "reliability": 0.8}	/uploads/consent_forms/1770044671680-CS331_assignment_3.pdf	100	t	2026-02-18 13:10:18.943086	f338c6e9-2b85-408e-b7c8-1c93293e45c7	\N	\N	\N	none	https://test-staging.example.com	\N	\N	\N	f	\N	\N	f
4fd4725d-b79b-4153-ab4f-9de997a4e21e	Workflow Test Project	survey	bdba264e-4a83-428d-9764-dc6d4a92c1d3	published	2026-02-23 00:39:40.99738	Testing transitions	\N	\N	\N	f	2026-02-23 00:39:41.09765	\N	\N	\N	\N	none	\N	\N	\N	\N	f	\N	\N	f
afdcf866-2f7c-477e-8d19-7ef47d7bc92b	The dilemma	decision_task	928f1bb2-b360-44e0-a224-0d4d2271e9e4	published	2026-02-17 16:37:38.749729	fvnjbovsbo	{"ai_model": "gpt-4", "features": {"hints": true, "explanations": true, "recommendations": true, "confidenceScores": true}, "reliability": 0.8}	/uploads/consent_forms/1771346258686-Proposla Lab.pdf	100	f	2026-02-25 12:48:23.658563	f338c6e9-2b85-408e-b7c8-1c93293e45c7	computer_science	26-35	{ll}	assistive	http://localhost:5174/	http://localhost:5174/	\N	\N	f	\N	\N	f
5b0ceca8-b761-442f-8918-91a2da63edfd	Workflow Test Project	survey	bdba264e-4a83-428d-9764-dc6d4a92c1d3	published	2026-02-23 00:40:05.704177	Testing transitions	\N	/dummy.pdf	\N	t	2026-02-23 00:40:05.864662	\N	\N	\N	\N	none	\N	\N	\N	\N	f	\N	\N	f
\.


--
-- Data for Name: login_attempts; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.login_attempts (id, email, ip_address, success, attempted_at) FROM stdin;
1	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-02-23 00:39:42.266273
2	admin@example.com	127.0.0.1	t	2026-02-23 00:40:18.402563
3	admin@example.com	127.0.0.1	t	2026-02-23 14:00:19.310708
4	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-02-23 14:00:43.752456
5	admin@example.com	127.0.0.1	t	2026-02-24 13:42:25.6872
6	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-02-24 13:45:07.229396
7	cherryberry363@gmail.com	127.0.0.1	t	2026-02-24 13:46:20.573006
8	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-02-24 13:51:38.74948
9	cherryberry363@gmail.com	127.0.0.1	t	2026-02-24 14:43:42.331352
10	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-02-24 15:52:54.643279
11	admin@example.com	127.0.0.1	t	2026-02-24 16:02:37.199584
12	cherryberry363@gmail.com	127.0.0.1	f	2026-02-25 12:44:44.982348
13	cherryberry363@gmail.com	127.0.0.1	t	2026-02-25 12:44:49.152444
14	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-02-25 12:45:17.246764
15	admin@example.com	127.0.0.1	t	2026-02-25 12:47:39.886729
16	cherryberry363@gmail.com	127.0.0.1	t	2026-02-25 12:49:54.439192
17	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-02-25 12:50:22.414334
18	admin@example.com	127.0.0.1	t	2026-02-25 12:50:59.731076
19	admin@example.com	127.0.0.1	t	2026-02-25 13:33:27.95911
20	admin@example.com	127.0.0.1	t	2026-02-25 19:50:20.733532
21	cherryberry363@gmail.com	127.0.0.1	t	2026-02-25 19:51:02.772713
22	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-02-25 19:51:16.34873
23	admin@example.com	127.0.0.1	t	2026-02-25 19:51:30.996983
24	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-02-25 21:06:08.849716
25	cherryberry363@gmail.com	127.0.0.1	t	2026-02-25 21:06:35.525752
26	admin@example.com	127.0.0.1	t	2026-02-25 21:06:56.117872
27	cherryberry363@gmail.com	127.0.0.1	t	2026-03-04 17:17:01.143362
28	admin@example.com	127.0.0.1	t	2026-03-04 17:18:40.714701
29	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-03-04 17:19:41.276182
30	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-03-04 17:53:43.153861
31	admin@example.com	127.0.0.1	f	2026-03-04 22:31:56.214242
32	admin@example.com	127.0.0.1	f	2026-03-04 22:31:56.650112
33	admin@example.com	127.0.0.1	t	2026-03-04 22:32:01.002796
34	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-03-04 22:32:31.815676
35	cherryberry363@gmail.com	127.0.0.1	t	2026-03-04 22:39:29.218641
36	tanviagrawal@utexas.edu	127.0.0.1	f	2026-03-18 19:00:43.334862
37	admin@example.com	127.0.0.1	t	2026-03-18 19:01:06.152459
38	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-03-18 19:01:34.049352
39	cherryberry363@gmail.com	127.0.0.1	t	2026-03-31 02:25:15.494057
40	cherryberry363@gmail.com	127.0.0.1	t	2026-03-31 02:55:56.088072
41	cherryberry363@gmail.com	127.0.0.1	t	2026-03-31 02:56:32.693302
42	cherryberry363@gmail.com	127.0.0.1	t	2026-03-31 02:56:51.684336
43	cherryberry363@gmail.com	127.0.0.1	t	2026-03-31 02:59:39.966548
44	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-03-31 03:08:10.302429
45	admin@example.com	127.0.0.1	f	2026-03-31 03:09:03.131094
46	admin@example.com	127.0.0.1	t	2026-03-31 03:09:07.442526
47	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-03-31 03:37:53.636923
48	admin@example.com	127.0.0.1	f	2026-03-31 04:10:54.182124
49	admin@example.com	127.0.0.1	t	2026-03-31 04:10:59.641285
50	cherryberry363@gmail.com	127.0.0.1	t	2026-03-31 04:13:06.139052
51	tanviagrawal@utexas.edu	127.0.0.1	t	2026-03-31 04:19:04.510966
52	tanviagrawal@utexas.edu	127.0.0.1	t	2026-03-31 04:19:04.995412
53	tanviagrawal@utexas.edu	127.0.0.1	t	2026-03-31 04:19:23.947749
54	tanviagrawal@utexas.edu	127.0.0.1	t	2026-03-31 04:19:32.149951
55	tanviagrawal@utexas.edu	127.0.0.1	t	2026-03-31 16:38:47.661419
56	tanviagrawal@utexas.edu	127.0.0.1	t	2026-03-31 16:38:58.395116
57	tanviagrawal@utexas.edu	127.0.0.1	t	2026-03-31 21:11:34.924174
58	tanviagrawal@utexas.edu	127.0.0.1	t	2026-03-31 21:11:35.808321
59	tanviagrawal@utexas.edu	127.0.0.1	t	2026-03-31 21:11:58.045774
60	tanviagrawal@utexas.edu	127.0.0.1	t	2026-03-31 21:11:59.804634
61	tanviagrawal@utexas.edu	127.0.0.1	t	2026-03-31 21:12:08.281831
62	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-04-05 22:33:07.998475
63	cherryberry363@gmail.com	127.0.0.1	t	2026-04-05 22:47:42.840836
64	tanviagrawal@utexas.edu	127.0.0.1	t	2026-04-05 22:48:22.419106
65	tanviagrawal@utexas.edu	127.0.0.1	t	2026-04-05 22:48:23.573901
66	tanviagrawal@utexas.edu	127.0.0.1	t	2026-04-05 22:48:43.57147
67	tanviagrawal@utexas.edu	127.0.0.1	t	2026-04-05 22:48:52.67608
68	cherryberry363@gmail.com	127.0.0.1	t	2026-04-05 22:53:28.710946
69	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-04-05 22:56:37.078978
70	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-04-05 23:17:15.86202
71	cherryberry363@gmail.com	127.0.0.1	t	2026-04-05 23:20:02.013738
72	cherryberry363@gmail.com	127.0.0.1	t	2026-04-13 18:38:15.016466
73	agrawaltanvi101@gmail.com	127.0.0.1	t	2026-04-13 18:52:59.367341
74	cherryberry363@gmail.com	127.0.0.1	t	2026-05-06 17:52:49.983728
75	tanviagrawal@utexas.edu	127.0.0.1	t	2026-05-06 19:10:31.418563
76	tanviagrawal@utexas.edu	127.0.0.1	t	2026-05-06 19:10:32.200883
77	tanviagrawal@utexas.edu	127.0.0.1	t	2026-05-06 19:10:46.284518
78	tanviagrawal@utexas.edu	127.0.0.1	t	2026-05-06 19:10:50.973807
79	tanviagrawal@utexas.edu	127.0.0.1	t	2026-05-06 19:11:02.489553
80	cherryberry363@gmail.com	127.0.0.1	t	2026-05-09 14:42:32.834601
81	tanviagraw1@gmail.com	127.0.0.1	t	2026-05-09 14:44:41.781758
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.notifications (id, user_id, type, message, is_read, created_at, metadata) FROM stdin;
837c4048-fe25-418a-9d9c-20457766a282	928f1bb2-b360-44e0-a224-0d4d2271e9e4	message	null null sent a message in "test1"	t	2026-02-17 01:35:30.317184	{"game_id": "d56f7606-0485-478b-bd76-ef61b939dcc4"}
3b70ce9c-1410-432c-867d-5855eb3cb5e3	928f1bb2-b360-44e0-a224-0d4d2271e9e4	message	null null sent a message in "test1"	t	2026-02-17 01:35:28.87602	{"game_id": "d56f7606-0485-478b-bd76-ef61b939dcc4"}
9b92c961-4396-4a50-902b-38e7dcb8e548	c076cb7a-e12a-49dd-ab07-03dec8b7addb	message	tanvi a sent a message in "test1"	t	2026-02-17 01:42:48.991676	{"game_id": "d56f7606-0485-478b-bd76-ef61b939dcc4"}
27bb125b-084c-4b2d-9646-13dc30559706	928f1bb2-b360-44e0-a224-0d4d2271e9e4	message	null null sent a message in "test1"	t	2026-02-17 01:43:17.334931	{"game_id": "d56f7606-0485-478b-bd76-ef61b939dcc4"}
37c18540-2331-4159-861e-4a18b9324c1e	928f1bb2-b360-44e0-a224-0d4d2271e9e4	message	null null sent a message in "test1"	t	2026-02-17 01:40:02.057021	{"game_id": "d56f7606-0485-478b-bd76-ef61b939dcc4"}
06eba4cc-00b7-4307-883f-4725d9172ea0	bdba264e-4a83-428d-9764-dc6d4a92c1d3	project_published	Your project "Workflow Test Project" has been published!	f	2026-02-23 00:39:41.10851	{"newStatus": "published", "projectId": "4fd4725d-b79b-4153-ab4f-9de997a4e21e"}
d1d1de0f-643b-448e-a90c-d88496ebf809	bdba264e-4a83-428d-9764-dc6d4a92c1d3	project_review	The project "Workflow Test Project" is ready for your review.	f	2026-02-23 00:40:05.768659	{"newStatus": "pending_review", "projectId": "5b0ceca8-b761-442f-8918-91a2da63edfd"}
0e04e826-edd5-49b2-9b5b-3d5f4a751bcd	bdba264e-4a83-428d-9764-dc6d4a92c1d3	project_review	The project "Workflow Test Project" is ready for your review.	f	2026-02-23 00:40:05.82361	{"newStatus": "pending_review", "projectId": "5b0ceca8-b761-442f-8918-91a2da63edfd"}
53663791-0fcd-4d70-8d03-0d6047f5fe15	bdba264e-4a83-428d-9764-dc6d4a92c1d3	project_published	Your project "Workflow Test Project" has been published!	f	2026-02-23 00:40:05.875518	{"newStatus": "published", "projectId": "5b0ceca8-b761-442f-8918-91a2da63edfd"}
56d85ccc-6242-4925-afa0-a73fda4e6630	c076cb7a-e12a-49dd-ab07-03dec8b7addb	project_changes_req	Changes requested for project "Workflow Test Project". It has been returned to draft.	t	2026-02-23 00:40:05.795996	{"newStatus": "draft", "projectId": "5b0ceca8-b761-442f-8918-91a2da63edfd"}
c82877ca-1b07-4199-be33-a73cb7e6987f	c076cb7a-e12a-49dd-ab07-03dec8b7addb	project_publish_req	Publish requested for project "Workflow Test Project". Ready for final launch.	t	2026-02-23 00:40:05.850448	{"newStatus": "publish_requested", "projectId": "5b0ceca8-b761-442f-8918-91a2da63edfd"}
18bac002-efb7-4036-bb5e-5b3f7422d919	928f1bb2-b360-44e0-a224-0d4d2271e9e4	project_review	The project "The dilemma" is ready for your review.	f	2026-02-23 00:50:22.327556	{"status": "pending_review", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "projectId": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b"}
e8b95431-2a6b-4936-910f-710f02854ecf	c076cb7a-e12a-49dd-ab07-03dec8b7addb	project_publish_req	Publish requested for project "The dilemma". Ready for final launch.	t	2026-02-23 00:50:39.180922	{"newStatus": "publish_requested", "projectId": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b"}
567b9d24-7106-4650-928b-a17b716f5034	c076cb7a-e12a-49dd-ab07-03dec8b7addb	project_changes_req	Changes requested for project "The dilemma". It has been returned to draft.	t	2026-02-23 00:50:09.459639	{"newStatus": "draft", "projectId": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b"}
a8f44ade-6c48-4dec-b1d3-d69d47699e57	928f1bb2-b360-44e0-a224-0d4d2271e9e4	project_review	The project "The dilemma" is ready for your review.	t	2026-02-23 00:49:54.351092	{"status": "pending_review", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "projectId": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b"}
ac56ae4a-ddf0-462b-8a52-7b09de468219	928f1bb2-b360-44e0-a224-0d4d2271e9e4	project_published	Your project "The dilemma" has been published!	f	2026-02-24 13:45:46.184641	{"status": "published", "game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "projectId": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b"}
6edca303-21ec-4175-a829-62478e8adaf3	c076cb7a-e12a-49dd-ab07-03dec8b7addb	ticket	tanvi a replied in ticket: "test"	f	2026-03-18 19:23:58.960294	{"game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "ticket_id": "8bc458d6-7dfc-4e30-8c63-3268c17d3264"}
7455450e-066c-4432-aeb9-7cc65e5ff663	928f1bb2-b360-44e0-a224-0d4d2271e9e4	ticket	null null replied to your ticket: "test"	t	2026-03-18 19:23:49.682996	{"game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "ticket_id": "8bc458d6-7dfc-4e30-8c63-3268c17d3264"}
6ee1a944-423c-49c9-82f3-3e400e7c92b5	c076cb7a-e12a-49dd-ab07-03dec8b7addb	ticket	tanvi a created ticket: "test"	t	2026-03-18 19:23:11.647958	{"game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "ticket_id": "8bc458d6-7dfc-4e30-8c63-3268c17d3264"}
467ad4e5-83eb-4990-ab69-35b0f9482850	3989bf59-8656-4b9f-a232-013e218cb610	ticket	test	f	2026-03-31 03:44:04.499485	{}
a24709e2-671e-4ea9-b9a2-a62ce85d81b9	928f1bb2-b360-44e0-a224-0d4d2271e9e4	ticket	null null marked your ticket "test" as in progress	f	2026-03-31 03:49:12.508547	{"game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "ticket_id": "8bc458d6-7dfc-4e30-8c63-3268c17d3264"}
108012b8-39c7-438c-9378-fb5b48e08081	928f1bb2-b360-44e0-a224-0d4d2271e9e4	ticket	null null marked your ticket "test" as resolved	f	2026-03-31 03:54:08.664606	{"game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "ticket_id": "8bc458d6-7dfc-4e30-8c63-3268c17d3264"}
7302b7c4-dcec-4ec1-8313-6a7587d98806	928f1bb2-b360-44e0-a224-0d4d2271e9e4	ticket	null null marked your ticket "test" as closed	f	2026-03-31 03:54:11.525908	{"game_id": "afdcf866-2f7c-477e-8d19-7ef47d7bc92b", "ticket_id": "8bc458d6-7dfc-4e30-8c63-3268c17d3264"}
\.


--
-- Data for Name: project_messages; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.project_messages (id, project_id, sender_id, message, created_at) FROM stdin;
ecddb101-73e4-4edb-8642-b4e7ba4b1566	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hi	2026-02-17 01:14:55.436189
6fc520ab-68ac-4471-9065-526c83fec591	d56f7606-0485-478b-bd76-ef61b939dcc4	928f1bb2-b360-44e0-a224-0d4d2271e9e4	hi	2026-02-17 01:15:25.15026
45669553-11d4-4393-b0d4-b416e4fe21a5	d56f7606-0485-478b-bd76-ef61b939dcc4	928f1bb2-b360-44e0-a224-0d4d2271e9e4	hi	2026-02-17 01:15:35.56572
17d124ce-10f2-43f8-ac46-ef4cc9c6ecb5	d56f7606-0485-478b-bd76-ef61b939dcc4	928f1bb2-b360-44e0-a224-0d4d2271e9e4	hi	2026-02-17 01:15:43.165276
0f13ab02-cc05-4512-8ada-8c8a586502de	d56f7606-0485-478b-bd76-ef61b939dcc4	928f1bb2-b360-44e0-a224-0d4d2271e9e4	hello	2026-02-17 01:15:50.558091
1b106238-a31d-4bd7-950b-bdc2e518e05b	d56f7606-0485-478b-bd76-ef61b939dcc4	928f1bb2-b360-44e0-a224-0d4d2271e9e4	hi	2026-02-17 01:18:56.740346
b63ed600-b950-4e4c-a22b-ae1d4dac8f8b	d56f7606-0485-478b-bd76-ef61b939dcc4	928f1bb2-b360-44e0-a224-0d4d2271e9e4	hel	2026-02-17 01:19:05.272197
7d1b9851-6de1-4132-b47c-e60b62b1327b	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hello	2026-02-17 01:19:38.380722
81ef8884-7629-48d2-9a7e-d66191445c42	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hi	2026-02-17 01:19:44.454759
e2b51907-5b0b-4558-9292-37f71737db46	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hello	2026-02-17 01:19:54.788978
c9bcafdd-6730-4969-9d4e-2ae3a2f4be3f	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hello	2026-02-17 01:19:59.180355
106b72ab-3c0e-417c-aed8-7e01718036a2	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	bruv	2026-02-17 01:21:23.65538
a9b181ea-c715-4f5d-aea8-74c322ae31ae	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hi	2026-02-17 01:23:39.552895
832b967c-4857-4434-8450-208d6901285a	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hi	2026-02-17 01:23:42.736368
56a20534-6e2a-4791-a7f9-822da5e1c3b3	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	bruv	2026-02-17 01:23:49.788275
f4142646-8745-4f7e-8c47-a218995611ac	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hi	2026-02-17 01:23:57.455389
34774bfb-3bf6-4d1d-9f2f-6d806aca2463	d56f7606-0485-478b-bd76-ef61b939dcc4	928f1bb2-b360-44e0-a224-0d4d2271e9e4	hi	2026-02-17 01:35:08.595335
0fe4cc04-b733-4080-a47d-2f56fee70cf0	d56f7606-0485-478b-bd76-ef61b939dcc4	928f1bb2-b360-44e0-a224-0d4d2271e9e4	hi hoe	2026-02-17 01:35:14.787362
431c6d2d-e8af-4c27-9373-d9c0fbf7d2e6	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hi	2026-02-17 01:35:28.868374
ac4f8860-730c-4549-9dce-fb374a550237	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hi	2026-02-17 01:35:30.310572
3d0a746c-e8a3-41b4-b038-488f1e0efd73	d56f7606-0485-478b-bd76-ef61b939dcc4	928f1bb2-b360-44e0-a224-0d4d2271e9e4	hi	2026-02-17 01:39:44.767311
792d8f0e-4dfb-428c-8375-7e66bdfa97a4	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hi	2026-02-17 01:40:02.050708
daf969a3-ed40-4892-8aef-6d425326ec84	d56f7606-0485-478b-bd76-ef61b939dcc4	928f1bb2-b360-44e0-a224-0d4d2271e9e4	hi	2026-02-17 01:42:48.980705
c1abdf85-263e-4dc0-b3cd-3de4131c6067	d56f7606-0485-478b-bd76-ef61b939dcc4	c076cb7a-e12a-49dd-ab07-03dec8b7addb	hi	2026-02-17 01:43:17.319723
\.


--
-- Data for Name: researcher_group_members; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.researcher_group_members (researcher_id, group_id, role, joined_at) FROM stdin;
bdba264e-4a83-428d-9764-dc6d4a92c1d3	1d9c0621-646f-4661-8704-a2714ad044f6	owner	2026-01-02 15:38:42.36599
928f1bb2-b360-44e0-a224-0d4d2271e9e4	f338c6e9-2b85-408e-b7c8-1c93293e45c7	owner	2026-01-10 15:31:54.400767
928f1bb2-b360-44e0-a224-0d4d2271e9e4	32790e09-9ba0-4eb6-8306-de615b100b42	owner	2026-02-02 13:26:37.053449
\.


--
-- Data for Name: researcher_groups; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.researcher_groups (id, name, description, created_by, created_at) FROM stdin;
1d9c0621-646f-4661-8704-a2714ad044f6	hello		bdba264e-4a83-428d-9764-dc6d4a92c1d3	2026-01-02 15:38:42.358523
f338c6e9-2b85-408e-b7c8-1c93293e45c7	hello		928f1bb2-b360-44e0-a224-0d4d2271e9e4	2026-01-10 15:31:54.39661
32790e09-9ba0-4eb6-8306-de615b100b42	bruv	Created via Dashboard	928f1bb2-b360-44e0-a224-0d4d2271e9e4	2026-02-02 13:26:37.044372
\.


--
-- Data for Name: researchers; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.researchers (user_id, verified, access_scopes) FROM stdin;
bdba264e-4a83-428d-9764-dc6d4a92c1d3	f	{}
928f1bb2-b360-44e0-a224-0d4d2271e9e4	t	{}
1638c73a-1f30-4660-a5cf-672ff2865420	f	{}
\.


--
-- Data for Name: siem_logs; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.siem_logs (id, user_id, event_type, ip_address, details, created_at, category) FROM stdin;
8d8d39d4-eeb3-4656-afce-a4e5e3eda4c8	c076cb7a-e12a-49dd-ab07-03dec8b7addb	LOGOUT_SUCCESS	127.0.0.1	{}	2026-03-31 04:10:38.509178+00	AUTH_AUTHORIZATION
6abda200-442f-402e-8752-a6eeb0345b0e	c076cb7a-e12a-49dd-ab07-03dec8b7addb	LOGIN_FAILED_PASSWORD	127.0.0.1	{"email": "admin@example.com"}	2026-03-31 04:10:54.185953+00	UNSUCCESSFUL_LOGON
c23eb32a-cda8-4751-bc53-72e586e32f0e	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	LOGIN_SUCCESS	127.0.0.1	{"role": "user"}	2026-03-31 04:13:06.148129+00	REMOTE_LOGON
67d7a492-1510-4efb-9c68-72d43d371ad5	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	LOGOUT_SUCCESS	127.0.0.1	{}	2026-03-31 04:13:08.976426+00	AUTH_AUTHORIZATION
f0c9a40d-a19a-43ae-b4fc-d9bc1446628a	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	MFA_FAILED	127.0.0.1	{"email": "tanviagrawal@utexas.edu"}	2026-03-31 04:19:23.953066+00	UNSUCCESSFUL_LOGON
3b40d53d-1e66-4cbf-9630-e965653bfd0e	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	MFA_SUCCESS	127.0.0.1	{"email": "tanviagrawal@utexas.edu"}	2026-03-31 04:19:32.158819+00	CONFIDENTIAL_DATA_HANDLING
77085b24-9c18-4d67-adee-578b618a42a8	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	LOGIN_SUCCESS	127.0.0.1	{"role": "admin"}	2026-03-31 04:19:32.167818+00	REMOTE_LOGON
c93fa332-acf5-40fd-9fd9-484ddcb30e48	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	MFA_SUCCESS	127.0.0.1	{"email": "tanviagrawal@utexas.edu"}	2026-03-31 16:38:58.406195+00	CONFIDENTIAL_DATA_HANDLING
9243f545-a37e-48e1-b2d8-529446d1c75f	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	LOGIN_SUCCESS	127.0.0.1	{"role": "admin"}	2026-03-31 16:38:58.416702+00	REMOTE_LOGON
be9a6f3d-5e7e-4d11-b0af-c0e55a686342	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_ROLE_UDPATE	127.0.0.1	{"new_role": "admin", "target_user_id": "5b3c83ca-7c81-4739-91f8-4354d37ef3c5"}	2026-03-31 16:39:13.159167+00	PRIVILEGED_ACCOUNT_ACTIVITY
ade07ecb-16a2-4955-bd97-8faefda57d71	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	MFA_FAILED	127.0.0.1	{"email": "tanviagrawal@utexas.edu"}	2026-03-31 21:11:58.055428+00	UNSUCCESSFUL_LOGON
f50c8606-2c60-4382-88e7-0a8742a0b411	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	MFA_FAILED	127.0.0.1	{"email": "tanviagrawal@utexas.edu"}	2026-03-31 21:11:59.8296+00	UNSUCCESSFUL_LOGON
6e26e845-79aa-41e3-9825-dee22c89896f	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	MFA_FAILED	127.0.0.1	{"email": "tanviagrawal@utexas.edu"}	2026-03-31 21:12:08.305947+00	UNSUCCESSFUL_LOGON
1d8f2240-70a7-478c-a656-4dd2e483855f	\N	APP_STARTUP	127.0.0.1	{"port": 5000}	2026-03-31 21:19:27.740292+00	UNCATEGORIZED
4fef4f01-96c7-4f54-b293-0368c0ab572e	\N	NETWORK_CONNECTION_ACCEPTED	127.0.0.1	{"socket_id": "KaKeBS8NM0T95bd8AAAC", "transport": "websocket"}	2026-03-31 21:19:28.855864+00	UNCATEGORIZED
7105d867-3ce5-44bb-8723-003d3cd030d4	\N	NETWORK_CONNECTION_ACCEPTED	127.0.0.1	{"socket_id": "8ENBNnNpenL-5_nwAAAD", "transport": "websocket"}	2026-03-31 21:19:28.872657+00	UNCATEGORIZED
e4a7ca49-d4ac-438a-a255-eea4f2226a0b	\N	APP_STARTUP	127.0.0.1	{"port": 5000}	2026-03-31 21:20:17.619227+00	UNCATEGORIZED
a199a6cf-46ae-41f8-b91e-ec0f89e2900a	\N	NETWORK_CONNECTION_ACCEPTED	127.0.0.1	{"socket_id": "CmB9wjSz687MBLAcAAAB", "transport": "websocket"}	2026-03-31 21:20:18.971828+00	UNCATEGORIZED
605f0d2f-7e6f-4744-9577-f5c2616ff553	\N	NETWORK_CONNECTION_ACCEPTED	127.0.0.1	{"socket_id": "fJMPI-xUgErLLBZZAAAD", "transport": "websocket"}	2026-03-31 21:20:19.547675+00	UNCATEGORIZED
74f4f0b1-b725-4f6f-bc5a-2368e4b51954	928f1bb2-b360-44e0-a224-0d4d2271e9e4	MFA_SKIPPED_DISABLED	127.0.0.1	{"role": "researcher", "email": "agrawaltanvi101@gmail.com"}	2026-04-05 22:33:08.037252+00	AUTH_AUTHORIZATION
31b19f27-6455-4fc2-919d-24d4504bad4a	928f1bb2-b360-44e0-a224-0d4d2271e9e4	LOGIN_SUCCESS	127.0.0.1	{"role": "researcher"}	2026-04-05 22:33:08.071669+00	REMOTE_LOGON
f4237803-887f-4fea-a3b4-f767e7423311	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	MFA_SKIPPED_DISABLED	127.0.0.1	{"role": "user", "email": "cherryberry363@gmail.com"}	2026-04-05 22:47:42.849671+00	AUTH_AUTHORIZATION
d2fb7e19-21a2-4265-a47f-fed64cf84be3	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	LOGIN_SUCCESS	127.0.0.1	{"role": "user"}	2026-04-05 22:47:42.870206+00	REMOTE_LOGON
a6ab03c4-975c-4307-9ffb-30f410980485	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	MFA_FAILED	127.0.0.1	{"email": "tanviagrawal@utexas.edu"}	2026-04-05 22:48:43.605454+00	UNSUCCESSFUL_LOGON
14679069-ee79-4114-8736-7bb9063a0bf1	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	MFA_SUCCESS	127.0.0.1	{"email": "tanviagrawal@utexas.edu"}	2026-04-05 22:48:52.711043+00	CONFIDENTIAL_DATA_HANDLING
aa345e79-71b9-4a75-b7e2-19d8bbc68449	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	LOGIN_SUCCESS	127.0.0.1	{"role": "admin"}	2026-04-05 22:48:52.724215+00	REMOTE_LOGON
6f22f229-1aa2-415f-8947-e3b8fa11593b	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_SYSTEM_TIME_CHECKED	127.0.0.1	{}	2026-04-05 22:49:01.946227+00	SYSTEM_CONFIG_CHANGE
c29f09ce-7497-4b72-aaae-4918ef0c4625	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_SYSTEM_TIME_CHECKED	127.0.0.1	{}	2026-04-05 22:49:02.032905+00	SYSTEM_CONFIG_CHANGE
de3dcd5f-f46c-4512-bdd7-8363f1392306	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_SYSTEM_TIME_CHECKED	127.0.0.1	{}	2026-04-05 22:49:42.968497+00	SYSTEM_CONFIG_CHANGE
3db066e9-e45f-4e77-8ac8-f728d960446b	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_SYSTEM_TIME_CHECKED	127.0.0.1	{}	2026-04-05 22:49:42.981233+00	SYSTEM_CONFIG_CHANGE
3fc43f41-bca4-44ab-8bd8-522d3200cd8c	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_SYSTEM_TIME_CHECKED	127.0.0.1	{}	2026-04-05 22:49:42.35945+00	SYSTEM_CONFIG_CHANGE
c3140a58-4f19-44ac-b740-a7f7816814e7	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_SYSTEM_TIME_CHECKED	127.0.0.1	{}	2026-04-05 22:49:42.382553+00	SYSTEM_CONFIG_CHANGE
fa4afef7-25c3-412b-b60c-898525cb57fc	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_SYSTEM_TIME_CHECKED	127.0.0.1	{}	2026-04-05 22:49:48.803759+00	SYSTEM_CONFIG_CHANGE
9368b119-2f26-4dae-b4d6-5e343fa3a8da	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_SYSTEM_TIME_CHECKED	127.0.0.1	{}	2026-04-05 22:49:48.843536+00	SYSTEM_CONFIG_CHANGE
a531fd04-d266-4056-b787-229fbd48ca90	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_SIEM_ACCESSED	127.0.0.1	{"limit": 200, "filters": {}}	2026-04-05 22:49:57.839657+00	PRIVILEGED_ACCOUNT_ACTIVITY
7b702567-381a-472d-bd11-a0d0f4fefbaa	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	MFA_SKIPPED_DISABLED	127.0.0.1	{"role": "user", "email": "cherryberry363@gmail.com"}	2026-04-05 22:53:28.738214+00	AUTH_AUTHORIZATION
00839fac-1cbb-49d4-9367-d2538532aa5a	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	LOGIN_SUCCESS	127.0.0.1	{"role": "user"}	2026-04-05 22:53:28.752886+00	REMOTE_LOGON
b509ea23-f5d0-4a62-835b-3b51192e1f62	928f1bb2-b360-44e0-a224-0d4d2271e9e4	MFA_SKIPPED_DISABLED	127.0.0.1	{"role": "researcher", "email": "agrawaltanvi101@gmail.com"}	2026-04-05 22:56:37.105098+00	AUTH_AUTHORIZATION
6b01dcdb-979a-4306-9005-5cd38d20f5e7	928f1bb2-b360-44e0-a224-0d4d2271e9e4	LOGIN_SUCCESS	127.0.0.1	{"role": "researcher"}	2026-04-05 22:56:37.11778+00	REMOTE_LOGON
4e5a4bdc-6d7f-4984-a93c-442583681ff7	928f1bb2-b360-44e0-a224-0d4d2271e9e4	MFA_SKIPPED_DISABLED	127.0.0.1	{"role": "researcher", "email": "agrawaltanvi101@gmail.com"}	2026-04-05 23:17:15.871176+00	AUTH_AUTHORIZATION
329a7f01-ff19-49f8-ae96-1e2385a09221	928f1bb2-b360-44e0-a224-0d4d2271e9e4	LOGIN_SUCCESS	127.0.0.1	{"role": "researcher"}	2026-04-05 23:17:15.886185+00	REMOTE_LOGON
41f4761b-2cef-4921-b17e-a998e588a67a	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_SYSTEM_TIME_CHECKED	127.0.0.1	{}	2026-04-05 23:19:26.528674+00	SYSTEM_CONFIG_CHANGE
7717d1fe-fa1b-4085-8f99-919da8266b66	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	ADMIN_SYSTEM_TIME_CHECKED	127.0.0.1	{}	2026-04-05 23:19:26.577371+00	SYSTEM_CONFIG_CHANGE
742d729b-2c08-4430-b4ed-3c83c840ce3d	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	LOGOUT_SUCCESS	127.0.0.1	{}	2026-04-05 23:19:55.786325+00	AUTH_AUTHORIZATION
c02ed6f3-551e-4791-8462-1a2ccd9cbe46	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	MFA_SKIPPED_DISABLED	127.0.0.1	{"role": "user", "email": "cherryberry363@gmail.com"}	2026-04-05 23:20:02.041212+00	AUTH_AUTHORIZATION
868512b1-27ea-41a1-a20e-afe70b43d9d6	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	LOGIN_SUCCESS	127.0.0.1	{"role": "user"}	2026-04-05 23:20:02.054318+00	REMOTE_LOGON
3d64fe8d-0706-4ab2-8611-89045cd1370a	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	MFA_SKIPPED_DISABLED	127.0.0.1	{"role": "user", "email": "cherryberry363@gmail.com"}	2026-04-13 18:38:15.025994+00	AUTH_AUTHORIZATION
a7de2223-ca43-48d5-b317-d5e9663efd41	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	LOGIN_SUCCESS	127.0.0.1	{"role": "user"}	2026-04-13 18:38:15.043525+00	REMOTE_LOGON
1ae17107-1972-4e8f-b55e-d6710fc0e58e	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	PROFILE_UPDATED	127.0.0.1	{"fields_updated": ["first_name", "last_name"]}	2026-04-13 18:50:02.938804+00	ACCOUNT_MANAGEMENT
708a73e4-8472-4cdc-a59a-aeb9f28d001c	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	PROFILE_UPDATED	127.0.0.1	{"fields_updated": ["first_name", "last_name"]}	2026-04-13 18:50:13.203555+00	ACCOUNT_MANAGEMENT
85f4cd6a-1dbb-40db-96c6-c068121e8803	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	LOGOUT_SUCCESS	127.0.0.1	{}	2026-04-13 18:52:40.316664+00	AUTH_AUTHORIZATION
b595c207-1e3c-453a-9334-9894495884db	928f1bb2-b360-44e0-a224-0d4d2271e9e4	MFA_SKIPPED_DISABLED	127.0.0.1	{"role": "researcher", "email": "agrawaltanvi101@gmail.com"}	2026-04-13 18:52:59.372127+00	AUTH_AUTHORIZATION
0d1c3385-cb38-423b-bf59-5e67e5f4646a	928f1bb2-b360-44e0-a224-0d4d2271e9e4	LOGIN_SUCCESS	127.0.0.1	{"role": "researcher"}	2026-04-13 18:52:59.381311+00	REMOTE_LOGON
28e1e001-47b0-414e-9174-8e8b8223250d	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	MFA_SKIPPED_DISABLED	127.0.0.1	{"role": "user", "email": "cherryberry363@gmail.com"}	2026-05-06 17:52:50.016124+00	AUTH_AUTHORIZATION
ff3a5797-ac7c-4385-81a5-198ff6f40f76	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	LOGIN_SUCCESS	127.0.0.1	{"role": "user"}	2026-05-06 17:52:50.061602+00	REMOTE_LOGON
d5cf826d-9a42-48e4-92a6-5d1667003f93	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	MFA_FAILED	127.0.0.1	{"email": "tanviagrawal@utexas.edu"}	2026-05-06 19:10:46.313095+00	UNSUCCESSFUL_LOGON
a4a21364-207e-4bdd-946c-9c974dc3bde8	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	MFA_FAILED	127.0.0.1	{"email": "tanviagrawal@utexas.edu"}	2026-05-06 19:10:51.00086+00	UNSUCCESSFUL_LOGON
cbd7195b-f905-4676-9797-cd097b314a18	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	MFA_SUCCESS	127.0.0.1	{"email": "tanviagrawal@utexas.edu"}	2026-05-06 19:11:02.52153+00	CONFIDENTIAL_DATA_HANDLING
0856a657-4d48-4dcc-bbaf-97c5b7b47da9	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	LOGIN_SUCCESS	127.0.0.1	{"role": "admin"}	2026-05-06 19:11:02.536958+00	REMOTE_LOGON
c672760e-44f9-4653-9807-94f4d88460a4	5b3c83ca-7c81-4739-91f8-4354d37ef3c5	LOGOUT_SUCCESS	127.0.0.1	{}	2026-05-06 19:13:18.118332+00	AUTH_AUTHORIZATION
d2c84bc9-1f5c-4c9c-9291-3b7195a0aea8	3989bf59-8656-4b9f-a232-013e218cb610	LOGIN_FAILED_UNVERIFIED	127.0.0.1	{"email": "ta@gmail.com"}	2026-05-06 19:14:26.55703+00	UNSUCCESSFUL_LOGON
36d0168d-c285-4310-8c5c-50606468a6c1	c21e502b-5557-4231-9b5f-662fa0cb455b	REGISTER_SUCCESS	127.0.0.1	{"role": "user"}	2026-05-06 19:24:00.344521+00	ACCOUNT_MANAGEMENT
cf974082-efcf-4892-8598-95286ec04cdc	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	MFA_SKIPPED_DISABLED	127.0.0.1	{"role": "user", "email": "cherryberry363@gmail.com"}	2026-05-09 14:42:32.843789+00	AUTH_AUTHORIZATION
04472294-e97d-46ec-bfc3-be82913c56b1	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	LOGIN_SUCCESS	127.0.0.1	{"role": "user"}	2026-05-09 14:42:32.872971+00	REMOTE_LOGON
db63c966-85ce-4379-98a4-a272c89e83fe	c21e502b-5557-4231-9b5f-662fa0cb455b	MFA_SKIPPED_DISABLED	127.0.0.1	{"role": "user", "email": "tanviagraw1@gmail.com"}	2026-05-09 14:44:41.786065+00	AUTH_AUTHORIZATION
d8fdd1b0-d16c-4218-a722-c88eee054d9f	c21e502b-5557-4231-9b5f-662fa0cb455b	LOGIN_SUCCESS	127.0.0.1	{"role": "user"}	2026-05-09 14:44:41.795727+00	REMOTE_LOGON
\.


--
-- Data for Name: system_notices; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.system_notices (id, admin_id, title, message, type, is_active, created_at, expires_at) FROM stdin;
\.


--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.system_settings (id, settings, updated_at, updated_by) FROM stdin;
1	{"mfaEnabled": false, "apiRateLimit": 100, "apiRateWindow": 60, "autoRevokeDays": 90, "sessionTimeout": 180, "lockoutDuration": 15, "maxLoginAttempts": 5, "maxApiKeysPerGame": 3, "passwordMinLength": 8, "dataExportApproval": false, "consentFormRequired": true, "irbApprovalRequired": true, "auditLogRetentionDays": 365, "passwordRequireNumber": true, "autoRevokeInactiveKeys": true, "passwordRequireSpecial": true, "passwordRequireUppercase": true}	2026-03-04 17:41:49.326469	c076cb7a-e12a-49dd-ab07-03dec8b7addb
\.


--
-- Data for Name: ticket_messages; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.ticket_messages (id, ticket_id, sender_id, sender_role, message, created_at) FROM stdin;
562c4b95-e825-4eed-a6f9-58a9bf0d92bd	8bc458d6-7dfc-4e30-8c63-3268c17d3264	c076cb7a-e12a-49dd-ab07-03dec8b7addb	admin	hi	2026-03-18 19:23:49.663425
2849f310-370f-42f8-8244-13158045715f	8bc458d6-7dfc-4e30-8c63-3268c17d3264	928f1bb2-b360-44e0-a224-0d4d2271e9e4	researcher	hi	2026-03-18 19:23:58.947335
\.


--
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.tickets (id, title, description, game_id, created_by, priority, category, status, assigned_to, created_at, updated_at, is_change_request, change_type, security_impact, approval_status, approved_by, approved_at, approval_notes) FROM stdin;
8bc458d6-7dfc-4e30-8c63-3268c17d3264	test	test	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	928f1bb2-b360-44e0-a224-0d4d2271e9e4	low	other	closed	\N	2026-03-18 19:23:11.635918	2026-03-31 03:54:11.516784	f	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: user_consents; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.user_consents (id, user_id, game_id, consent_form_url, accepted_at) FROM stdin;
da7980cb-7716-4be5-9f0e-4f449e9c767f	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	afdcf866-2f7c-477e-8d19-7ef47d7bc92b	/uploads/consent_forms/1771346258686-Proposla Lab.pdf	2026-03-04 17:17:09.239612
\.


--
-- Data for Name: user_emails; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.user_emails (id, user_id, email, is_primary, is_verified, verification_token, created_at) FROM stdin;
c8faa75f-94c0-4f9e-899e-1c29bbb727e8	3989bf59-8656-4b9f-a232-013e218cb610	ta@gmail.com	t	f	\N	2026-01-26 17:42:31.8417
75247189-cd23-4358-83f4-b7e4ff9eec5c	1638c73a-1f30-4660-a5cf-672ff2865420	ta1@gmail.com	t	f	\N	2026-01-26 17:42:31.8417
3a842a9b-ba5c-46d9-aa6d-e408462aaeb8	bdba264e-4a83-428d-9764-dc6d4a92c1d3	a1@gmail.com	t	f	\N	2026-01-26 17:42:31.8417
66bb4216-16fc-4129-bb8b-7b978126ecc9	928f1bb2-b360-44e0-a224-0d4d2271e9e4	agrawaltanvi101@gmail.com	t	t	\N	2026-01-26 17:42:31.8417
f70c7ab9-4dae-412b-bc02-cc711a5f7cd8	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	cherryberry363@gmail.com	t	t	\N	2026-01-26 17:42:31.8417
f52766eb-08e3-4570-8c02-bbad0a661316	c076cb7a-e12a-49dd-ab07-03dec8b7addb	admin@example.com	t	t	\N	2026-01-26 17:42:31.8417
e893bc3d-4011-4886-b651-6b9a7ebc00b1	b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	tanviagrawal@utexas.edu	f	t	\N	2026-01-26 19:57:25.932841
aa1137a6-ae16-4a6d-98e8-9c0fff305cd4	8dacbb48-d96d-4df5-b05b-61bd5e679e3c	testterms_ok@example.com	t	f	03b9553d0cc8496edd5175dcedae52fd7313022bac7910597b523996e41c21c2	2026-03-04 13:17:56.285575
29782035-d4ac-4ddf-a208-dae0ae324f2b	c21e502b-5557-4231-9b5f-662fa0cb455b	tanviagraw1@gmail.com	t	t	\N	2026-05-06 19:24:00.316583
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: trustuser
--

COPY public.users (id, email, password_hash, role, created_at, first_name, last_name, dob, is_verified, verification_token, reset_token, reset_token_expires, affiliation, research_interests, api_key, notification_prefs, status, terms_accepted_at, demographics, last_login_at, country, is_tiso, mfa_token, mfa_token_expires, session_version, mfa_required, pseudonym) FROM stdin;
c076cb7a-e12a-49dd-ab07-03dec8b7addb	admin@example.com	$2b$12$kEXY06ZNHsc.Y/F/rLjHkepQKpCKYZvu7KzB6jRZJJrljP8XFlxBC	admin	2025-12-23 01:59:52.78772	\N	\N	\N	t	\N	\N	\N	\N	\N	\N	{}	active	\N	\N	2026-03-31 04:06:53.355424+00	US	f	513048	2026-03-31 04:20:59.646392+00	1	t	\N
928f1bb2-b360-44e0-a224-0d4d2271e9e4	agrawaltanvi101@gmail.com	$2b$12$z/VXjc3VBfU5i/sbA9f15uGRdQgZ9KMV/.iqZioobyj1p0Bax1HXq	researcher	2026-01-10 15:31:53.805627	tanvi	a	\N	t	\N	\N	\N	\N	\N	\N	{}	active	\N	\N	2026-04-13 18:52:59.377906+00	US	f	\N	\N	1	f	\N
3989bf59-8656-4b9f-a232-013e218cb610	ta@gmail.com	$2b$12$gWwGvR.l5blYz1JTOYiwQe9R5bFUxa7DW8UsBRt26SDl3lqL7OI56	user	2026-01-02 04:09:19.157799	t	a	2007-02-01	f	\N	\N	\N	\N	\N	\N	{}	active	\N	\N	2026-03-31 04:06:53.355424+00	US	f	\N	\N	1	f	\N
bdba264e-4a83-428d-9764-dc6d4a92c1d3	a1@gmail.com	$2b$12$hqwbL.JmHzYrVIE4xitBb.S/jAvmwA14JrvDN.sIY9jG8g.NzrUBO	researcher	2026-01-02 15:38:42.346529	t	a	\N	f	\N	\N	\N	\N	\N	\N	{}	active	\N	\N	2026-03-31 04:06:53.355424+00	US	f	\N	\N	1	f	\N
b3e294c6-3d1a-4637-8cd0-52f01dd1f7cb	cherryberry363@gmail.com	$2b$12$vEqw89JuWKWQCw.Tq7KLFu5IjSOAI2OoBq/WK77DsvLASUz2H5rvy	user	2026-01-13 03:28:26.211144	tani	agr	2009-05-19	t	\N	\N	\N	\N	\N	\N	\N	active	\N	\N	2026-05-09 15:10:42.990606+00	US	f	\N	\N	1	f	EagerHeron52
1638c73a-1f30-4660-a5cf-672ff2865420	ta1@gmail.com	$2b$12$bv9F3mPgpObnDClfs7xJ/.uS9.jMSyp0Z1lrbarFWy6nbMp3m4sbO	user	2026-01-02 15:23:21.258933	t	a	2009-02-02	f	\N	\N	\N	\N	\N	\N	{}	active	\N	\N	2026-03-31 04:06:53.355424+00	US	f	\N	\N	1	f	\N
8dacbb48-d96d-4df5-b05b-61bd5e679e3c	testterms_ok@example.com	$2b$12$jiUKrWjzI.RtH1ZsW9qZDuCrFAYjhymRGJGHCdqzzAnvrUiN46MPe	user	2026-03-04 13:17:55.011174	Test	User	2000-01-01	f	03b9553d0cc8496edd5175dcedae52fd7313022bac7910597b523996e41c21c2	\N	\N	\N	\N	\N	{}	active	2026-03-04 07:17:55.009	\N	2026-03-31 04:06:53.355424+00	US	f	\N	\N	1	f	\N
c21e502b-5557-4231-9b5f-662fa0cb455b	tanviagraw1@gmail.com	$2b$12$Hrs4R4AOAmm8OK5LE484xeJMWQ.3mlsZapSDO7R1KfM/n71WvdY4y	user	2026-05-06 19:23:58.381462	t	aa	2010-05-06	t	\N	\N	\N	\N	\N	\N	{}	active	2026-05-06 14:23:58.379	\N	2026-05-09 15:12:21.624726+00	US	f	\N	\N	1	f	\N
5b3c83ca-7c81-4739-91f8-4354d37ef3c5	tanviagrawal@utexas.edu	$2b$12$Chl5UJnzfn.bRTUBFCDjSO92e4sa2xj0S6iSy.l/01eZz6tObqq3y	admin	2026-03-31 04:15:26.938818	Tanvi	Agrawal	\N	t	93aaf309445d002d5eca85cf32ebc5399995b29d31cfb8cecdab57791a6c42e0	\N	\N	\N	\N	\N	{}	active	2026-03-30 23:15:26.927	\N	2026-05-06 19:11:02.531336+00	US	t	\N	\N	1	t	\N
\.


--
-- Name: login_attempts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: trustuser
--

SELECT pg_catalog.setval('public.login_attempts_id_seq', 81, true);


--
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- Name: admins admins_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (user_id);


--
-- Name: ai_interaction_logs ai_interaction_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.ai_interaction_logs
    ADD CONSTRAINT ai_interaction_logs_pkey PRIMARY KEY (id);


--
-- Name: api_keys api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);


--
-- Name: friendships friendships_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.friendships
    ADD CONSTRAINT friendships_pkey PRIMARY KEY (id);


--
-- Name: game_sessions game_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.game_sessions
    ADD CONSTRAINT game_sessions_pkey PRIMARY KEY (id);


--
-- Name: games games_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT games_pkey PRIMARY KEY (id);


--
-- Name: login_attempts login_attempts_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.login_attempts
    ADD CONSTRAINT login_attempts_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: project_messages project_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.project_messages
    ADD CONSTRAINT project_messages_pkey PRIMARY KEY (id);


--
-- Name: researcher_group_members researcher_group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.researcher_group_members
    ADD CONSTRAINT researcher_group_members_pkey PRIMARY KEY (researcher_id, group_id);


--
-- Name: researcher_groups researcher_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.researcher_groups
    ADD CONSTRAINT researcher_groups_pkey PRIMARY KEY (id);


--
-- Name: researchers researchers_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.researchers
    ADD CONSTRAINT researchers_pkey PRIMARY KEY (user_id);


--
-- Name: siem_logs siem_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.siem_logs
    ADD CONSTRAINT siem_logs_pkey PRIMARY KEY (id);


--
-- Name: system_notices system_notices_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.system_notices
    ADD CONSTRAINT system_notices_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- Name: ticket_messages ticket_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.ticket_messages
    ADD CONSTRAINT ticket_messages_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: friendships unique_friendship; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.friendships
    ADD CONSTRAINT unique_friendship UNIQUE (requester_id, addressee_id);


--
-- Name: user_consents user_consents_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.user_consents
    ADD CONSTRAINT user_consents_pkey PRIMARY KEY (id);


--
-- Name: user_consents user_consents_user_id_game_id_key; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.user_consents
    ADD CONSTRAINT user_consents_user_id_game_id_key UNIQUE (user_id, game_id);


--
-- Name: user_emails user_emails_email_key; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.user_emails
    ADD CONSTRAINT user_emails_email_key UNIQUE (email);


--
-- Name: user_emails user_emails_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.user_emails
    ADD CONSTRAINT user_emails_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_pseudonym_key; Type: CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pseudonym_key UNIQUE (pseudonym);


--
-- Name: idx_ai_logs_event_type; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_ai_logs_event_type ON public.ai_interaction_logs USING btree (event_type);


--
-- Name: idx_ai_logs_session_id; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_ai_logs_session_id ON public.ai_interaction_logs USING btree (session_id);


--
-- Name: idx_api_keys_game; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_api_keys_game ON public.api_keys USING btree (game_id);


--
-- Name: idx_api_keys_prefix; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_api_keys_prefix ON public.api_keys USING btree (key_prefix);


--
-- Name: idx_audit_logs_admin_id; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_audit_logs_admin_id ON public.audit_logs USING btree (admin_id);


--
-- Name: idx_audit_logs_target_id; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_audit_logs_target_id ON public.audit_logs USING btree (target_id);


--
-- Name: idx_friendships_addressee; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_friendships_addressee ON public.friendships USING btree (addressee_id);


--
-- Name: idx_friendships_requester; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_friendships_requester ON public.friendships USING btree (requester_id);


--
-- Name: idx_friendships_status; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_friendships_status ON public.friendships USING btree (status);


--
-- Name: idx_game_sessions_game_id; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_game_sessions_game_id ON public.game_sessions USING btree (game_id);


--
-- Name: idx_login_attempts_email; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_login_attempts_email ON public.login_attempts USING btree (email);


--
-- Name: idx_login_attempts_time; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_login_attempts_time ON public.login_attempts USING btree (attempted_at);


--
-- Name: idx_notifications_user_id; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_notifications_user_id ON public.notifications USING btree (user_id);


--
-- Name: idx_project_messages_project_id; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_project_messages_project_id ON public.project_messages USING btree (project_id);


--
-- Name: idx_siem_logs_category; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_siem_logs_category ON public.siem_logs USING btree (category);


--
-- Name: idx_siem_logs_created_at; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_siem_logs_created_at ON public.siem_logs USING btree (created_at DESC);


--
-- Name: idx_siem_logs_user_id; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_siem_logs_user_id ON public.siem_logs USING btree (user_id);


--
-- Name: idx_ticket_messages_ticket_id; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_ticket_messages_ticket_id ON public.ticket_messages USING btree (ticket_id);


--
-- Name: idx_tickets_assigned_to; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_tickets_assigned_to ON public.tickets USING btree (assigned_to);


--
-- Name: idx_tickets_created_by; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_tickets_created_by ON public.tickets USING btree (created_by);


--
-- Name: idx_tickets_game_id; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_tickets_game_id ON public.tickets USING btree (game_id);


--
-- Name: idx_tickets_is_change_request; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_tickets_is_change_request ON public.tickets USING btree (is_change_request, approval_status) WHERE (is_change_request = true);


--
-- Name: idx_tickets_status; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_tickets_status ON public.tickets USING btree (status);


--
-- Name: idx_user_consents_game; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_user_consents_game ON public.user_consents USING btree (game_id);


--
-- Name: idx_user_consents_user; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_user_consents_user ON public.user_consents USING btree (user_id);


--
-- Name: idx_users_pseudonym; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_users_pseudonym ON public.users USING btree (pseudonym);


--
-- Name: idx_users_session_version; Type: INDEX; Schema: public; Owner: trustuser
--

CREATE INDEX idx_users_session_version ON public.users USING btree (id, session_version);


--
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: admins admins_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.admins
    ADD CONSTRAINT admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: api_keys api_keys_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id);


--
-- Name: api_keys api_keys_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.api_keys
    ADD CONSTRAINT api_keys_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: chat_messages chat_messages_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: chat_messages chat_messages_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.researcher_groups(id) ON DELETE CASCADE;


--
-- Name: chat_messages chat_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: ai_interaction_logs fk_ai_logs_game; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.ai_interaction_logs
    ADD CONSTRAINT fk_ai_logs_game FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: ai_interaction_logs fk_ai_logs_participant; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.ai_interaction_logs
    ADD CONSTRAINT fk_ai_logs_participant FOREIGN KEY (participant_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: ai_interaction_logs fk_ai_logs_researcher; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.ai_interaction_logs
    ADD CONSTRAINT fk_ai_logs_researcher FOREIGN KEY (researcher_id) REFERENCES public.researchers(user_id) ON DELETE SET NULL;


--
-- Name: ai_interaction_logs fk_ai_logs_session; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.ai_interaction_logs
    ADD CONSTRAINT fk_ai_logs_session FOREIGN KEY (session_id) REFERENCES public.game_sessions(id) ON DELETE CASCADE;


--
-- Name: game_sessions fk_game_sessions_game; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.game_sessions
    ADD CONSTRAINT fk_game_sessions_game FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: game_sessions fk_game_sessions_participant; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.game_sessions
    ADD CONSTRAINT fk_game_sessions_participant FOREIGN KEY (participant_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: games fk_games_researcher; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT fk_games_researcher FOREIGN KEY (researcher_id) REFERENCES public.researchers(user_id) ON DELETE RESTRICT;


--
-- Name: friendships friendships_addressee_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.friendships
    ADD CONSTRAINT friendships_addressee_id_fkey FOREIGN KEY (addressee_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: friendships friendships_requester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.friendships
    ADD CONSTRAINT friendships_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: games games_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.games
    ADD CONSTRAINT games_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.researcher_groups(id) ON DELETE SET NULL;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: project_messages project_messages_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.project_messages
    ADD CONSTRAINT project_messages_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: project_messages project_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.project_messages
    ADD CONSTRAINT project_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: researcher_group_members researcher_group_members_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.researcher_group_members
    ADD CONSTRAINT researcher_group_members_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.researcher_groups(id) ON DELETE CASCADE;


--
-- Name: researcher_group_members researcher_group_members_researcher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.researcher_group_members
    ADD CONSTRAINT researcher_group_members_researcher_id_fkey FOREIGN KEY (researcher_id) REFERENCES public.researchers(user_id) ON DELETE CASCADE;


--
-- Name: researcher_groups researcher_groups_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.researcher_groups
    ADD CONSTRAINT researcher_groups_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.researchers(user_id) ON DELETE RESTRICT;


--
-- Name: researchers researchers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.researchers
    ADD CONSTRAINT researchers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: siem_logs siem_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.siem_logs
    ADD CONSTRAINT siem_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: system_notices system_notices_admin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.system_notices
    ADD CONSTRAINT system_notices_admin_id_fkey FOREIGN KEY (admin_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: system_settings system_settings_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES public.users(id);


--
-- Name: ticket_messages ticket_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.ticket_messages
    ADD CONSTRAINT ticket_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: ticket_messages ticket_messages_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.ticket_messages
    ADD CONSTRAINT ticket_messages_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- Name: tickets tickets_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: tickets tickets_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: tickets tickets_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: tickets tickets_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: user_consents user_consents_game_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.user_consents
    ADD CONSTRAINT user_consents_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE;


--
-- Name: user_consents user_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.user_consents
    ADD CONSTRAINT user_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_emails user_emails_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: trustuser
--

ALTER TABLE ONLY public.user_emails
    ADD CONSTRAINT user_emails_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict qm5Bji1nidYOAdfkbxs5cq0ef0bcfZUS8euIXHTCpVzlTQUnhBji1cjYnOc7MtD

