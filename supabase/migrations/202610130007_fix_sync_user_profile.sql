-- ==============================================================================
-- Migration: 202610130007_fix_sync_user_profile.sql
-- Fix lỗi 23505 (duplicate key value violates unique constraint "app_users_email_lower_uidx")
-- khi đăng nhập bằng tài khoản Google thật đã được seed trước đó.
-- ==============================================================================

-- 1. Thêm ON UPDATE CASCADE cho các khóa ngoại để cập nhật id thông suốt
alter table if exists public.documents
  drop constraint if exists documents_owner_id_fkey,
  add constraint documents_owner_id_fkey
    foreign key (owner_id) references public.app_users(id) on delete cascade on update cascade;

alter table if exists public.document_permissions
  drop constraint if exists document_permissions_user_id_fkey,
  add constraint document_permissions_user_id_fkey
    foreign key (user_id) references public.app_users(id) on delete cascade on update cascade;

alter table if exists public.document_permissions
  drop constraint if exists document_permissions_granted_by_fkey,
  add constraint document_permissions_granted_by_fkey
    foreign key (granted_by) references public.app_users(id) on update cascade;

-- 2. Viết lại hàm sync_user_profile đảm bảo thứ tự thực thi an toàn không đụng độ Foreign Key & Unique Index
create or replace function public.sync_user_profile(
  p_id text,
  p_email text,
  p_display_name text,
  p_photo_url text,
  p_email_verified boolean
)
returns void language plpgsql security definer
set search_path = pg_catalog, public
as $$
declare
  v_old_id text;
begin
  -- Tìm user cũ đang giữ email này (nếu là UID seed tạm)
  select id into v_old_id 
  from public.app_users 
  where lower(email) = lower(p_email) 
  limit 1;
  
  if v_old_id is not null and v_old_id <> p_id and v_old_id <> 'public-system' then
    -- Bước 1: Đổi email cũ để giải phóng ràng buộc unique index app_users_email_lower_uidx
    update public.app_users 
    set email = 'migrated_' || id || '_' || email 
    where id = v_old_id;

    -- Bước 2: Tạo record cho user mới (p_id) trong app_users trước (để thỏa mãn foreign key)
    insert into public.app_users (id, email, display_name, photo_url, email_verified, updated_at)
    values (p_id, p_email, p_display_name, p_photo_url, p_email_verified, now())
    on conflict (id) do update set
      email = excluded.email,
      display_name = excluded.display_name,
      photo_url = excluded.photo_url,
      email_verified = excluded.email_verified,
      updated_at = now();

    -- Bước 3: Di chuyển tài liệu sang user mới
    update public.documents set owner_id = p_id where owner_id = v_old_id;

    -- Bước 4: Xử lý permissions
    delete from public.document_permissions
    where user_id = v_old_id
      and document_id in (select document_id from public.document_permissions where user_id = p_id);

    update public.document_permissions set user_id = p_id where user_id = v_old_id;
    update public.document_permissions set granted_by = p_id where granted_by = v_old_id;

    -- Bước 5: Xóa user tạm cũ
    delete from public.app_users where id = v_old_id;
  else
    -- Nếu user chưa tồn tại hoặc đã trùng id thì upsert bình thường
    insert into public.app_users (id, email, display_name, photo_url, email_verified, updated_at)
    values (p_id, p_email, p_display_name, p_photo_url, p_email_verified, now())
    on conflict (id) do update set
      email = excluded.email,
      display_name = excluded.display_name,
      photo_url = excluded.photo_url,
      email_verified = excluded.email_verified,
      updated_at = now();
  end if;
end;
$$;

-- Cấp quyền gọi hàm cho người dùng đã đăng nhập và khách
grant execute on function public.sync_user_profile(text, text, text, text, boolean) to anon, authenticated, public;

