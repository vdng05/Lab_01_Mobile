# Thiết lập Firebase, Supabase và kiểm thử quyền

## Trạng thái và nền tảng

Repository đã có FlutterFire options cho Firebase project `my-docs-manager-9cdf8` trên Android, web và Windows. iOS/macOS chưa có app configuration; cần đăng ký platform đó trong Firebase Console và chạy lại FlutterFire CLI trước khi build. Firebase Auth/Storage và Supabase Flutter được nối trong source, nhưng việc đăng nhập và RLS live chỉ hoạt động sau khi hoàn tất các bước project bên dưới.

Ứng dụng dùng Firebase UID làm `app_users.id`, `documents.owner_id` và `document_permissions.user_id`. Supabase nhận Firebase ID token làm JWT. Không đặt Supabase service-role key trong Flutter.

## Thiết lập Firebase

1. Mở Firebase project `my-docs-manager-9cdf8`, bật Google ở **Authentication > Sign-in method**.
2. Thêm authorized domains cho web; cấu hình OAuth consent screen và OAuth client theo hướng dẫn Google/Firebase.
3. Bật Firebase Storage. Deploy `firebase/storage.rules`; rule giới hạn file 25 MiB, MIME type và chỉ cho user tải lên path `users/{uid}/documents/{documentId}/...` của chính UID.
4. Với Android, giữ `android/app/google-services.json` và Gradle Google Services plugin hiện có. Thêm SHA-1/SHA-256 cho signing keys dùng thử nếu Firebase Console yêu cầu.
5. Google Sign-In dùng `google_sign_in` trên Android/iOS/macOS; web dùng Firebase popup; Windows dùng Firebase Auth provider flow. Cấu hình đúng OAuth client IDs cho từng platform trong Firebase/Google Console.

## Thiết lập Supabase

1. Tạo Supabase project và bật third-party authentication cho Firebase trong phần **Authentication > Third-Party Auth**; nhập Firebase project ID `my-docs-manager-9cdf8`. Supabase phải xác minh Firebase JWT và đưa request vào role `authenticated`.
2. Chạy migration `supabase/migrations/202610130001_cloud_document_access.sql` bằng Supabase CLI hoặc SQL Editor. Migration tạo `app_users`, `documents`, `document_permissions`, helper functions, trigger bảo vệ ownership và RLS policies.
3. Bật extension `pgtap` nếu chưa có, rồi chạy `supabase test db` để thực hiện các policy tests.
4. Lấy Project URL và publishable key (anon key cũ cũng là public client key) từ Supabase Dashboard. Chỉ dùng publishable key trong ứng dụng; không đưa service-role key vào app hoặc repo.

## Cấu hình chạy ứng dụng

Chạy app ở cloud mode bằng hai compile-time defines. Ví dụ PowerShell:

```powershell
flutter run -d windows `
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co `
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY `
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_GOOGLE_SERVER_CLIENT_ID
```

Thay `windows` bằng `chrome` hoặc `android` khi cần. Nếu Supabase defines bị bỏ qua, ứng dụng chủ động khởi động local mode, không gọi Firebase/Supabase.

## Cloud Function cấp download URL

Shared files không được mở bằng URL public dài hạn. Flutter gửi callable HTTPS request có Firebase ID token; Cloud Function xác thực Firebase user, tra `documents` và `document_permissions` bằng service role, rồi mới cấp signed URL chỉ đọc có hạn 5 phút.

1. Tạo file `functions/.env.my-docs-manager-9cdf8` (không commit) với `SUPABASE_URL=https://YOUR_PROJECT.supabase.co`.
2. Đặt service key trong Firebase Secret Manager:

```powershell
firebase functions:secrets:set SUPABASE_SERVICE_ROLE_KEY --project my-docs-manager-9cdf8
```

3. Cài dependencies và deploy rules/function:

```powershell
Push-Location functions
npm install
npm run build
Pop-Location
firebase deploy --only storage,functions --project my-docs-manager-9cdf8
```

Function chạy ở `us-central1` mặc định; nếu đổi region, truyền `FIREBASE_FUNCTIONS_REGION` khi build Flutter để endpoint khớp.

## Luồng kiểm thử nhiều tài khoản

Tạo ít nhất bốn tài khoản Google test riêng trong Firebase Auth:

| Vai trò | Thao tác mong đợi |
| --- | --- |
| A - owner | Đăng nhập, tạo tài liệu/file, chia sẻ cho B với `view` và C với `edit`. |
| B - viewer | Thấy tài liệu và mở file; không có sửa/xóa/chia sẻ. Thử gọi update trực tiếp cũng phải bị RLS chặn. |
| C - editor | Thấy và sửa metadata; không xóa, không đổi owner hoặc thay file đính kèm. |
| D - outsider | Không thấy metadata, không mở file; signed URL Function trả permission denied. |

Ghi nhận email/UID test, quyền cấp, kết quả list/read/update/delete và thời điểm URL hết hạn; không lưu token vào ảnh/log. SQL test `supabase/tests/document_sharing_rls.test.sql` mô phỏng bốn Firebase `sub` claims và kiểm tra owner, viewer, editor, outsider. Đây là test RLS bằng claims giả lập; nó không thay thế lượt kiểm thử tích hợp bằng bốn phiên đăng nhập Google thật ở bảng trên.

## Giới hạn cần biết

- `google_sign_in` không có plugin Windows; Windows dùng native provider của Firebase Auth. OAuth app registration/redirect phải được cấu hình cho Firebase project và kiểm tra trên máy Windows thực.
- Chia sẻ theo email chỉ tìm được người đã từng đăng nhập và đồng bộ profile vào `app_users`.
- RLS bảo vệ SQL; Firebase Storage Rules chỉ cho owner đọc trực tiếp. Người được chia sẻ lấy file qua signed URL Function sau khi kiểm tra permission.
- Dữ liệu mẫu local không được đưa lên cloud tự động. Tài liệu cloud chỉ hiện tài liệu do user tạo hoặc được chia sẻ với UID đó.
- Repo không chứa Supabase URL/key hay secret function. Chưa có Supabase project credentials trong môi trường, nên live sign-in, deployment và test với tài khoản Google thật chưa được thực thi tại đây.