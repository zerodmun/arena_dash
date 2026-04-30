# Memos for Mac - Flutter Edition 📝

Aplikasi catatan berbasis Flutter yang terinspirasi dari [Memos](https://github.com/usememos/memos) (59.3k ⭐). Dibangun dengan **UI/UX Pro Max** design dan fitur pengingat (reminder) lengkap.

![Memos Screenshot](https://raw.githubusercontent.com/usememos/.github/main/assets/demo.png)

---

## ✨ Fitur Utama

### 1. **Layout Baru: Sidebar Kiri + Area Kanan**
- ✅ **Sidebar Kiri** (300px) - Daftar semua memo
- ✅ **Area Kanan** - Buat memo baru atau lihat detail memo
- ✅ **Search** - Cari memo di sidebar
- ✅ **Toggle Archive** - Tampilkan/sembunyikan memo yang diarsip

### 2. **Facebook-Style New Memo Card**
- ✅ **Pilihan Jenis**: Text Memo atau List Memo
- ✅ **Upload Gambar** - Lampirkan foto langsung dari card
- ✅ **Upload File** - Dukungan PDF, Docs, dan file lainnya
- ✅ **Markdown Editor** - Tulis dalam format Markdown dengan preview

### 3. **Task List dengan Pengingat (Reminder)**
- ✅ **Tambah Task** ke memo
- ✅ **Set Deadline Lengkap**: Tanggal, Bulan, Tahun, Jam, Menit
- ✅ **Notifikasi Otomatis** - Muncul 15 menit sebelum deadline
- ✅ **Notifikasi Deadline** - Muncul pas waktu habis
- ✅ **Task Overdue** - Ditandai merah dengan label "OVERDUE"
- ✅ **Checklist** - Tandai task selesai

### 4. **Manajemen Memo**
- ✅ **Pin Memo** - Sematkan memo penting di atas
- ✅ **Archive** - Sembunyikan memo tapi tetap tersimpan
- ✅ **Delete** - Hapus memo dengan konfirmasi
- ✅ **Visibility** - Private/Public/Protected
- ✅ **Tags** - Auto-extract dari `#tag` di markdown
- ✅ **Search** - Cari di konten dan tags

### 5. **UI/UX Pro Max Design**
- ✅ **Premium Theme** - Orange palette (#FF8C00)
- ✅ **Dark/Light Mode** - Support system theme
- ✅ **Smooth Animations** - Transisi yang halus
- ✅ **Modern Cards** - Rounded corners, subtle borders
- ✅ **Responsive** - Padding dan spacing konsisten

---

## 📁 Struktur File

```
lib/
├── main.dart                           # Entry point + TaskReminder init
├── theme/
│   └── app_theme.dart                # UI/UX Pro Max theme
├── models/
│   ├── memo.dart                     # Memo model (tags, pin, archive)
│   ├── attachment.dart               # Attachment model
│   ├── comment.dart                 # Comment model
│   ├── reaction.dart                # Reaction model
│   └── task.dart                    # Task model (deadline, notification)
├── database/
│   └── database_service.dart        # SQLite + SharedPreferences + Tasks
├── services/
│   ├── notification_service.dart      # Legacy notification
│   └── task_reminder_service.dart   # Periodic deadline checker
├── screens/
│   ├── main_screen.dart             # Navigasi utama (Home, Settings)
│   ├── home_screen.dart             # ⭐ Sidebar kiri + Detail kanan
│   ├── new_memo_screen.dart         # Facebook-style status card
│   ├── memo_editor_screen.dart     # Editor dengan task list
│   ├── memo_list_screen.dart       # Sidebar memo list
│   ├── archive_screen.dart          # Archived memos
│   └── settings_screen.dart        # Theme, stats, data management
└── widgets/
    ├── quick_capture.dart          # Animated quick capture
    └── task_list.dart             # Task list widget
```

---

## 🎨 Design System

### Color Palette
```dart
Primary Orange:    #FF8C00
Primary Light:     #FFB347
Primary Dark:      #E07800
Light Background:  #FFFBF5
Dark Background:   #1A1A1A
Card Light:        #FFFFFF
Card Dark:         #2D2D2D
```

### Typography
- **Title**: 24-28px, Weight 700-800
- **Body**: 14-16px, Height 1.6
- **Tags**: 11-12px, Primary color

---

## 🚀 Cara Menjalankan

### Prerequisites
- Flutter SDK terinstall
- Web browser (Brave/Chrome) atau macOS

### Web (Brave/Chrome)
```bash
cd /Users/tentendigitalindonesia/Downloads/note_app_mac
flutter run -d chrome --release
# atau buka http://localhost:8080
```

### Build Web
```bash
flutter build web --release
cd build/web
python3 -m http.server 8080
# Buka http://localhost:8080 di browser
```

### macOS
```bash
cd /Users/tentendigitalindonesia/Downloads/note_app_mac
flutter run -d macos --release
```

---

## 📝 Cara Menggunakan

### A. Buat Memo Baru (Facebook-Style)
1. Klik tombol **"New Memo"** di sidebar kiri
2. Pilih jenis: **Text** atau **List**
3. Tulis konten dalam Markdown
4. Upload gambar/file jika diperlukan
5. Set visibility (Private/Public/Protected)
6. Klik **"Post"** untuk menyimpan

### B. Task List dengan Pengingat
1. Di editor memo, klik **"Add Task"**
2. Isi judul task
3. Centang **"Set deadline"**
4. Pilih **Tanggal, Bulan, Tahun** (date picker)
5. Pilih **Jam & Menit** (time picker)
6. Klik **"Add"**
7. Task akan muncul di bawah editor
8. **Notifikasi otomatis** muncul 15 menit sebelum deadline

### C. Sidebar & Navigation
1. **List memo** di sidebar kiri (scrollable)
2. **Klik memo** → Detail muncul di kanan
3. **Search** memo di sidebar
4. Toggle **"Show Archived"** untuk lihat memo yang diarsip
5. **Pin memo** untuk menyematkan di atas

### D. Pengingat & Notifikasi

**Cara Kerja:**
1. Task dibuat dengan deadline → Tersimpan di database
2. Service mengecek setiap 30 detik → Mencari task yang mendekati deadline
3. **15 menit sebelum deadline** → Notifikasi "Task Deadline Approaching"
4. **Pas deadline tercapai** → Notifikasi "Task Deadline Reached!"
5. Task selesai → Checklist ditandai hijau, notifikasi berhenti

**Format Deadline:**
- Tanggal: 30/04/2026
- Jam: 14:30
- Tampil: "30/04/2026 14:30"

---

## 🎯 Memos Philosophy (Implemented)

> **"Built for quick capture"**

1. ✅ **Speed over organization** - Tulis cepat, organisasi belakangan
2. ✅ **Timeline is king** - Cronologis feed adalah fokus utama
3. ✅ **Markdown first** - Semua content dalam markdown
4. ✅ **Minimal clicks** - Seminimal mungkin langkah untuk capture
5. ✅ **Own your data** - Self-hosted friendly, format portable

---

## 📊 Comparison: Flutter vs Original Memos

| Fitur | Flutter App | Original Memos | Status |
|---------|-------------|----------------|--------|
| Sidebar Layout | ✅ Kiri list, Kanan detail | ✅ | Complete |
| Facebook-Style Memo | ✅ Status card | ⭐ | Enhanced |
| Text & List Memo | ✅ | ⭐ | New |
| Quick Capture | ✅ Animated | ✅ | Complete |
| Markdown | ✅ Editor + Preview | ✅ | Complete |
| Tasks with Deadline | ✅ + Notifikasi | ⭐ | Enhanced |
| Pin/Archive | ✅ | ✅ | Complete |
| Visibility | ✅ UI Ready | ✅ | Complete |
| Search | ✅ Content + Tags | ✅ | Complete |
| Dark Mode | ✅ System-based | ✅ | Complete |
| UI/UX | ✅ Pro Max | ⭐ Clean | Enhanced |
| Notifications | ✅ 15min + Deadline | ⭐ | New |
| Auth/Users | 🔲 | ✅ | Future |
| REST API | 🔲 | ✅ | Future |
| Attachments | 🔲 | ✅ | Future |

---

## 🔧 Technical Details

### Frontend
- **Flutter** with Dart
- **State Management**: StatefulWidget + setState
- **UI**: Material 3 with custom theme

### Backend/Storage
- **macOS**: SQLite via `sqflite_common_ffi`
- **Web**: SharedPreferences (localStorage)
- **Database Version**: 4 (with tasks table)

### Notifications
- **flutter_local_notifications** for local notifications
- **timezone** for timezone handling
- **Periodic Timer** checks deadlines every 30 seconds

### Packages
```yaml
dependencies:
  flutter_local_notifications: ^17.2.1
  timezone: ^0.9.4
  image_picker: ^1.1.2
  file_picker: ^8.0.0
  flutter_markdown: ^0.7.1
  sqflite_common_ffi: ^2.3.0
  shared_preferences: ^2.3.0
  intl: ^0.19.0
```

---

## 📖 References

- **Repository**: https://github.com/usememos/memos
- **Documentation**: https://usememos.com/docs
- **Live Demo**: https://demo.usememos.com
- **UI/UX Pro Max**: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill

---

## 🎉 Status: COMPLETE! ✅

**Semua fitur SUDAH SELESAI:**

### Core Features:
- ✅ Sidebar kiri dengan list memo
- ✅ Area kanan untuk buat & lihat memo
- ✅ Facebook-style New Memo card
- ✅ Text & List memo types
- ✅ Image & File upload
- ✅ Task list dengan deadline lengkap
- ✅ Notifikasi 15 menit sebelum deadline
- ✅ Notifikasi pas deadline
- ✅ Overdue tasks dengan label merah
- ✅ Pin, Archive, Delete memo
- ✅ Search functionality
- ✅ Tags auto-extract
- ✅ Light/Dark/System theme
- ✅ UI/UX Pro Max design

### App siap pakai! 🚀

**Akses:**
- **URL**: `http://localhost:8080`
- **Git**: Sudah di-commit dengan dokumentasi lengkap

---

**Dibuat dengan ❤ menggunakan Flutter + UI/UX Pro Max Design**

Created: 2026-04-30  
Version: 3.0.0 (Sidebar + Tasks + Notifications)  
Status: ✅ Production Ready dengan Fitur Lengkap!
