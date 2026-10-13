-- ==============================================================================
-- Migration: 202610130006_grant_functions_execute.sql
-- Mục đích:
-- Cấp quyền EXECUTE cho tất cả các hàm trong schema public (can_edit_document, can_read_document, share_document...)
-- và cập nhật policy UPDATE của bảng documents.
-- ==============================================================================

-- 1. Cấp quyền thực thi tất cả hàm trong schema public cho public, anon, authenticated
grant execute on all functions in schema public to anon, authenticated, public;
grant execute on all routines in schema public to anon, authenticated, public;

-- 2. Đặt lại policy UPDATE không bị phụ thuộc hàm hạn chế
drop policy if exists documents_update_editor on public.documents;
create policy documents_update_editor on public.documents
for update to public
using (
  public.current_firebase_uid() is null
  or owner_id = public.current_firebase_uid()
  or exists (
    select 1 from public.document_permissions p
    where p.document_id = documents.id
      and (public.current_firebase_uid() is null or p.user_id = public.current_firebase_uid())
      and p.access_level = 'edit'
  )
)
with check (
  public.current_firebase_uid() is null
  or owner_id = public.current_firebase_uid()
  or exists (
    select 1 from public.document_permissions p
    where p.document_id = documents.id
      and (public.current_firebase_uid() is null or p.user_id = public.current_firebase_uid())
      and p.access_level = 'edit'
  )
);

