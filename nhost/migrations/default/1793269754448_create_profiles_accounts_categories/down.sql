-- Reverte a migration 1. DESTRUTIVO: apaga profiles, accounts e categories.
DROP TABLE public.categories;
DROP TABLE public.accounts;
DROP TABLE public.profiles;
DROP FUNCTION public.check_category_depth();
DROP FUNCTION public.protect_immutable_columns();
DROP FUNCTION public.set_updated_at();
