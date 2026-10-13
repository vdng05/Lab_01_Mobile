-- ==============================================================================
-- Migration: 202610130003_fix_rls_policies_for_public.sql
-- Mục đích:
-- Mở quyền SELECT / INSERT / UPDATE / DELETE trên bảng documents và document_permissions
-- cho role public, đảm bảo tài liệu hiển thị ngay lập tức trên app.
-- ==============================================================================

-- 1. Cấp quyền schema và bảng
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.documents to anon, authenticated;
grant select, insert, update, delete on public.document_permissions to anon, authenticated;
grant select, insert, update on public.app_users to anon, authenticated;

-- 2. Cập nhật hàm can_read_document
create or replace function public.can_read_document(target_id text)
returns boolean language sql stable security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.documents d
    where d.id = target_id
      and (
        d.owner_id = 'public-system' -- Tài liệu công khai
        or public.current_firebase_uid() is null -- Hiển thị nếu chưa cấu hình Third-Party Auth
        or d.owner_id = public.current_firebase_uid()
        or exists (
          select 1 from public.document_permissions p
          where p.document_id = d.id
            and p.user_id = public.current_firebase_uid()
        )
      )
  )
$$;

-- 3. Cập nhật hàm can_edit_document
create or replace function public.can_edit_document(target_id text)
returns boolean language sql stable security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.documents d
    where d.id = target_id
      and (
        public.current_firebase_uid() is null
        or d.owner_id = public.current_firebase_uid()
        or exists (
          select 1 from public.document_permissions p
          where p.document_id = d.id
            and p.user_id = public.current_firebase_uid()
            and p.access_level = 'edit'
        )
      )
  )
$$;

-- 4. Cập nhật RLS Policy SELECT cho bảng documents (áp dụng cho public)
drop policy if exists documents_select_authorized on public.documents;
create policy documents_select_authorized on public.documents
for select to public
using (public.can_read_document(id));

-- 5. Cập nhật RLS Policy SELECT cho bảng document_permissions
drop policy if exists permissions_select_participant on public.document_permissions;
create policy permissions_select_participant on public.document_permissions
for select to public
using (
  public.current_firebase_uid() is null
  or user_id = public.current_firebase_uid()
  or public.owns_document(document_id)
);

-- 6. Cập nhật RLS Policy INSERT cho bảng documents
drop policy if exists documents_insert_owner on public.documents;
create policy documents_insert_owner on public.documents
for insert to public
with check (
  public.current_firebase_uid() is null
  or owner_id = public.current_firebase_uid()
);

-- 7. Cập nhật RLS Policy UPDATE cho bảng documents
drop policy if exists documents_update_editor on public.documents;
create policy documents_update_editor on public.documents
for update to public
using (public.can_edit_document(id))
with check (public.can_edit_document(id));

-- 8. Cập nhật RLS Policy DELETE cho bảng documents
drop policy if exists documents_delete_owner on public.documents;
create policy documents_delete_owner on public.documents
for delete to public
using (
  public.current_firebase_uid() is null
  or owner_id = public.current_firebase_uid()
);

