-- ==============================================================================
-- Migration: 202610130002_seed_test_data.sql (Bản Fix Hoàn Chỉnh - Chống đụng độ Email)
-- ==============================================================================

-- 1. Cập nhật chính sách đọc tài liệu: cho phép đọc nếu là tài liệu công khai (owner_id = 'public-system')
create or replace function public.can_read_document(target_id text)
returns boolean language sql stable security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1 from public.documents d
    where d.id = target_id
      and (
        d.owner_id = 'public-system' -- Tài liệu công khai toàn hệ thống
        or d.owner_id = public.current_firebase_uid()
        or exists (
          select 1 from public.document_permissions p
          where p.document_id = d.id
            and p.user_id = public.current_firebase_uid()
        )
      )
  )
$$;

-- 2. Cập nhật quyền thêm tài liệu (không bị chặn khi thêm tài liệu mới)
drop policy if exists documents_insert_owner on public.documents;
create policy documents_insert_owner on public.documents
for insert to public
with check (
  owner_id = coalesce(public.current_firebase_uid(), owner_id)
);

-- 3. Tạo hàm RPC sync_user_profile: khi user đăng nhập thật bằng Google, tự động đồng bộ
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
  select id into v_old_id from public.app_users where lower(email) = lower(p_email) limit 1;
  
  if v_old_id is not null and v_old_id <> p_id then
    update public.documents set owner_id = p_id where owner_id = v_old_id;
    update public.document_permissions set user_id = p_id where user_id = v_old_id;
    update public.document_permissions set granted_by = p_id where granted_by = v_old_id;
    delete from public.app_users where id = v_old_id;
  end if;

  insert into public.app_users (id, email, display_name, photo_url, email_verified, updated_at)
  values (p_id, p_email, p_display_name, p_photo_url, p_email_verified, now())
  on conflict (id) do update set
    email = excluded.email,
    display_name = excluded.display_name,
    photo_url = excluded.photo_url,
    email_verified = excluded.email_verified,
    updated_at = now();
end;
$$;
grant execute on function public.sync_user_profile(text, text, text, text, boolean) to anon, authenticated;


-- 4. Seed dữ liệu an toàn (Tự động nhận diện nếu User đã tồn tại sẵn)
do $$
declare
  v_uid_dang1 text;
  v_uid_dang2 text;
  v_uid_thai3 text;
begin
  -- Tạo tài khoản hệ thống cho tài liệu công khai
  insert into public.app_users (id, email, display_name, email_verified)
  values ('public-system', 'public-system@study.edu.vn', 'Hệ thống Đào tạo (Công khai)', true)
  on conflict (id) do nothing;

  -- Kiểm tra và tạo 3 user kiểm thử nếu chưa có
  if not exists (select 1 from public.app_users where lower(email) = 'vuhaidang3566577@gmail.com') then
    insert into public.app_users (id, email, display_name, email_verified)
    values ('uid-dang-01', 'vuhaidang3566577@gmail.com', 'Vũ Hải Đăng (01)', true);
  end if;

  if not exists (select 1 from public.app_users where lower(email) = 'vuhaidang19122005@gmail.com') then
    insert into public.app_users (id, email, display_name, email_verified)
    values ('uid-dang-02', 'vuhaidang19122005@gmail.com', 'Vũ Hải Đăng (02)', true);
  end if;

  if not exists (select 1 from public.app_users where lower(email) = 'phuvanthai3566577@gmail.com') then
    insert into public.app_users (id, email, display_name, email_verified)
    values ('uid-thai-03', 'phuvanthai3566577@gmail.com', 'Phù Văn Thái', true);
  end if;

  -- Lấy đúng ID (kể cả UID thật đã đăng nhập từ Google Firebase)
  select id into v_uid_dang1 from public.app_users where lower(email) = 'vuhaidang3566577@gmail.com' limit 1;
  select id into v_uid_dang2 from public.app_users where lower(email) = 'vuhaidang19122005@gmail.com' limit 1;
  select id into v_uid_thai3 from public.app_users where lower(email) = 'phuvanthai3566577@gmail.com' limit 1;

  -- Seed tài liệu công khai toàn hệ thống
  insert into public.documents (id, owner_id, title, course, category, description, link, author, semester, tags)
  values
    (
      'doc-pub-01',
      'public-system',
      'Giáo trình Phát triển Ứng dụng Di động Đa nền tảng (Flutter & Firebase)',
      'Mobile Application Development',
      'lesson',
      'Tài liệu giảng dạy chính thức cung cấp kiến thức toàn diện về Flutter UI, State Management, và kết nối Cloud Services.',
      'https://flutter.dev',
      'Bộ môn Công nghệ Phần mềm',
      'Học kỳ 1 - 2026',
      array['flutter', 'mobile', 'giao-trinh', 'cong-khai']
    ),
    (
      'doc-pub-02',
      'public-system',
      'Quy chuẩn Thiết kế Kiến trúc Clean Architecture trong Ứng dụng Di động',
      'Software Architecture',
      'reference',
      'Tài liệu tham khảo hướng dẫn phân tầng Presentation, Domain, Data và Dependency Injection.',
      'https://pub.dev',
      'Bộ môn Công nghệ Phần mềm',
      'Học kỳ 1 - 2026',
      array['clean-architecture', 'best-practices', 'cong-khai']
    ),
    (
      'doc-pub-03',
      'public-system',
      'Hướng dẫn Tích hợp Cloud Storage & Supabase Row Level Security (RLS)',
      'Cloud Computing & Security',
      'reference',
      'Tài liệu thực hành cấu hình xác thực Google, phân quyền dữ liệu quan hệ và lưu trữ tệp tin đám mây.',
      'https://supabase.com/docs',
      'Bộ môn An toàn Thông tin',
      'Học kỳ 1 - 2026',
      array['cloud', 'supabase', 'firebase', 'rls']
    )
  on conflict (id) do update set
    title = excluded.title,
    course = excluded.course,
    description = excluded.description;

  -- Seed tài liệu riêng & phân cấp cho User 1 (vuhaidang3566577@gmail.com)
  insert into public.documents (id, owner_id, title, course, category, description, link, author, semester, tags)
  values (
    'doc-dang1-private',
    v_uid_dang1,
    'Ghi chú ôn thi cuối kỳ: Lập trình Di động nâng cao',
    'Mobile Application Development',
    'assignment',
    'Tài liệu ghi chú cá nhân phục vụ ôn thi cuối kỳ (chỉ cá nhân tác giả xem được).',
    '',
    'Vũ Hải Đăng (01)',
    'Học kỳ 1 - 2026',
    array['on-thi', 'ca-nhan']
  )
  on conflict (id) do update set owner_id = v_uid_dang1;

  insert into public.documents (id, owner_id, title, course, category, description, link, author, semester, tags)
  values (
    'doc-dang1-shared',
    v_uid_dang1,
    'Báo cáo Đồ án Nhóm 01 - Hệ thống Quản lý Tài liệu Cloud',
    'Mobile Application Development',
    'assignment',
    'Bản báo cáo chung của Nhóm 01. Đã chia sẻ quyền chỉnh sửa cho Đăng 02 và quyền xem cho Thái.',
    'https://github.com',
    'Nhóm 01',
    'Học kỳ 1 - 2026',
    array['do-an', 'nhom-01', 'chia-se']
  )
  on conflict (id) do update set owner_id = v_uid_dang1;

  insert into public.document_permissions (document_id, user_id, access_level, granted_by)
  values
    ('doc-dang1-shared', v_uid_dang2, 'edit', v_uid_dang1),
    ('doc-dang1-shared', v_uid_thai3, 'view', v_uid_dang1)
  on conflict (document_id, user_id) do update set
    access_level = excluded.access_level,
    granted_by = excluded.granted_by;

  -- Seed tài liệu riêng & phân cấp cho User 2 (vuhaidang19122005@gmail.com)
  insert into public.documents (id, owner_id, title, course, category, description, link, author, semester, tags)
  values (
    'doc-dang2-private',
    v_uid_dang2,
    'Source code tham khảo: REST API & WebSocket Realtime',
    'Mobile Application Development',
    'lesson',
    'Ghi chú kiến trúc WebSocket kết nối realtime trong ứng dụng chat và thông báo.',
    '',
    'Vũ Hải Đăng (02)',
    'Học kỳ 1 - 2026',
    array['websocket', 'realtime', 'ca-nhan']
  )
  on conflict (id) do update set owner_id = v_uid_dang2;

  insert into public.documents (id, owner_id, title, course, category, description, link, author, semester, tags)
  values (
    'doc-dang2-shared',
    v_uid_dang2,
    'Báo cáo Thiết kế Database Supabase & Phân quyền RLS',
    'Cloud Computing & Security',
    'reference',
    'Bản thiết kế cơ sở dữ liệu quan hệ và mô hình RLS. Chia sẻ cho Đăng 01 xem tham khảo.',
    '',
    'Vũ Hải Đăng (02)',
    'Học kỳ 1 - 2026',
    array['database', 'rls', 'chia-se']
  )
  on conflict (id) do update set owner_id = v_uid_dang2;

  insert into public.document_permissions (document_id, user_id, access_level, granted_by)
  values
    ('doc-dang2-shared', v_uid_dang1, 'view', v_uid_dang2)
  on conflict (document_id, user_id) do update set
    access_level = excluded.access_level,
    granted_by = excluded.granted_by;

  -- Seed tài liệu riêng cho User 3 (phuvanthai3566577@gmail.com)
  insert into public.documents (id, owner_id, title, course, category, description, link, author, semester, tags)
  values (
    'doc-thai-private',
    v_uid_thai3,
    'Kịch bản Kiểm thử Phân quyền 3 Tài khoản (Test Plan)',
    'Software Testing & QA',
    'assignment',
    'Kịch bản kiểm thử chi tiết xác minh quyền hạn Owner, Editor, Viewer và Outsider.',
    '',
    'Phù Văn Thái',
    'Học kỳ 1 - 2026',
    array['testing', 'test-cases', 'ca-nhan']
  )
  on conflict (id) do update set owner_id = v_uid_thai3;

end $$;
