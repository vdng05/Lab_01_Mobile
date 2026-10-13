begin;
create extension if not exists pgtap with schema extensions;
select plan(11);

insert into public.app_users (id, email, display_name, email_verified) values
  ('firebase-owner-01', 'owner@example.test', 'Owner', true),
  ('firebase-viewer-02', 'viewer@example.test', 'Viewer', true),
  ('firebase-editor-03', 'editor@example.test', 'Editor', true),
  ('firebase-outsider-04', 'outsider@example.test', 'Outsider', false)
on conflict (id) do nothing;

insert into public.documents (id, owner_id, title, course, category)
values ('rls-document-01', 'firebase-owner-01', 'RLS test', 'Security', 'lesson')
on conflict (id) do nothing;

insert into public.document_permissions (document_id, user_id, access_level, granted_by)
values
  ('rls-document-01', 'firebase-viewer-02', 'view', 'firebase-owner-01'),
  ('rls-document-01', 'firebase-editor-03', 'edit', 'firebase-owner-01')
on conflict (document_id, user_id) do update set access_level = excluded.access_level;

set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"firebase-owner-01","role":"authenticated"}', true);
select is((select count(*)::int from public.documents), 1, 'owner reads own document');
select is(public.owns_document('rls-document-01'), true, 'owner is recognized');
select is(
  (select count(*)::int from public.share_document('rls-document-01', 'viewer@example.test', 'view')),
  1,
  'owner can share to a verified account'
);
select throws_ok(
  $$select * from public.share_document('rls-document-01', 'outsider@example.test', 'view')$$,
  'P0002',
  'No registered user found for that email',
  'unverified email cannot receive a share'
);

select set_config('request.jwt.claims', '{"sub":"firebase-viewer-02","role":"authenticated"}', true);
select is((select count(*)::int from public.documents), 1, 'viewer reads shared document');
update public.documents set title = 'viewer must not update' where id = 'rls-document-01';
select is((select title from public.documents where id = 'rls-document-01'), 'RLS test', 'viewer cannot update');
select is((select count(*)::int from public.document_permissions), 1, 'viewer sees own permission only');

select set_config('request.jwt.claims', '{"sub":"firebase-editor-03","role":"authenticated"}', true);
update public.documents set title = 'editor update' where id = 'rls-document-01';
select is((select title from public.documents where id = 'rls-document-01'), 'editor update', 'editor can update metadata');
select throws_ok(
  $$update public.documents set owner_id = 'firebase-editor-03' where id = 'rls-document-01'$$,
  'P0001',
  'Document owner cannot be changed',
  'editor cannot take ownership'
);

select set_config('request.jwt.claims', '{"sub":"firebase-outsider-04","role":"authenticated"}', true);
select is((select count(*)::int from public.documents), 0, 'unshared user cannot read document');
select is(public.owns_document('rls-document-01'), false, 'unshared user is not owner');

select * from finish();
rollback;