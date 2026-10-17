-- DRAFT ONLY: review the live schema and data immediately before execution.
-- PostgreSQL 17.11 snapshot supplied on 2026-10-12.
-- Do not execute this file as a whole. Run each stage separately and verify
-- its result before proceeding to the next stage.

-- ---------------------------------------------------------------------------
-- Stage 0: read-only preflight
-- Confirm the legacy schema, constraints, RLS policies, and current row counts.
-- Compare these results with the reviewed snapshot before running Stage 1.
-- ---------------------------------------------------------------------------

SHOW server_version;

SELECT to_regclass('public.categories') AS existing_categories_table;

SELECT column_name, data_type, udt_name, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'decks'
  AND column_name IN ('category', 'category_id', 'user_id')
ORDER BY column_name;

SELECT conname, contype, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.decks'::regclass
ORDER BY conname;

SELECT c.relrowsecurity AS rls_enabled,
       c.relforcerowsecurity AS rls_forced
FROM pg_class AS c
WHERE c.oid = 'public.decks'::regclass;

SELECT policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('decks', 'cards', 'categories')
ORDER BY tablename, policyname;

SELECT
  (SELECT count(*) FROM public.decks) AS deck_count,
  (SELECT count(*) FROM public.cards) AS card_count,
  count(*) FILTER (WHERE d.user_id IS NULL) AS decks_without_owner,
  count(*) FILTER (
    WHERE d.category IS NULL OR btrim(d.category) = ''
  ) AS decks_without_usable_legacy_category,
  count(*) FILTER (
    WHERE d.category IS NOT NULL
      AND char_length(btrim(d.category)) > 50
  ) AS legacy_categories_over_50_chars
FROM public.decks AS d;

SELECT d.user_id, btrim(d.category) AS legacy_category, count(*) AS deck_count
FROM public.decks AS d
GROUP BY d.user_id, btrim(d.category)
ORDER BY d.user_id, legacy_category;

-- ---------------------------------------------------------------------------
-- Stage 1: additive schema migration
-- Keep decks.category, its NOT NULL/default, and its existing CHECK constraint.
-- This stage does not change any deck or card rows.
-- ---------------------------------------------------------------------------

BEGIN;

CREATE TABLE public.categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users (id) ON DELETE CASCADE,
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT categories_name_trimmed_length_check
    CHECK (
      name = btrim(name)
      AND char_length(name) BETWEEN 1 AND 50
    ),
  CONSTRAINT categories_user_id_id_key
    UNIQUE (user_id, id)
);

CREATE UNIQUE INDEX categories_user_name_ci_key
  ON public.categories (user_id, lower(name));

REVOKE ALL PRIVILEGES ON TABLE public.categories
  FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.categories
  TO authenticated;

ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY categories_owner_select
  ON public.categories
  FOR SELECT
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

CREATE POLICY categories_owner_insert
  ON public.categories
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY categories_owner_update
  ON public.categories
  FOR UPDATE
  TO authenticated
  USING (user_id = (SELECT auth.uid()))
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY categories_owner_delete
  ON public.categories
  FOR DELETE
  TO authenticated
  USING (user_id = (SELECT auth.uid()));

ALTER TABLE public.decks
  ADD COLUMN category_id uuid;

ALTER TABLE public.decks
  ADD CONSTRAINT decks_category_owner_fkey
  FOREIGN KEY (user_id, category_id)
  REFERENCES public.categories (user_id, id)
  ON DELETE SET NULL (category_id);

CREATE INDEX decks_user_category_id_idx
  ON public.decks (user_id, category_id);

COMMIT;

-- If Stage 1 fails before COMMIT, PostgreSQL rolls back its transaction.
-- Confirm the table, column, constraints, grants, and policies before Stage 2.

-- ---------------------------------------------------------------------------
-- Stage 2: one-time legacy data backfill
-- Creates one category per (owner, trimmed legacy name). Updates only rows
-- whose category_id is NULL; non-NULL category assignments are never replaced.
-- Run before enabling category deletion in the updated app. Do not rerun after
-- users can delete categories: a deleted category leaves category_id NULL,
-- while the retained legacy category text may cause a rerun to recreate it.
-- ---------------------------------------------------------------------------

BEGIN;

INSERT INTO public.categories (user_id, name)
SELECT DISTINCT d.user_id, btrim(d.category)
FROM public.decks AS d
WHERE d.category_id IS NULL
  AND d.user_id IS NOT NULL
  AND d.category IS NOT NULL
  AND btrim(d.category) <> ''
  AND char_length(btrim(d.category)) <= 50
ON CONFLICT DO NOTHING;

UPDATE public.decks AS d
SET category_id = c.id
FROM public.categories AS c
WHERE d.category_id IS NULL
  AND d.user_id = c.user_id
  AND lower(c.name) = lower(btrim(d.category))
  AND d.category IS NOT NULL
  AND btrim(d.category) <> ''
  AND char_length(btrim(d.category)) <= 50;

COMMIT;

-- If Stage 2 fails before COMMIT, its category inserts and deck updates roll
-- back together. Recheck the Stage 0 preflight and do not proceed on errors.

-- ---------------------------------------------------------------------------
-- Stage 3: read-only verification
-- Compare deck_count and card_count with the fresh Stage 0 counts.
-- Before enabling the new app, both unmigrated and cross-owner counts must be 0.
-- ---------------------------------------------------------------------------

SELECT
  (SELECT count(*) FROM public.decks) AS deck_count,
  (SELECT count(*) FROM public.cards) AS card_count,
  count(*) FILTER (
    WHERE d.category_id IS NULL
      AND d.category IS NOT NULL
      AND btrim(d.category) <> ''
  ) AS nonblank_legacy_categories_not_migrated,
  count(*) FILTER (
    WHERE c.id IS NOT NULL
      AND c.user_id <> d.user_id
  ) AS category_owner_mismatches
FROM public.decks AS d
LEFT JOIN public.categories AS c
  ON c.id = d.category_id;

SELECT count(*) AS categories_with_invalid_names
FROM public.categories
WHERE name <> btrim(name)
   OR char_length(name) NOT BETWEEN 1 AND 50;

SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('decks', 'cards', 'categories')
ORDER BY tablename;

SELECT policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('decks', 'cards', 'categories')
ORDER BY tablename, policyname;
