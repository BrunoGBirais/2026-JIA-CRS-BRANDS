-- =============================================
-- CRS Brants â€” 006: Prevent self-delete
-- A logged-in user cannot delete their OWN account
-- via crs_brants_admin_delete_user.
-- Run AFTER 005_prevent_self_role_change.sql
-- =============================================

-- =======  UP  ========

CREATE OR REPLACE FUNCTION crs_brants_admin_delete_user(p_user_id UUID)
RETURNS VOID
SECURITY DEFINER
SET search_path = auth, public
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT crs_brants_is_admin() THEN
    RAISE EXCEPTION 'Acesso negado: apenas administradores.' USING ERRCODE = '42501';
  END IF;

  -- Prevent a user from deleting themselves.
  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'VocÃƒÂª nÃƒÂ£o pode excluir o seu prÃƒÂ³prio usuÃƒÂ¡rio.' USING ERRCODE = '42501';
  END IF;

  DELETE FROM auth.users
  WHERE id = p_user_id
    AND raw_user_meta_data->>'company_name' = 'crs_brants';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'UsuÃƒÂ¡rio nÃƒÂ£o encontrado ou pertence a outra empresa.' USING ERRCODE = '42501';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION crs_brants_admin_delete_user(UUID) TO authenticated;

NOTIFY pgrst, 'reload schema';

-- =======  DOWN  ========
-- Reverts to 004 version (no self-delete guard).
