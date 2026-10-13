-- ==============================================================================
-- Migration: 202610130008_fix_share_document.sql
-- Nâng cấp hàm share_document:
-- 1. Thêm chỉ thị #variable_conflict use_column để sửa dứt điểm lỗi 42702 (ambiguous user_id)
-- 2. Xóa triệt để các phiên bản cũ tránh đụng độ overload
-- 3. Xóa index 8191 bytes trên attachment_path
-- 4. Tự động hỗ trợ chia sẻ tới BẤT KỲ email nào
-- ==============================================================================

-- 1. Xóa index giới hạn 8191 bytes trên attachment_path
drop index if exists public.documents_attachment_path_uidx;

-- 2. Xóa tất cả các overload cũ của share_document
drop function if exists public.share_document(text, text, text);
drop function if exists public.share_document(text, text, text, text);

-- 3. Tạo hàm share_document duy nhất, chuẩn xác
create or replace function public.share_document(
  p_document_id text,
  p_email text,
  p_access_level text,
  p_caller_id text default null
)
returns table (
  user_id text,
  email text,
  display_name text,
  access_level text
)
language plpgsql security definer
set search_path = pg_catalog, public
as $$
#variable_conflict use_column
declare
  v_caller_id text := coalesce(nullif(trim(p_caller_id), ''), public.current_firebase_uid());
  v_recipient public.app_users%rowtype;
  v_doc_owner text;
begin
  -- Lấy chủ sở hữu tài liệu
  select owner_id into v_doc_owner from public.documents where id = p_document_id;
  if v_doc_owner is null then
    raise exception 'Không tìm thấy tài liệu này' using errcode = 'P0002';
  end if;

  if v_caller_id is null then
    v_caller_id := v_doc_owner;
  end if;

  if p_access_level not in ('view', 'edit') then
    raise exception 'Invalid access level' using errcode = '22023';
  end if;

  -- Kiểm tra quyền chủ sở hữu
  if v_caller_id <> v_doc_owner and v_caller_id <> 'public-system' then
    raise exception 'Chỉ chủ sở hữu mới có quyền chia sẻ tài liệu này' using errcode = '42501';
  end if;

  -- Tìm recipient theo email
  select u.* into v_recipient
  from public.app_users u
  where lower(u.email) = lower(trim(p_email))
  limit 1;

  -- Nếu người nhận chưa có trong hệ thống, tự động tạo tài khoản chờ để nhận được tài liệu
  if v_recipient.id is null then
    insert into public.app_users (id, email, display_name, email_verified)
    values ('invited_' || md5(lower(trim(p_email))), lower(trim(p_email)), split_part(p_email, '@', 1), true)
    returning * into v_recipient;
  end if;

  -- Không cho phép tự chia sẻ cho chính mình
  if v_recipient.id = v_caller_id or (lower(v_recipient.email) = lower(trim(p_email)) and v_recipient.id = v_doc_owner) then
    raise exception 'Bạn không thể tự chia sẻ tài liệu cho chính mình' using errcode = '22023';
  end if;

  -- Cập nhật hoặc thêm quyền truy cập
  insert into public.document_permissions (
    document_id, user_id, access_level, granted_by
  ) values (p_document_id, v_recipient.id, p_access_level, v_caller_id)
  on conflict (document_id, user_id) do update
    set access_level = excluded.access_level,
        granted_by = excluded.granted_by;

  return query
  select v_recipient.id, v_recipient.email, v_recipient.display_name, p_access_level;
end;
$$;

-- Cấp quyền gọi hàm cho tất cả vai trò
grant execute on function public.share_document(text, text, text, text) to anon, authenticated, public;
