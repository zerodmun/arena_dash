# Memos-Style Transformation Plan

## Referensi: https://github.com/usememos/memos

## Perbedaan Utama: Evernote vs Memos

### Evernote-style (Current)
- Notebook/folder organization
- Grid view
- Complex tags, colors, notebooks
- Archive/pin features
- Hierarchical organization

### Memos-style (Target)
- **Timeline/stream view** (vertical list, chronologis)
- **Instant capture** (input prominent di atas)
- **Markdown-focused** (render markdown di timeline)
- **Minimal organization** (no folders, maybe just visibility)
- **Quick capture philosophy** (buka → tulis → selesai)
- **Microblog style** (seperti social feed)

## Rencana Perubahan

### 1. UI/UX Changes
- [ ] Ganti dari grid view → timeline list view (seperti social media feed)
- [ ] Tambah quick capture input di bagian atas (prominent)
- [ ] Hapus sidebar complex (notebooks, folders)
- [ ] Hapus fitur: notebooks, tags complex, color coding
- [ ] Fokus pada: timeline + input field

### 2. Model Changes (`lib/models/note.dart`)
- [ ] Tambah field `visibility` (PRIVATE, PUBLIC, PROTECTED)
- [ ] Field `content` harus mendukung Markdown
- [ ] Pertimbangkan `parent_id` untuk reply/thread (optional)
- [ ] Hapus: notebook, tags, color (atau simplify)

### 3. Database Changes (`lib/database/database_service.dart`)
- [ ] Update schema: tambah `visibility` field
- [ ] Hapus notebook, tags, color columns (atau biarkan tapi tidak digunakan)
- [ ] Query utama: ORDER BY created_at DESC (timeline)
- [ ] Simplify: tidak perlu complex filtering

### 4. Home Screen (`lib/screens/home_screen.dart`)
- [ ] **REWRITE TOTAL** - buat timeline view:
  ```
  +---------------------------+
  | [Quick Capture Input]     | ← Input prominent di atas
  +---------------------------+
  | Memo 3 (latest)          | ← Timeline list
  | Memo 2                    |
  | Memo 1 (oldest)          |
  +---------------------------+
  ```
- [ ] Render markdown content di list items
- [ ] Swipe actions: delete, edit
- [ ] No sidebar - cukup bottom nav atau simple top bar

### 5. Editor (`lib/screens/note_editor_screen.dart`)
- [ ] Simplify: fokus pada quick input
- [ ] Markdown preview/editor
- [ ] Visibility selector (Private/Public)
- [ ] Hapus: notebook selector, tags, colors, pin, archive

### 6. New Features to Add
- [ ] **Markdown renderer** - untuk menampilkan memo di timeline
  - Package: `flutter_markdown` atau `markdown_widget`
- [ ] **Quick capture** - input field tetap di atas, bisa submit dengan Enter
- [ ] **Timeline animation** - maybe slide-in animation untuk memo baru
- [ ] **Visibility toggle** - private/public memo

### 7. Packages to Add (`pubspec.yaml`)
- [ ] `flutter_markdown: ^0.7.0` - render markdown
- [ ] `markdown: ^7.0.0` - parse markdown
- [ ] Hapus: provider (atau tetap, tapi simplify state management)

## Implementation Priority

1. **Phase 1: Core Timeline** (Paling penting)
   - Buat timeline list view
   - Quick capture input di atas
   - Markdown rendering

2. **Phase 2: Simplify**
   - Hapus fitur Evernote yang tidak perlu
   - Clean up UI

3. **Phase 3: Polish**
   - Animations
   - Better markdown support
   - Visibility features

## File Structure (New)
```
lib/
├── models/
│   └── memo.dart          # Rename note → memo, add visibility
├── database/
│   └── memo_service.dart  # Simplify, timeline queries
├── providers/
│   └── memo_provider.dart # Simplify state
├── screens/
│   ├── timeline_screen.dart   # NEW: main timeline view
│   └── memo_editor_screen.dart # Simplify existing
├── widgets/
│   ├── memo_card.dart      # Timeline card dengan markdown
│   └── quick_capture.dart # Input di atas
└── main.dart
```

## Key Design Principles (Memos Philosophy)
1. **Speed over organization** - tulis cepat, organisasi belakangan
2. **Timeline is king** - chronologis feed adalah fokus utama
3. **Markdown first** - semua content dalam markdown
4. **Minimal clicks** - seminimal mungkin langkah untuk capture
5. **Own your data** - self-hosted friendly (SQLite/local first)

## Reminders for AI
- JANGAN buat complex folder/notebook organization
- JANGAN buat grid view (pakai ListView timeline)
- JANGAN over-engineer dengan tags, colors, dll
- LAKUKAN: simple timeline dengan quick capture
- LAKUKAN: markdown rendering di timeline
- LAKUKAN: fokus pada kecepatan user menulis

## Status Implementasi (Updated: 2026-04-29)

### ✅ Sudah Selesai:
1. ✅ Model `Memo` sudah dibuat (`lib/models/memo.dart`)
   - Field: id, content (markdown), visibility, created_at, updated_at
   - Helper: `title` (extract dari first line), `preview` (strip markdown)
2. ✅ Database `MemoService` sudah dibuat (`lib/database/memo_service.dart`)
   - Timeline query: ORDER BY created_at DESC
   - Quick capture: `captureMemo()`
   - Support web (SharedPreferences) & macOS (SQLite)
3. ✅ Widget `QuickCapture` sudah dibuat (`lib/widgets/quick_capture.dart`)
   - Expandable input (tap → expand)
   - Submit dengan button atau Enter
4. ✅ `TimelineScreen` sudah dibuat (`lib/screens/timeline_screen.dart`)
   - Timeline list view (bukan grid!)
   - Markdown rendering dengan `flutter_markdown`
   - Pull-to-refresh
   - Delete & edit actions
5. ✅ `MemoEditorScreen` disederhanakan (`lib/screens/memo_editor_screen.dart`)
   - Edit/Preview toggle (markdown)
   - Minimal UI (fokus pada content)
6. ✅ `main.dart` updated ke Memos-style
   - Direct ke TimelineScreen
   - Theme orange (khas memos)
7. ✅ `pubspec.yaml` updated
   - Added: `flutter_markdown: ^0.7.1`
   - Removed: `provider` (tidak dipakai), `sqflite_common_ffi`, `shared_preferences` tetap

### ⏳ Belum Selesai (Optional):
- [ ] Visibility selector (PRIVATE/PUBLIC) di editor
- [ ] Search functionality
- [ ] Animations untuk memo baru
- [ ] Delete confirmation dialog
- [ ] Error handling yang lebih baik
- [ ] Unit tests

### 📝 File Structure (Final):
```
lib/
├── models/
│   └── memo.dart           ✅ Done
├── database/
│   └── memo_service.dart   ✅ Done
├── screens/
│   ├── timeline_screen.dart    ✅ Done (main screen)
│   └── memo_editor_screen.dart ✅ Done (simplified)
├── widgets/
│   └── quick_capture.dart  ✅ Done
└── main.dart                ✅ Done
```

### 🎯 Key Features (Memos-style):
- ✅ **Timeline-first UI** - ListView chronologis
- ✅ **Quick Capture** - Input prominent di atas
- ✅ **Markdown-native** - Render markdown di timeline
- ✅ **Minimal organization** - No folders, no notebooks
- ✅ **Instant capture philosophy** - Buka → Tulis → Selesai

### 🚀 Next Steps:
1. Test di web: `flutter run -d chrome --release`
2. Test di macOS: `flutter run -d macos`
3. Tambah visibility selector jika diperlukan
4. Polish UI/UX

---
Created: 2026-04-29
Updated: 2026-04-29
Based on: https://github.com/usememos/memos (59.3k ⭐)
