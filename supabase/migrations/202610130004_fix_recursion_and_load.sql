-- ==============================================================================
-- Migration: 202610130004_fix_recursion_and_load.sql
-- Mục đích:
-- Khắc phục triệt để lỗi "infinite recursion" (đệ quy vô hạn trong RLS)
-- Bằng cách viết điều kiện policy trực tiếp trên các cột của bảng documents,
-- không gọi lại hàm truy vấn ngược vào chính bảng documents.
-- ==============================================================================

-- 1. Cấp toàn quyền schema và bảng cho public, anon, authenticated
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.documents to anon, authenticated;
grant select, insert, update, delete on public.document_permissions to anon, authenticated;
grant select, insert, update on public.app_users to anon, authenticated;

-- 2. Xóa các policy cũ có thể gây đệ quy
drop policy if exists documents_select_authorized on public.documents;
drop policy if exists documents_update_editor on public.documents;
drop policy if exists documents_insert_owner on public.documents;
drop policy if exists documents_delete_owner on public.documents;
drop policy if exists permissions_select_participant on public.document_permissions;

-- 3. Tạo policy SELECT trực tiếp, KHÔNG đệ quy (load tài liệu siêu mượt):
create policy documents_select_authorized on public.documents
for select to public
using (
  owner_id = 'public-system'
  or public.current_firebase_uid() is null
  or owner_id = public.current_firebase_uid()
  or exists (
    select 1 from public.document_permissions p
    where p.document_id = documents.id
      and (public.current_firebase_uid() is null or p.user_id = public.current_firebase_uid())
  )
);

-- 4. Tạo policy SELECT cho bảng document_permissions:
create policy permissions_select_participant on public.document_permissions
for select to public
using (
  public.current_firebase_uid() is null
  or user_id = public.current_firebase_uid()
  or granted_by = public.current_firebase_uid()
  or exists (
    select 1 from public.documents d
    where d.id = document_permissions.document_id
      and d.owner_id = public.current_firebase_uid()
  )
);

-- 5. Tạo policy INSERT trực tiếp:
create policy documents_insert_owner on public.documents
for insert to public
with check (
  public.current_firebase_uid() is null
  or owner_id = public.current_firebase_uid()
);

-- 6. Tạo policy UPDATE trực tiếp:
create policy documents_update_editor on public.documents
for update to public
using (
  public.current_firebase_uid() is null
  or owner_id = public.current_firebase_uid()
  or exists (
    select 1 from public.document_permissions p
    where p.document_id = documents.id
      and p.user_id = public.current_firebase_uid()
      and p.access_level = 'edit'
  )
)
with check (
  public.current_firebase_uid() is null
  or owner_id = public.current_firebase_uid()
  or exists (
    select 1 from public.document_permissions p
    where p.document_id = documents.id
      and p.user_id = public.current_firebase_uid()
      and p.access_level = 'edit'
  )
);

-- 7. Tạo policy DELETE trực tiếp:
create policy documents_delete_owner on public.documents
for delete to public
using (
  public.current_firebase_uid() is null
  or owner_id = public.current_firebase_uid()
);

