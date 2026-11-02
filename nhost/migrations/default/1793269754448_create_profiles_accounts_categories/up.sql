-- Migration 1: profiles, accounts, categories
-- Regras: modelo-de-dados.md (valores em centavos, arquivar em vez de excluir,
-- integridade aplicada no banco). Isolamento por usuário é reforçado nas
-- permissões do Hasura (próximo passo); aqui ficam as constraints estruturais.

-- ---------------------------------------------------------------------------
-- Funções auxiliares
-- ---------------------------------------------------------------------------

CREATE FUNCTION public.set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- user_id e created_at nunca mudam depois da criação (defesa além do Hasura).
CREATE FUNCTION public.protect_immutable_columns() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.user_id IS DISTINCT FROM OLD.user_id THEN
    RAISE EXCEPTION 'user_id não pode ser alterado' USING ERRCODE = '23514';
  END IF;
  IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'created_at não pode ser alterado' USING ERRCODE = '23514';
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- profiles (1 por usuário)
-- ---------------------------------------------------------------------------

CREATE TABLE public.profiles (
  user_id      uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  display_name text        NOT NULL DEFAULT '',
  currency     char(3)     NOT NULL DEFAULT 'BRL',
  theme        text        NOT NULL DEFAULT 'system',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT profiles_display_name_len CHECK (char_length(display_name) <= 80),
  CONSTRAINT profiles_currency_brl     CHECK (currency = 'BRL'),            -- v1: moeda única
  CONSTRAINT profiles_theme_valid      CHECK (theme IN ('light', 'dark', 'system'))
);

-- ---------------------------------------------------------------------------
-- accounts (contas e cartões)
-- ---------------------------------------------------------------------------

CREATE TABLE public.accounts (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               uuid        NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name                  text        NOT NULL,
  type                  text        NOT NULL,
  initial_balance_cents bigint      NOT NULL DEFAULT 0,
  closing_day           smallint,
  due_day               smallint,
  color                 text,
  is_archived           boolean     NOT NULL DEFAULT false,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  -- permite chaves estrangeiras compostas (id, user_id) nas tabelas seguintes,
  -- garantindo no banco que o lançamento e a conta são do mesmo usuário
  CONSTRAINT accounts_id_user_key UNIQUE (id, user_id),
  CONSTRAINT accounts_name_len    CHECK (char_length(btrim(name)) BETWEEN 1 AND 80),
  CONSTRAINT accounts_type_valid  CHECK (type IN ('checking', 'savings', 'wallet', 'credit_card')),
  CONSTRAINT accounts_color_hex   CHECK (color IS NULL OR color ~ '^#[0-9a-fA-F]{6}$'),
  -- cartão: fechamento e vencimento obrigatórios (1-31) e sem saldo inicial;
  -- demais tipos: fechamento e vencimento proibidos
  CONSTRAINT accounts_card_rules CHECK (
    CASE WHEN type = 'credit_card'
      THEN closing_day IS NOT NULL AND closing_day BETWEEN 1 AND 31
       AND due_day     IS NOT NULL AND due_day     BETWEEN 1 AND 31
       AND initial_balance_cents = 0
      ELSE closing_day IS NULL AND due_day IS NULL
    END
  )
);

-- Evita duplicidade de nome entre contas ativas do mesmo usuário (sem diferenciar maiúsculas)
CREATE UNIQUE INDEX accounts_user_name_active_key
  ON public.accounts (user_id, lower(btrim(name))) WHERE NOT is_archived;

-- ---------------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------------

CREATE TABLE public.categories (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name        text        NOT NULL,
  type        text        NOT NULL,
  parent_id   uuid,
  color       text,
  icon        text,
  is_archived boolean     NOT NULL DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT categories_id_user_key      UNIQUE (id, user_id),
  CONSTRAINT categories_id_user_type_key UNIQUE (id, user_id, type),
  CONSTRAINT categories_name_len   CHECK (char_length(btrim(name)) BETWEEN 1 AND 80),
  CONSTRAINT categories_type_valid CHECK (type IN ('income', 'expense')),
  CONSTRAINT categories_color_hex  CHECK (color IS NULL OR color ~ '^#[0-9a-fA-F]{6}$'),
  CONSTRAINT categories_icon_len   CHECK (icon IS NULL OR char_length(icon) <= 50),
  CONSTRAINT categories_not_own_parent CHECK (parent_id IS NULL OR parent_id <> id),
  -- a categoria pai precisa ser do mesmo usuário e do mesmo tipo
  CONSTRAINT categories_parent_fkey FOREIGN KEY (parent_id, user_id, type)
    REFERENCES public.categories (id, user_id, type)
);

CREATE UNIQUE INDEX categories_user_name_active_key
  ON public.categories (
    user_id, type,
    COALESCE(parent_id, '00000000-0000-0000-0000-000000000000'::uuid),
    lower(btrim(name))
  ) WHERE NOT is_archived;

CREATE INDEX categories_parent_idx ON public.categories (parent_id) WHERE parent_id IS NOT NULL;

-- Hierarquia limitada a 2 níveis (categoria e subcategoria): o pai não pode ter
-- pai, e uma categoria que já tem filhas não pode virar subcategoria.
CREATE FUNCTION public.check_category_depth() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.parent_id IS NOT NULL THEN
    IF EXISTS (SELECT 1 FROM public.categories WHERE id = NEW.parent_id AND parent_id IS NOT NULL) THEN
      RAISE EXCEPTION 'subcategoria não pode ter subcategorias (máximo de 2 níveis)' USING ERRCODE = '23514';
    END IF;
    IF EXISTS (SELECT 1 FROM public.categories WHERE parent_id = NEW.id) THEN
      RAISE EXCEPTION 'categoria com subcategorias não pode virar subcategoria' USING ERRCODE = '23514';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- Triggers
-- ---------------------------------------------------------------------------

CREATE TRIGGER profiles_protect   BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_immutable_columns();
CREATE TRIGGER accounts_protect   BEFORE UPDATE ON public.accounts
  FOR EACH ROW EXECUTE FUNCTION public.protect_immutable_columns();
CREATE TRIGGER categories_protect BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE FUNCTION public.protect_immutable_columns();

CREATE TRIGGER categories_depth BEFORE INSERT OR UPDATE OF parent_id ON public.categories
  FOR EACH ROW EXECUTE FUNCTION public.check_category_depth();

CREATE TRIGGER profiles_updated_at   BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER accounts_updated_at   BEFORE UPDATE ON public.accounts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
CREATE TRIGGER categories_updated_at BEFORE UPDATE ON public.categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
