<div align="center">

# 📚 My Dashboard
### Engineering Student Companion App

![Version](https://img.shields.io/badge/version-1.4.0-667EEA?style=for-the-badge)
![Platform](https://img.shields.io/badge/platform-Android-764BA2?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.19.6-02569B?style=for-the-badge&logo=flutter)

*An all-in-one productivity app built for engineering students.*

</div>

---

## ✨ Features Overview

### 📊 GPA Calculator
Track your academic performance with a fully dynamic GPA calculator.
- Add courses with credit hours and letter grades
- Real-time GPA calculation (4.0 scale)
- Displays total credit hours alongside cumulative GPA
- Delete or update courses anytime

---

### 📋 Assignments & Tasks
Never miss a deadline with smart assignment tracking.
- **Three filter tabs**: In-Progress (due within 3 days), Incoming (due later), Done
- **Sort options**: by Due Date, Course name, or Priority level
- **Priority system**: Fully customisable emoji-based priority labels (Low 🟢, Medium 🔵, High 🟠, Urgent 🔴)
- **Assignment details**: Rich text field to describe what needs to be done
- **Reminders**: Schedule push notifications for any assignment
- **Alarms**: Set a device alarm directly from the app
- Overdue tasks highlighted in red
- Mark complete with a single tap

---

### ⏱️ Study Timer
Boost focus with a Pomodoro-style study timer.
- **Presets**: Pomodoro (25 min), Short Break (5 min), Long Break (15 min), Deep Focus (50 min)
- Circular progress ring with smooth animation
- Session counter tracks daily study sessions
- Push notification when a session ends (works even if phone is locked)
- Timer persists across tab switches

---

### 📅 Schedule
Organise your class timetable with two powerful views.
- **List view**: Day-by-day vertical layout with colour-coded headers
- **Table view**: Horizontal grid showing all days side by side
- Add classes with name, day, time (AM/PM), and room/location
- Toggle between views with a single button in the top bar
- All times displayed in 12-hour AM/PM format

---

### 📚 Library
A unified knowledge base replacing separate Notes and Formulas screens.

#### Section Tiles
- Grid of colour-coded tiles — each tile is a section (e.g. Formulas 📐, Notes 📝, Email Addresses 📧)
- Tap **+** to create custom sections with a chosen emoji and title
- Long-press a tile to **rename** or **delete** it (with all its contents)
- Item count shown on each tile

#### Notes (inside any non-formula section)
- Add notes with a **title** and **text content**
- Attach **photos** (camera or gallery) and **PDFs** to any note
- Attachments are stored privately inside the app — deleting the original source file does not affect them
- Image thumbnails previewed directly on the note card
- Tap any attachment to open it with the device's default viewer
- Copy text, edit, or delete notes at any time

#### Formulas (inside the Formulas section)
- 31 pre-loaded engineering formulas across 6 categories:
  - ⚡ Electricity — Ohm's Law, Power, Capacitance, Electric Field, Series/Parallel resistors
  - 🚀 Motion — Velocity, Displacement, Newton's 2nd Law, Momentum, Centripetal Force
  - 💡 Energy — Kinetic/Potential Energy, Work, Power, Efficiency
  - 💧 Fluids — Pressure, Fluid Pressure, Continuity, Bernoulli's, Buoyancy
  - 🔧 Materials — Young's Modulus, Stress, Strain, Thermal Expansion
  - 🔥 Thermodynamics — Heat Transfer, Ideal Gas Law, 1st Law, Carnot, Conduction
- Search formulas by name, expression, or description
- Filter by category using chips
- Add, edit, and delete custom formulas
- Manage formula categories (add/remove with custom emoji)
- Reset to defaults at any time

---

### ⚙️ Settings

#### 🎨 Appearance
- **Dark / Light mode** toggle with persistence across restarts

#### 💾 Data Backup
- **Selective export**: Choose which sections to include using checkboxes
  - GPA & Courses, Assignments, Schedule, Library & Notes, Formulas, Priority Labels
- Export as a JSON file (share via any app) or copy to clipboard
- **Selective import**: Choose which sections to restore from a JSON backup
- Confirmation dialog shows exactly what will be overwritten before proceeding

#### 🖼️ Media Backup
- **Export Photos & PDFs**: Bundles all note attachments into a single `.zip` file and shares it via any app (Google Drive, WhatsApp, email, etc.)
- **Import Media Bundle**: Pick a `.zip` file to restore attachments back into the app's private storage
- File names are preserved inside the zip for easy identification

#### ⚠️ Danger Zone
- **Clear All Data**: Wipes all app data and resets to factory defaults (with confirmation)

---

## 🔒 Remote Maintenance Mode

The app includes a remote switch that allows the developer to take it offline for maintenance from anywhere in the world — no app update required.

**How it works:**
- Every time the app opens while the device is connected to the internet, it silently fetches this `README.md` file from GitHub
- If a specific control word is detected in the file, the app displays a full-screen maintenance notice instead of loading normally
- If there is no internet connection, the app opens as usual (offline users are never blocked)
- A **Try Again** button allows users to retry once maintenance is over

This mechanism requires no backend server and works purely through GitHub.

---

## 📲 Installation

### From GitHub Releases (Recommended)
1. Go to the [Releases page](../../releases)
2. Download the latest `dashboard-v*.apk` file
3. On your Android phone, open the downloaded file
4. Tap **Install** (first time) or **Update** (if already installed — your data is preserved)
5. If prompted, allow installation from unknown sources in your device settings

> Each release uses the same App ID (`com.bodybth.mydashboard`) so every new APK installs as an update over the previous version — no need to uninstall.

### From Source
```bash
git clone https://github.com/bodybth/MyDashboardFlutter.git
cd MyDashboardFlutter
flutter pub get
flutter run
```

**Requirements:** Flutter 3.19.6+, Java 17, Android SDK 33+

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.19.6 (Dart) |
| State management | Provider |
| Local storage | SharedPreferences |
| Notifications | flutter_local_notifications |
| Charts | fl_chart |
| File sharing | share_plus |
| File picking | file_picker |
| Image picking | image_picker |
| File opening | open_filex |
| ZIP compression | archive |
| HTTP | http |
| Path utilities | path, path_provider |

---

## 📁 Project Structure

```
lib/
├── main.dart                   # App entry, splash, maintenance screen
├── models/
│   └── models.dart             # Data models (Course, Assignment, Note, etc.)
├── services/
│   ├── storage_service.dart    # All CRUD + export/import logic
│   ├── theme_service.dart      # Dark/light mode persistence
│   ├── notification_service.dart
│   └── lock_service.dart       # Remote maintenance check
└── screens/
    ├── gpa_screen.dart
    ├── assignments_screen.dart
    ├── timer_screen.dart
    ├── schedule_screen.dart
    ├── library_screen.dart     # Notes + Formulas unified
    ├── settings_screen.dart    # Backup, media, theme
    └── widgets.dart            # Shared UI components
```

---

## 🔄 CI/CD

GitHub Actions automatically builds and publishes a new APK on every push to `main`:

- Sets `versionCode` to the GitHub run number (ensures each build is higher than the last)
- Sets `versionName` to `1.x.{run_number}`
- Builds a release APK with `--no-tree-shake-icons`
- Creates a GitHub Release with the APK attached and installation instructions

---

## 📄 License

This project is for personal use. All rights reserved © 2025.

---

<div align="center">
  <sub>Built with ❤️ for engineering students</sub>
</div>
