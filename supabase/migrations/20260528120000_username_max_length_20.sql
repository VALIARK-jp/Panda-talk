-- ユーザーコード上限を 30 → 20 に変更。既存の 21 文字以上・不正形式を書き換える。

DO $$
DECLARE
  r RECORD;
  base text;
  candidate text;
  n int;
BEGIN
  FOR r IN
    SELECT id, username::text AS uname
    FROM public.panda_profiles
    WHERE length(username::text) > 20
       OR username::text !~ '^[A-Za-z0-9_]{3,20}$'
    ORDER BY created_at NULLS LAST, id
  LOOP
    base := lower(regexp_replace(r.uname, '[^a-zA-Z0-9_]', '_', 'g'));
    base := regexp_replace(base, '_+', '_', 'g');
    base := trim(both '_' from base);

    IF length(base) < 3 THEN
      base := 'panda_' || substr(replace(r.id::text, '-', ''), 1, 6);
    END IF;

    base := left(base, 20);
    candidate := base;
    n := 1;

    WHILE EXISTS (
      SELECT 1
      FROM public.panda_profiles p
      WHERE lower(p.username::text) = lower(candidate)
        AND p.id <> r.id
    ) LOOP
      candidate := left(base, greatest(3, 20 - length(n::text) - 1)) || '_' || n::text;
      n := n + 1;

      IF n > 999 THEN
        candidate := 'panda_' || substr(replace(r.id::text, '-', ''), 1, 6);
        EXIT;
      END IF;
    END LOOP;

    UPDATE public.panda_profiles
    SET username = candidate
    WHERE id = r.id;

    RAISE NOTICE 'username migrated: % -> %', r.uname, candidate;
  END LOOP;
END $$;

ALTER TABLE public.panda_profiles
  DROP CONSTRAINT IF EXISTS panda_profiles_username_format;

ALTER TABLE public.panda_profiles
  DROP CONSTRAINT IF EXISTS users_username_format;

ALTER TABLE public.panda_profiles
  ADD CONSTRAINT panda_profiles_username_format
  CHECK (username::text ~ '^[A-Za-z0-9_]{3,20}$');
