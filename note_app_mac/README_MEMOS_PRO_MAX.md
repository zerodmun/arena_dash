# Memos Flutter - UI/UX Pro Max ✨

## Dokumentasi Lengkap Aplikasi

Berdasarkan: https://github.com/usememos/memos (59.3k ⭐)

---

## ✅ Fitur yang Sudah Diimplementasi

### 1. **Core Memos Features**
- ✅ **Timeline-First UI** - Cronologis feed seperti social media
- ✅ **Quick Capture** - Input prominent di atas dengan animasi expand/collapse
- ✅ **Markdown-Native** - Render markdown di timeline dengan `flutter_markdown`
- ✅ **Minimal Organization** - Tanpa folder/notebook yang ribet

### 2. **Advanced Features**
- ✅ **Tags System** - Auto-extract tags dari `#tag` di markdown
- ✅ **Pin Memos** - Sematkan memo penting di atas
- ✅ **Archive Memos** - Sembunyikan memo lama tapi tetap tersimpan
- ✅ **Visibility Settings** - Private/Public/Protected
- ✅ **Search Functionality** - Cari di content dan tags
- ✅ **Edit/Preview Toggle** - Switch antara edit dan preview markdown
- ✅ **Delete Confirmation** - Dialog konfirmasi hapus

### 3. **UI/UX Pro Max Features**
- ✅ **Premium Theme** - Orange palette yang sophisticated
- ✅ **Dark Mode** - Support light/dark theme (mengikuti system)
- ✅ **Smooth Animations** - Expand/collapse, smooth transitions
- ✅ **Gradient Dividers** - Pembatas dengan gradient halus
- ✅ **Modern Cards** - Rounded corners (16px), subtle borders
- ✅ **Floating Snackbars** - Success/error dengan icon dan warna
- ✅ **SliverAppBar** - AppBar yang responsive dan smooth
- ✅ **Empty State** - Icon besar dengan gradient background
- ✅ **Responsive Layout** - Padding dan spacing yang konsisten

---

## 📁 Struktur File

```
lib/
├── main.dart                        # Entry point + theme setup
├── theme/
│   └── app_theme.dart               # Premium light/dark theme
├── models/
│   └── memo.dart                    # Memo model (tags, pin, archive)
├── database/
│   └── memo_service.dart           # SQLite (macOS) + SharedPreferences (Web)
├── screens/
│   ├── timeline_screen.dart        # 🎯 Main timeline (Pro Max UI)
│   └── memo_editor_screen.dart    # Editor dengan visibility + pin/archive
└── widgets/
    └── quick_capture.dart          # Animated quick capture input
```

---

## 🎨 Design System

### Color Palette
```dart
Primary Orange: #E9730A
Light Background: #FAFAFA
Dark Background: #121212
Card Light: #FFFFFF
Card Dark: #1E1E1E
```

### Typography
- Title: 28px, Weight 700, Letter-spacing -0.5
- Body: 14-16px, Height 1.5-1.6
- Tags: 12px, FontWeight 500

### Components
- **Cards**: BorderRadius 16px, Border 1px, Elevation 0
- **Buttons**: BorderRadius 10px, Padding horizontal 24
- **Inputs**: BorderRadius 12px, Filled background
- **Chips/Tags**: BorderRadius 8px, Primary color with opacity

---

## 🚀 How to Run

### Prerequisites
- Flutter SDK terinstall
- Xcode (untuk macOS) atau Brave/Chrome (untuk Web)
- macOS: Xcode command line tools

### Run di Web (Brave/Chrome)
```bash
cd /Users/tentendigitalindonesia/Downloads/note_app_mac
flutter run -d chrome --release
```

### Run di macOS
```bash
cd /Users/tentendigitalindonesia/Downloads/note_app_mac
flutter run -d macos --release
```

### Set Brave sebagai default browser (Optional)
```bash
export CHROME_EXECUTABLE="/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
flutter run -d chrome --release
```

---

## 📝 Cara Pakai

### 1. **Quick Capture**
- Klik input di atas atau tap "+" icon
- Tulis catatan dalam Markdown
- Tekan "Capture" atau Enter
- Tags otomatis terdeteksi dari `#tag`

### 2. **Timeline**
- Scroll untuk melihat semua memo
- Pinned memo muncul di atas (orange pin icon)
- Tap memo untuk edit
- Tap 3-dots menu untuk Pin/Archive/Edit/Delete

### 3. **Edit Memo**
- Tap memo di timeline
- Toggle antara Edit/Preview mode
- Atur Visibility (Private/Public/Protected)
- Toggle Pin dan Archive
- Save dengan tombol checkmark

### 4. **Search**
- Tap icon search di appbar
- Ketik kata kunci
- Search otomatis mencari di content dan tags

### 5. **Tags**
- Gunakan `#tag` di dalam markdown content
- Tags otomatis terdeteksi dan ditampilkan di card
- Klik tag untuk filter (segera hadir)

---

## 🔧 Technical Details

### Database
- **macOS**: SQLite via `sqflite_common_ffi`
- **Web**: SharedPreferences (localStorage)
- Auto-migrasi database (version 1 → 2)

### State Management
- Simple StatefulWidget + setState
- Direct call ke MemoService

### Packages
```yaml
dependencies:
  flutter_markdown: ^0.7.1    # Render markdown
  sqflite_common_ffi: ^2.3.0  # SQLite macOS
  shared_preferences: ^2.3.0    # Web storage
  intl: ^0.19.0               # Date formatting
```

---

## 🎯 Memos Philosophy (Implemented)

> **"Built for quick capture"**

1. ✅ **Speed over organization** - Tulis cepat, organisasi belakangan
2. ✅ **Timeline is king** - Cronologis feed adalah fokus utama
3. ✅ **Markdown first** - Semua content dalam markdown
4. ✅ **Minimal clicks** - Seminimal mungkin langkah untuk capture
5. ✅ **Own your data** - Self-hosted friendly, format portable

---

## 📊 Comparison: Current vs Original Memos

| Fitur | Flutter App | Original Memos | Status |
|-------|------------|----------------|--------|
| Timeline UI | ✅ Pro Max | ✅ | Complete |
| Quick Capture | ✅ Animated | ✅ | Complete |
| Markdown | ✅ Render + Preview | ✅ | Complete |
| Tags | ✅ Auto-extract | ✅ | Complete |
| Pin/Archive | ✅ | ✅ | Complete |
| Visibility | ✅ UI Ready | ✅ | Complete |
| Search | ✅ Content + Tags | ✅ | Complete |
| Dark Mode | ✅ System-based | ✅ | Complete |
| UI/UX | ✅ Pro Max | ⭐ Clean | Enhanced |
| Auth/Users | 🔲 | ✅ | Future |
| REST API | 🔲 | ✅ | Future |
| SSE Live Update | 🔲 | ✅ | Future |
| Attachments | 🔲 | ✅ | Future |
| Webhooks | 🔲 | ✅ | Future |

---

## 🚀 Next Development (Optional)

### Phase 1: Backend (Multi-User)
- [ ] Go backend dengan Echo v5
- [ ] JWT authentication
- [ ] REST API (Connect RPC + gRPC)
- [ ] PostgreSQL support

### Phase 2: Advanced Features
- [ ] Attachments (upload gambar/file)
- [ ] Comments di memo
- [ ] Reactions (emoji)
- [ ] RSS feeds
- [ ] SSE untuk live updates

### Phase 3: Integrations
- [ ] Webhooks
- [ ] MCP Server (AI assistants)
- [ ] CLI client
- [ ] Mobile apps (iOS/Android)

---

## 📖 Referensi

- **Repository**: https://github.com/usememos/memos
- **Documentation**: https://usememos.com/docs
- **Live Demo**: https://demo.usememos.com
- **Architecture**: https://usememos.com/docs/operations/architecture

---

## 🎉 Status: COMPLETE (Phase 0)

Aplikasi Flutter Memos-style dengan **UI/UX Pro Max** sudah selesai!

Fitur utama:
- ✅ Timeline dengan smooth UI
- ✅ Quick capture dengan animasi
- ✅ Markdown editor + preview
- ✅ Tags, Pin, Archive
- ✅ Search functionality
- ✅ Dark/Light theme
- ✅ Premium design system

**Coba sekarang di Brave!** 🚀

---
Created: 2026-04-29
Version: 1.0.0
Status: ✅ Production Ready (Core Features)
