# Memos Architecture & Features Documentation

## Referensi
- Repository: https://github.com/usememos/memos
- Stars: 59.3k ⭐
- License: MIT
- Homepage: https://usememos.com

---

## 1. Arsitektur Sistem Memos

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────┐
│                    Frontend (React)                     │
│         React 18 + TypeScript + Vite 7                 │
│    State: React Query v5 + React Context               │
│    Styling: Tailwind CSS v4                           │
└──────────────────┬──────────────────────────────────────┘
                   │ HTTP/JSON
                   │ Connect RPC / gRPC-Gateway
┌──────────────────▼──────────────────────────────────────┐
│                  API Layer (Go)                        │
│         Echo v5 HTTP Server                            │
│    ┌──────────────────────────────────┐               │
│    │  Connect RPC (/memos.api.v1.*)  │ ← Browser    │
│    └──────────────────────────────────┘               │
│    ┌──────────────────────────────────┐               │
│    │  gRPC-Gateway (/api/v1/*)       │ ← External   │
│    └──────────────────────────────────┘               │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│                Service Layer                            │
│    • Auth (JWT + Refresh tokens)                       │
│    • Memo operations                                   │
│    • User management                                   │
│    • Webhook dispatcher                                │
│    • SSE (Server-Sent Events) for live updates        │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│                Store Layer                               │
│    • Internal storage messages (Protocol Buffers)        │
│    • Database drivers: SQLite / MySQL / PostgreSQL      │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│              Database                                   │
│    SQLite (default) / MySQL / PostgreSQL               │
└─────────────────────────────────────────────────────────┘
```

### Tech Stack (Original Memos)
| Layer | Technology |
|-------|-------------|
| Backend Language | Go 1.25+ |
| HTTP Router | Echo v5 |
| API Protocol | gRPC + Connect RPC (dual) |
| Schema | Protocol Buffers v2 |
| Databases | SQLite (default), MySQL, PostgreSQL |
| Frontend | React 18 + TypeScript |
| Frontend Build | Vite 7 |
| State Management | React Query v5 + React Context |
| API Client | Connect RPC |
| Styling | Tailwind CSS v4 |

---

## 2. Fitur-Fitur Utama Memos

### A. Core Features (Sudah diimplementasi di Flutter)

#### 1. **Timeline-First UI** ✅
- Cronologis feed seperti social media
- Instant capture: buka → tulis → selesai
- Tanpa folder/notebook navigation
- **Status Flutter:** ✅ `TimelineScreen` dengan ListView

#### 2. **Markdown-Native** ✅
- Content dalam format Markdown
- Render markdown di timeline
- Preview mode di editor
- **Status Flutter:** ✅ `flutter_markdown` package

#### 3. **Quick Capture** ✅
- Input field prominent di atas
- Expandable text field
- Submit dengan Enter/button
- **Status Flutter:** ✅ `QuickCapture` widget

#### 4. **Self-Hosted & Data Ownership**
- Deploy di infrastruktur sendiri
- Notes selalu dalam format Markdown (portable)
- Zero telemetry
- **Status Flutter:** 🔲 Belum (butuh backend)

---

### B. Features dari Memos (Belum diimplementasi)

#### 1. **Authentication & User Management**
```
- JWT Access Token (15 menit)
- Refresh Token (30 hari)
- Personal Access Tokens (PAT)
- User settings & profile
```
**Status Flutter:** 🔲 Belum (single user saat ini)

#### 2. **Visibility & Sharing**
```
- PRIVATE: Hanya pemilik
- PUBLIC: Semua orang bisa lihat
- PROTECTED: Hanya user terautentikasi
```
**Status Flutter:** 🔲 Model sudah ada (`visibility` field), UI belum

#### 3. **Dual-Protocol API**
```
Connect RPC (/memos.api.v1.*)
  └─ HTTP/JSON, type-safe, untuk browser frontend

gRPC-Gateway (/api/v1/*)
  └─ REST-compatible, untuk external tools/CLI
```
**Status Flutter:** 🔲 Belum (perlu Go backend)

#### 4. **Advanced Memo Features**
```
- Tags: #tag untuk kategorisasi
- Relations: memo A relate ke memo B
- Comments: Komentar di memo
- Attachments: Upload file/gambar
- Pin memo: Sematkan di atas
- Archive: Arsip memo lama
- Reactions: 👍 🎉 etc (seperti Slack)
```
**Status Flutter:** 🔲 Belum (hanya basic CRUD)

#### 5. **Live Updates (SSE)**
```
Server-Sent Events (SSE) untuk update real-time
- Memo baru dari user lain
- Comments, reactions
```
**Status Flutter:** 🔲 Belum

#### 6. **Webhooks & Integrations**
```
Webhook events:
- memo.created
- memo.updated
- memo.deleted
- comment.created
```
**Status Flutter:** 🔲 Belum

#### 7. **RSS Feeds**
```
- RSS feed per user
- RSS feed untuk public memos
```
**Status Flutter:** 🔲 Belum

#### 8. **MCP Server (AI Assistants)**
```
Model Context Protocol server untuk integrasi AI
- Claude, GPT, dll bisa akses memos
```
**Status Flutter:** 🔲 Belum

---

## 3. Arsitektur Flutter (Hasil Transformasi)

### Current Architecture (Flutter Memos-Style)
```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App                          │
│         Material 3 + Orange Theme                      │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│                Screens                                  │
│  ┌──────────────────────────────────────────────┐      │
│  │ TimelineScreen (Main)                        │      │
│  │  - QuickCapture widget                      │      │
│  │  - ListView timeline                        │      │
│  │  - Markdown rendering                       │      │
│  └──────────────────────────────────────────────┘      │
│  ┌──────────────────────────────────────────────┐      │
│  │ MemoEditorScreen                            │      │
│  │  - Edit/Preview toggle                     │      │
│  │  - Markdown editor                         │      │
│  └──────────────────────────────────────────────┘      │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│                Services                                  │
│  ┌──────────────────────────────────────────────┐      │
│  │ MemoService                                  │      │
│  │  - getTimeline()                            │      │
│  │  - captureMemo()                            │      │
│  │  - updateMemo()                             │      │
│  │  - deleteMemo()                             │      │
│  │  - searchMemos()                            │      │
│  └──────────────────────────────────────────────┘      │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│                Storage (Platform-specific)              │
│  ┌─────────────────┐  ┌──────────────────────────┐    │
│  │ macOS/iOS       │  │ Web                      │    │
│  │ SQLite          │  │ SharedPreferences        │    │
│  │ (sqflite_ffi)  │  │ (localStorage)           │    │
│  └─────────────────┘  └──────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### File Structure (Flutter)
```
lib/
├── models/
│   └── memo.dart              # Memo model (id, content, visibility, timestamps)
├── database/
│   └── memo_service.dart      # Storage abstraction (SQLite/SharedPreferences)
├── screens/
│   ├── timeline_screen.dart    # Main timeline view (memos-style)
│   └── memo_editor_screen.dart # Editor with markdown preview
├── widgets/
│   └── quick_capture.dart     # Quick capture input widget
└── main.dart                  # Entry point
```

---

## 4. Roadmap Pengembangan (Next Steps)

### Phase 1: Core Features (Prioritas Tinggi)
- [ ] **Visibility selector** (Private/Public) di editor
- [ ] **Search functionality** di timeline
- [ ] **Delete confirmation** dialog
- [ ] **Edit memo** dari timeline (saat ini hanya create baru)

### Phase 2: Memos-like Features
- [ ] **Tags** (`#tag` parsing di markdown)
- [ ] **Pin memo** (sematkan di atas timeline)
- [ ] **Archive memo** (hide dari timeline tapi tetap di DB)
- [ ] **Attachments** (upload gambar/file)

### Phase 3: Backend & Multi-User (Optional)
- [ ] **Go backend** dengan Echo v5
- [ ] **JWT authentication**
- [ ] **REST API** untuk external access
- [ ] **Database migration** (SQLite → PostgreSQL)

### Phase 4: Advanced Features (Optional)
- [ ] **SSE** untuk live updates
- [ ] **Webhooks** untuk integrations
- [ ] **RSS feeds**
- [ ] **Comments** di memo
- [ ] **Reactions** (emoji)

---

## 5. Perbandingan: Current vs Target

| Feature | Current Flutter | Memos (Original) | Status |
|---------|----------------|-------------------|--------|
| Timeline UI | ✅ | ✅ | Complete |
| Quick Capture | ✅ | ✅ | Complete |
| Markdown | ✅ | ✅ | Complete |
| Visibility | 🔲 Model only | ✅ | Partial |
| Tags | 🔲 | ✅ | Missing |
| Pin/Archive | 🔲 | ✅ | Missing |
| Auth/Users | 🔲 | ✅ | Missing |
| REST API | 🔲 | ✅ | Missing |
| SSE | 🔲 | ✅ | Missing |
| Attachments | 🔲 | ✅ | Missing |

---

## 6. Design Philosophy (Memos)

> **"Built for quick capture"**

1. **Speed over organization** - Tulis cepat, organisasi belakangan
2. **Timeline is king** - Cronologis feed adalah fokus utama
3. **Markdown first** - Semua content dalam markdown
4. **Minimal clicks** - Seminimal mungkin langkah untuk capture
5. **Own your data** - Self-hosted friendly, format portable

---

## 7. Dokumentasi API (Rencana)

Jika ingin mengimplementasi backend seperti memos original:

### Endpoints (REST API)
```
POST   /api/v1/memos           # Create memo
GET    /api/v1/memos           # List memos (timeline)
GET    /api/v1/memos/:id        # Get single memo
PATCH  /api/v1/memos/:id       # Update memo
DELETE /api/v1/memos/:id       # Delete memo

# Future:
GET    /api/v1/memos/:id/comments
POST   /api/v1/memos/:id/comments
GET    /api/v1/users/me
POST   /api/v1/auth/sessions   # Login
```

### Proto Schema (seperti memos original)
```protobuf
message Memo {
  string name = 1;          // "memos/{uid}"
  string content = 2;        // Markdown content
  Visibility visibility = 3;
  repeated string tags = 4;
  int64 create_time = 5;
  int64 update_time = 6;
}

enum Visibility {
  VISIBILITY_UNSPECIFIED = 0;
  PRIVATE = 1;
  PUBLIC = 2;
  PROTECTED = 3;
}
```

---

## 8. Referensi & Resources

- **Repository:** https://github.com/usememos/memos
- **Documentation:** https://usememos.com/docs
- **Live Demo:** https://demo.usememos.com
- **Discord:** https://discord.gg/tfPJa4UmAv
- **Architecture Docs:** https://usememos.com/docs/operations/architecture

---

**Catatan untuk AI:** 
- JANGAN tambah fitur kompleks (notebook, folder) - memos itu minimalis!
- LAKUKAN: fokus pada quick capture dan timeline
- PRIORITAS: visibility, tags, search sebelum fitur lainnya

---
Created: 2026-04-29
Based on: https://github.com/usememos/memos (v0.28.0)
