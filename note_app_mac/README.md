# Memos for Mac - Flutter Edition 📝

A beautiful, minimalist note-taking app inspired by [Memos](https://github.com/usememos/memos) (59.3k ⭐), built with Flutter and enhanced with **UI/UX Pro Max** design principles.

![Memos Logo](https://raw.githubusercontent.com/usememos/.github/refs/heads/main/assets/logo-rounded.png)

---

## ✨ Features

### Core Memos Features
- ✅ **Timeline-First UI** - Chronological feed like social media
- ✅ **Quick Capture** - Prominent input with expand/collapse animation
- ✅ **Markdown-Native** - Full markdown support with live preview
- ✅ **Minimal Organization** - No folders/notebooks, just write

### Advanced Features
- ✅ **Tags System** - Auto-extract tags from `#tag` in markdown
- ✅ **Pin Memos** - Pin important memos to top
- ✅ **Archive Memos** - Hide old memos but keep them stored
- ✅ **Visibility Settings** - Private/Public/Protected
- ✅ **Search Functionality** - Search in content and tags
- ✅ **Edit/Preview Toggle** - Switch between edit and preview modes
- ✅ **Delete Confirmation** - Safety dialog before deletion

### UI/UX Pro Max Features
- ✅ **Premium Theme** - Orange palette (#FF8C00) with sophisticated design
- ✅ **Dark Mode** - Full light/dark theme support (follows system)
- ✅ **Smooth Animations** - Expand/collapse, transitions, and micro-interactions
- ✅ **Modern Cards** - Rounded corners (16px), subtle borders, shadows
- ✅ **Floating Snackbars** - Success/error with icons and colors
- ✅ **Responsive Layout** - Consistent padding and spacing
- ✅ **Empty States** - Beautiful icons with gradient backgrounds
- ✅ **Bottom Navigation** - Timeline, Archive, Settings tabs

---

## 📁 Project Structure

```
lib/
├── main.dart                          # Entry point + theme setup
├── theme/
│   └── app_theme.dart               # Premium light/dark theme
├── models/
│   ├── memo.dart                    # Memo model (tags, pin, archive)
│   ├── attachment.dart               # Attachment model (images, files)
│   ├── comment.dart                 # Comment model
│   └── reaction.dart                # Reaction model (emoji)
├── database/
│   └── database_service.dart        # SQLite (macOS) + SharedPreferences (Web)
├── screens/
│   ├── main_screen.dart             # Bottom navigation wrapper
│   ├── timeline_screen.dart         # 🎯 Main timeline (Pro Max UI)
│   ├── archive_screen.dart          # Archived memos view
│   ├── settings_screen.dart        # Theme, stats, data management
│   └── memo_editor_screen.dart     # Editor with visibility + tags
└── widgets/
    └── quick_capture.dart          # Animated quick capture input
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
- **Title**: 28px, Weight 800, Letter-spacing -0.5
- **Body**: 14-16px, Height 1.5-1.6
- **Tags**: 12px, FontWeight 500

### Components
- **Cards**: BorderRadius 16px, Border 1px, Elevation 0
- **Buttons**: BorderRadius 12px, Padding horizontal 24
- **Inputs**: BorderRadius 12px, Filled background
- **Chips/Tags**: BorderRadius 8px, Primary color with opacity

---

## 🚀 How to Run

### Prerequisites
- Flutter SDK installed
- Xcode (for macOS) or Chrome/Brave (for Web)
- macOS: Xcode command line tools

### Run on Web (Brave/Chrome)
```bash
cd /Users/tentendigitalindonesia/Downloads/note_app_mac
flutter run -d chrome --release
```

Or access the built version at: **http://localhost:8080** (if server is running)

### Run on macOS
```bash
cd /Users/tentendigitalindonesia/Downloads/note_app_mac
flutter run -d macos --release
```

### Build for Web
```bash
flutter build web --release
cd build/web && python3 -m http.server 8080
```

---

## 📝 How to Use

### 1. **Quick Capture**
- Click the input at the top or tap "+" icon
- Write notes in Markdown
- Press "Capture" or Enter
- Tags auto-detected from `#tag`

### 2. **Timeline**
- Scroll to see all memos
- Pinned memos appear at top (orange pin icon)
- Tap memo to edit
- Tap 3-dots menu for Pin/Archive/Edit/Delete

### 3. **Edit Memo**
- Tap memo in timeline
- Toggle between Edit/Preview mode
- Set Visibility (Private/Public/Protected)
- Toggle Pin and Archive
- Save with save button

### 4. **Search**
- Tap search icon in appbar
- Type keywords
- Search automatically finds in content and tags

### 5. **Tags**
- Use `#tag` in markdown content
- Tags auto-detected and displayed on cards
- Click tag to filter (coming soon)

### 6. **Settings**
- Switch theme: Light/Dark/System
- View statistics (total, pinned, archived, tags)
- Clear all data (danger zone)

---

## 🔧 Technical Details

### Database
- **macOS**: SQLite via `sqflite_common_ffi`
- **Web**: SharedPreferences (localStorage)
- Auto-migration support (version 1 → 2 → 3)

### State Management
- Simple StatefulWidget + setState
- Direct calls to DatabaseService

### Packages
```yaml
dependencies:
  flutter_markdown: ^0.7.1    # Render markdown
  sqflite_common_ffi: ^2.3.0  # SQLite macOS
  shared_preferences: ^2.3.0    # Web storage
  intl: ^0.19.0               # Date formatting
  image_picker: ^1.1.2          # Pick images
  file_picker: ^8.0.0           # Pick files
  percent_indicator: ^4.2.3       # Progress indicators
  shimmer: ^3.0.0               # Loading effects
  flutter_staggered_animations: ^1.1.1
  animations: ^2.0.11             # Flutter animations
```

---

## 🎯 Memos Philosophy (Implemented)

> **"Built for quick capture"**

1. ✅ **Speed over organization** - Write fast, organize later
2. ✅ **Timeline is king** - Chronological feed is the main focus
3. ✅ **Markdown first** - All content in markdown
4. ✅ **Minimal clicks** - Minimum steps to capture
5. ✅ **Own your data** - Self-hosted friendly, portable format

---

## 📊 Comparison: Flutter vs Original Memos

| Feature | Flutter App | Original Memos | Status |
|---------|-------------|----------------|--------|
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
| Comments | 🔲 | ✅ | Future |
| Reactions | 🔲 | ✅ | Future |
| Webhooks | 🔲 | ✅ | Future |

---

## 🚧 Next Development (Optional)

### Phase 1: Backend (Multi-User)
- [ ] Go backend with Echo v5
- [ ] JWT authentication
- [ ] REST API (Connect RPC + gRPC)
- [ ] PostgreSQL support

### Phase 2: Advanced Features
- [ ] Attachments (upload images/files)
- [ ] Comments on memos
- [ ] Reactions (emoji)
- [ ] RSS feeds
- [ ] SSE for live updates

### Phase 3: Integrations
- [ ] Webhooks
- [ ] MCP Server (AI assistants)
- [ ] CLI client
- [ ] Mobile apps (iOS/Android)

---

## 📖 References

- **Repository**: https://github.com/usememos/memos
- **Documentation**: https://usememos.com/docs
- **Live Demo**: https://demo.usememos.com
- **Architecture**: https://usememos.com/docs/operations/architecture
- **UI/UX Pro Max**: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill

---

## 🎉 Status: COMPLETE (Phase 0)

**Memos for Mac** Flutter app with **UI/UX Pro Max** design is complete and ready to use!

### What's Working:
- ✅ Timeline with smooth UI
- ✅ Quick capture with animations
- ✅ Markdown editor + preview
- ✅ Tags, Pin, Archive
- ✅ Search functionality
- ✅ Dark/Light theme
- ✅ Premium design system
- ✅ Statistics & Settings
- ✅ Bottom navigation

### Try it Now! 🚀

```bash
cd /Users/tentendigitalindonesia/Downloads/note_app_mac
flutter run -d chrome
```

Or open: **http://localhost:8080**

---

Created: 2026-04-30  
Version: 2.0.0  
Status: ✅ Production Ready (Core Features)  
Design: UI/UX Pro Max 🎨
