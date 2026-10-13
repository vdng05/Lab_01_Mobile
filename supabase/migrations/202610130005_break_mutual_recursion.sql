-- ==============================================================================
-- Migration: 202610130005_break_mutual_recursion.sql
-- Khắc phục triệt để lỗi 42P17: "infinite recursion detected in policy for relation documents"
-- Nguyên nhân: documents gọi sang document_permissions, rồi permissions lại gọi ngược lại documents.
-- Giải pháp: Đặt policy của document_permissions thành `using (true)` để bẻ gãy hoàn toàn vòng lặp.
-- ==============================================================================

-- 1. Bẻ gãy vòng lặp trên bảng document_permissions (không gọi ngược sang documents nữa)
drop policy if exists permissions_select_participant on public.document_permissions;
create policy permissions_select_participant on public.document_permissions
for select to public
using (true);

-- 2. Đặt lại policy SELECT trên bảng documents
drop policy if exists documents_select_authorized on public.documents;
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

