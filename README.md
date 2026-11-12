# QLHocPhan — Quản lý giảng viên (Flutter + Firebase)

Ứng dụng Flutter đa nền tảng (Web / Android / iOS) quản lý danh sách giảng viên.
Mỗi giảng viên **chỉ gồm 4 trường** đúng theo đề bài: `IDGV`, `Fullname`, `Image`,
`SumClass` — không thêm field nào khác vào Firestore.

## Chức năng

| Nhóm           | Chi tiết                                                                                                                                                  |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Xác thực       | Đăng nhập Email/Password, **đăng ký tài khoản**, **quên mật khẩu** (gửi email reset), đăng xuất, chặn truy cập khi chưa đăng nhập                         |
| CRUD           | Thêm / sửa / xóa giảng viên, validate IDGV (không trùng, không chứa `/`), SumClass là số nguyên ≥ 0                                                       |
| Ảnh            | Chọn ảnh từ thư viện hoặc chụp ảnh (mobile), tải lên **Firebase Storage** `giang_vien/<IDGV>-<timestamp>`, lưu URL vào `Image`; xóa giảng viên sẽ xóa ảnh |
| Realtime       | `StreamBuilder` trên `snapshots()` của Firestore — dữ liệu tự cập nhật khi thiết bị khác thay đổi                                                         |
| Tìm kiếm & lọc | Tìm theo mã/tên, lọc "tải cao (≥6 lớp)", sắp xếp theo mã / tên / số lớp                                                                                   |
| Hiển thị       | Chuyển đổi **Lưới ↔ Danh sách**, thẻ chi tiết (bottom sheet) hiển thị đúng 4 trường dữ liệu                                                               |
| Thống kê       | Tổng giảng viên, tổng lớp, lớp/GV trung bình, GV phụ trách nhiều nhất, bảng xếp hạng top 5, **biểu đồ phân bố khối lượng tương tác (Donut & Bar Chart)** |
| Dữ liệu        | **Nhập (Import) hàng loạt từ CSV / JSON**, xuất **CSV** (mở được bằng Excel, có BOM UTF-8) và **JSON** (đúng cấu trúc Firestore để nộp bài), nạp dữ liệu mẫu |
| Giao diện      | Material 3, gradient + aurora background, **sáng/tối**, responsive từ điện thoại đến desktop                                                              |

## Chạy thử

```powershell
flutter pub get
flutter run -d chrome
```

Mặc định chạy **chế độ demo** (dữ liệu mẫu trong bộ nhớ, không cần Firebase) để
chấm offline. Dữ liệu demo mất khi khởi động lại.

```powershell
flutter test      # 11 test: model, service, import/export CSV/JSON, widget
flutter analyze   # không có lỗi
```

## Kết nối Firebase

1. Tạo Firebase project → bật **Authentication (Email/Password)**, **Cloud Firestore**, **Storage**.
2. Tạo collection `GiangVien`; document ID = `IDGV`; mỗi document có 4 trường
   `IDGV` (string), `Fullname` (string), `Image` (string URL), `SumClass` (number).
3. Tạo tài khoản quản trị trong Authentication → Users (hoặc dùng nút **Đăng ký ngay** trong app).
4. Lấy cấu hình Web app ở Project settings → tạo file `firebase.json` (đã có trong `.gitignore`):

```json
{
  "USE_FIREBASE": "true",
  "FIREBASE_API_KEY": "AIza...",
  "FIREBASE_APP_ID": "1:1234567890:web:abcdef",
  "FIREBASE_MESSAGING_SENDER_ID": "1234567890",
  "FIREBASE_PROJECT_ID": "your-project-id",
  "FIREBASE_AUTH_DOMAIN": "your-project-id.firebaseapp.com",
  "FIREBASE_STORAGE_BUCKET": "your-project-id.firebasestorage.app"
}
```

5. Chạy / build:

```powershell
flutter run -d chrome --dart-define-from-file=firebase.json
flutter build web --dart-define-from-file=firebase.json
```

Có thể truyền từng biến bằng `--dart-define=KEY=value` thay vì dùng file.

### Firestore Rules (chỉ tài khoản đã đăng nhập)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /GiangVien/{idgv} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Rules

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /giang_vien/{file} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

Firebase API key phía client không phải mật khẩu quản trị; quyền truy cập phải
được bảo vệ bằng Rules ở trên. Không commit service account key.

## Cấu trúc mã nguồn

```
lib/
├── main.dart                     # khởi tạo Firebase, theme sáng/tối, điều hướng
├── models/teacher.dart           # model 4 trường + fromMap/toMap
├── services/
│   ├── teacher_service.dart      # Firestore + Storage + realtime stream + demo
│   ├── teacher_exporter.dart     # xuất CSV / JSON
│   └── auth_errors.dart          # dịch mã lỗi FirebaseAuth sang tiếng Việt
├── auth/auth_gate.dart           # đăng nhập / đăng ký / quên mật khẩu
├── screens/teacher_dashboard.dart# màn hình quản trị chính
├── theme/app_theme.dart          # bảng màu, theme Material 3
└── widgets/                      # avatar, card, form, chi tiết, thống kê
```
# LTDT_PTUD-NT_GK_2026
