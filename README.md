<h1 align="center">🛡️ SafeZone</h1>

<p align="center">
  <b>A community-driven public safety mobile application built with Flutter</b><br/>
  Report incidents, trigger SOS alerts, explore safety maps, and get AI-powered assistance — all in one place.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" />
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase" />
  <img src="https://img.shields.io/badge/Firebase-FCM-FFCA28?logo=firebase" />
  <img src="https://img.shields.io/badge/OpenAI-GPT--4o--mini-412991?logo=openai" />
  <img src="https://img.shields.io/badge/Google%20Maps-API-4285F4?logo=googlemaps" />
</p>

---

## 📖 Overview

**SafeZone** is a Flutter-based community safety platform that empowers users to report safety incidents, trigger emergency SOS alerts, and explore real-time danger zones on an interactive map. It connects citizens with emergency services and their trusted contacts instantly, while an AI chatbot provides safety guidance 24/7.

---

## ✨ Features

### 🔐 Authentication
- **Email & Password Sign Up / Login** — Secure authentication powered by Supabase Auth.
- **Password Reset via Email** — Users can reset their password through a magic link.
- **Session Persistence** — Users stay logged in across app restarts.
- **Profile Management** — Edit display name, phone number, emergency contact, profile picture, and vehicle info.
- **Account Deletion** — Users can delete their account with password re-authentication.

---

### 🚨 Emergency SOS (One-Tap Alert)
- **SOS Button** — A large, prominent panic button triggers an emergency flow instantly.
- **Live GPS Location** — Captures the user's precise GPS coordinates in real time.
- **SMS Alert** — Automatically sends a distress SMS with a Google Maps link to the user's registered emergency contact.
- **WhatsApp Alert** — Opens WhatsApp and sends the same location message to the emergency contact.
- **Push Notification (FCM)** — If the emergency contact is a registered SafeZone user, a Firebase Cloud Messaging push notification is delivered directly to their device.
- **In-App Alert Record** — The SOS event is logged in the Supabase `alerts` table for audit/history purposes.
- **15-Second Video Evidence** — Automatically records a 15-second video from the device camera during SOS activation and uploads it securely to Supabase Storage (`emergency` bucket), with metadata stored in the `emergency_details` table.
- **Quick Dial Buttons** — One-tap direct call buttons for Police (100), Ambulance (108), and Fire Brigade (101).

---

### 🗺️ Safety Map
- **Interactive Google Map** — Displays all community-reported and admin-approved complaints as map markers.
- **Real-Time Location** — Centers the map on the user's live GPS position.
- **Place Search** — Search any city or address using the Google Places Text Search API; the map animates to the result.
- **Reverse Geocoding** — Tap anywhere on the map and see the street/locality name using the Geocoding API.
- **Route Drawing** — Tap two points to draw a driving route between them using the Google Directions API with animated polylines.

---

### 📢 Complaint / Incident Reporting
- **Category Selection** — Choose from: Crime, Accident, Fire, Medical, Hazard, or Other.
- **Location Options** — Use current GPS location or manually pick a location from an interactive map.
- **Description & Proof** — Add a text description and optional proof link.
- **Photo/Video Upload** — Attach media from the gallery; uploaded to the Supabase `complaint_media` storage bucket.
- **Urgency Level** — Slider to mark urgency as Low, Medium, or High.
- **Complaint Status** — Submitted complaints go through a `pending → approved / declined` review process.

---

### 🤖 AI Safety Chatbot
- **GPT-4o-mini Powered** — Uses OpenAI's API to classify user messages and extract intent in JSON format.
- **Intent Detection** — Detects: `report_incident`, `report_infra_issue`, `check_area_safety`, `emergency_help`, `smalltalk`.
- **Report Confirmation Flow** — AI proposes an incident report and asks the user to `confirm` or `cancel` before saving to the database.
- **SOS Fast-Path** — Keywords like "SOS", "help", "emergency" bypass the API for instant local guidance with emergency numbers.
- **Supabase Integration** — Confirmed reports are saved to the `incidents` table in Supabase.
- **Accessible via FAB** — A floating action button throughout the app opens the chatbot screen.

---

### 🧑‍💼 Admin Dashboard
- **Complaint Review** — Admins can view all pending complaints with full details (user, category, description, urgency, media).
- **Approve / Decline** — Update complaint status with a single tap; approved complaints appear as map markers in the Safety Map.
- **Separate Entry Point** — `admin_dashboard.dart` can be run as a standalone module.

---

### ⚙️ Settings & Account Management
- **Edit Profile** — Update name, phone, profile picture, and vehicle information.
- **Change Email** — Update email via Supabase Auth.
- **Change Emergency Contact** — Update the phone number used for SOS alerts.
- **Notification Settings** — Toggle notification preferences.
- **Privacy Page** — App privacy policy display.
- **Invite Friends** — Share the app with others.
- **Logout** — Secure sign-out with session cleanup.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend Framework** | [Flutter](https://flutter.dev) (Dart 3.x) |
| **State Management** | Flutter `setState` (Widget-level) |
| **Authentication & Database** | [Supabase](https://supabase.com) (Auth + PostgreSQL + Storage) |
| **Push Notifications** | [Firebase Cloud Messaging (FCM)](https://firebase.google.com/docs/cloud-messaging) |
| **Maps & Navigation** | [Google Maps Flutter](https://pub.dev/packages/google_maps_flutter) |
| **Directions & Places** | [Google Directions API](https://developers.google.com/maps/documentation/directions) + [Google Places API](https://developers.google.com/maps/documentation/places) |
| **Geocoding** | [geocoding](https://pub.dev/packages/geocoding) |
| **Location** | [geolocator](https://pub.dev/packages/geolocator) |
| **AI Chatbot** | [OpenAI GPT-4o-mini](https://platform.openai.com/docs/models/gpt-4o-mini) |
| **SMS** | [another_telephony](https://pub.dev/packages/another_telephony) |
| **WhatsApp / URL Launcher** | [url_launcher](https://pub.dev/packages/url_launcher) |
| **HTTP Requests** | [dio](https://pub.dev/packages/dio) + [http](https://pub.dev/packages/http) |
| **Camera & Video** | [camera](https://pub.dev/packages/camera) |
| **Image Picker** | [image_picker](https://pub.dev/packages/image_picker) |
| **Permissions** | [permission_handler](https://pub.dev/packages/permission_handler) |
| **Environment Variables** | [flutter_dotenv](https://pub.dev/packages/flutter_dotenv) |
| **Fonts** | [google_fonts](https://pub.dev/packages/google_fonts) (Poppins) |
| **Logging** | [logger](https://pub.dev/packages/logger) |
| **File System** | [path_provider](https://pub.dev/packages/path_provider) + [path](https://pub.dev/packages/path) |

---

## 🔑 APIs Used

### 1. Supabase
- **Auth API** — Sign up, login, logout, password reset, email update, user deletion.
- **PostgreSQL (REST API)** — CRUD operations on `profiles`, `complaints`, `alerts`, `emergency_details`, `incidents` tables.
- **Storage API** — Upload/retrieve profile images (`profile-images`), complaint media (`complaint_media`), and emergency videos (`emergency`) buckets.

### 2. Firebase Cloud Messaging (FCM)
- **Endpoint:** `https://fcm.googleapis.com/fcm/send`
- **Used For:** Sending real-time push notifications to emergency contacts when an SOS is triggered.
- **Required Keys:** `FCM_SERVER_KEY` (legacy HTTP v1 key or Service Account for v2).

### 3. Google Maps Platform
| API | Purpose |
|---|---|
| **Maps SDK for Android/iOS** | Renders the interactive map |
| **Places API (Text Search)** | `GET /maps/api/place/textsearch/json?query=...&key=API_KEY` — Searches for a location by name |
| **Directions API** | `GET /maps/api/directions/json?origin=...&destination=...&mode=driving&key=API_KEY` — Draws route polylines |
| **Geocoding API** | Converts GPS coordinates to human-readable addresses (via `geocoding` package) |

### 4. OpenAI API
- **Endpoint:** `POST https://api.openai.com/v1/chat/completions`
- **Model:** `gpt-4o-mini`
- **Used For:** Intent extraction and automated reply generation in the AI chatbot.
- **Auth:** `Authorization: Bearer YOUR_OPENAI_API_KEY`

---

## 🗄️ Database Schema (Supabase / PostgreSQL)

### `profiles`
| Column | Type | Description |
|---|---|---|
| `id` | UUID (FK → auth.users) | User identifier |
| `display_name` | text | Full name |
| `phone` | text | Phone number |
| `emergency_contact` | text | Emergency contact phone |
| `profile_image_url` | text | Path or URL to profile image |
| `fcm_token` | text | Firebase device token |

### `complaints`
| Column | Type | Description |
|---|---|---|
| `id` | serial | Auto-increment ID |
| `user_id` | UUID | Who submitted the complaint |
| `category` | text | Crime / Accident / Fire / Medical / Hazard / Other |
| `description` | text | Complaint details |
| `urgency` | integer | 1 (Low) / 2 (Medium) / 3 (High) |
| `latitude` | float8 | GPS latitude |
| `longitude` | float8 | GPS longitude |
| `media_url` | text | Uploaded image/video link |
| `proof_link` | text | Optional external proof URL |
| `status` | text | `pending` / `approved` / `declined` |

### `alerts`
| Column | Type | Description |
|---|---|---|
| `id` | serial | Auto-increment ID |
| `sender_id` | UUID | Who triggered the SOS |
| `receiver_id` | UUID | The emergency contact's user ID |
| `message` | text | The alert message with GPS link |
| `timestamp` | timestamptz | When the alert was triggered |
| `seen` | boolean | Whether the receiver has seen it |

### `emergency_details`
| Column | Type | Description |
|---|---|---|
| `id` | serial | Auto-increment ID |
| `user_id` | UUID | Who triggered the SOS |
| `user_name` | text | Display name of the user |
| `latitude` | float8 | GPS latitude at time of SOS |
| `longitude` | float8 | GPS longitude at time of SOS |
| `video_path` | text | Path to the 15s emergency video in storage |

### `incidents` (Chatbot-reported)
| Column | Type | Description |
|---|---|---|
| `id` | UUID | Auto-generated |
| `type` | text | theft / harassment / assault / accident / etc. |
| `description` | text | Summary of the incident |
| `location_text` | text | Text description of location |
| `when_text` | text | When it happened (text) |
| `anonymous` | boolean | Defaults to `true` |
| `created_at` | timestamptz | Submission timestamp |

---

## ⚙️ Environment Variables

Create a file named `flutter.env` inside the `safezone/` directory with the following content:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

> ⚠️ **Never commit this file to version control.** It is listed in `.gitignore`.

Additionally, update these constants directly in the source files (or move them to `flutter.env` for better security):

| File | Constant | Value |
|---|---|---|
| `lib/features/map_page.dart` | `googleApiKey` | Your Google Maps/Places/Directions API Key |
| `lib/features/emergency_page.dart` | `fcmServerKey` | Your Firebase FCM Server Key |
| `lib/chatbot.dart` | `kOpenAiApiKey` | Your OpenAI API Key |
| `lib/chatbot.dart` | `kDefaultCity` | Your city name (for better AI context) |

---

## 🔧 How It Works

```
┌──────────────────────────────────────────────────────┐
│                    USER ACTION                       │
│  (Login / SOS / Report / Map Search / Chat)          │
└────────────────────────┬─────────────────────────────┘
                         │
            ┌────────────▼────────────┐
            │     Flutter App UI      │
            │  (Dart/Flutter Widgets) │
            └────────────┬────────────┘
          ┌──────────────┼──────────────┐
          │              │              │
   ┌──────▼───┐   ┌──────▼────┐  ┌─────▼──────┐
   │ Supabase │   │  Firebase │  │ Google APIs │
   │ Auth +   │   │   FCM     │  │ Maps/Places │
   │ Database │   │   Push    │  │ Directions  │
   │ Storage  │   └───────────┘  └────────────┘
   └──────────┘
          │
   ┌──────▼───────┐
   │  OpenAI API  │
   │ (Chatbot AI) │
   └──────────────┘
```

1. **User authenticates** via Supabase Auth → Session stored locally.
2. **On Home load**, the FCM token is saved to the `profiles` table for push targeting.
3. **SOS Trigger**: GPS captured → 15s video recorded → uploaded to Supabase Storage → SMS + WhatsApp sent → FCM push delivered → DB row inserted.
4. **Complaint Report**: User fills form → image uploaded to Storage → record inserted in `complaints` table with `status: pending`.
5. **Admin Review**: Admin opens dashboard → approves/declines complaints → approved ones appear as map markers.
6. **Safety Map**: On load, all `approved` complaints are fetched and plotted as markers on the Google Map.
7. **AI Chatbot**: User message → OpenAI GPT classifies intent → if report, user confirms → saved to `incidents` table.

---

## 🚀 How to Clone and Run Locally

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x or later)
- [Dart SDK](https://dart.dev/get-dart) (bundled with Flutter)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/) with Flutter extension
- A physical Android device or emulator (iOS simulator for Mac)
- A [Supabase](https://supabase.com) project set up
- A [Firebase](https://console.firebase.google.com) project with FCM enabled
- A [Google Cloud](https://console.cloud.google.com) project with Maps, Places, and Directions APIs enabled
- An [OpenAI](https://platform.openai.com) account with an API key

---

### Step 1: Clone the Repository

```bash
git clone https://github.com/sagarshettyy11/SafeZone.git
cd SafeZone/safezone
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Set Up Environment Variables

Create a `flutter.env` file in the `safezone/` folder:

```bash
# On Windows (PowerShell)
New-Item flutter.env

# On macOS/Linux
touch flutter.env
```

Add your credentials:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

### Step 4: Configure API Keys

Update the following files with your API Keys:

```dart
// lib/features/map_page.dart
const String googleApiKey = "YOUR_GOOGLE_MAPS_API_KEY";

// lib/features/emergency_page.dart
static const String fcmServerKey = "YOUR_FCM_SERVER_KEY";

// lib/chatbot.dart
const String kOpenAiApiKey = "YOUR_OPENAI_API_KEY";
const String kDefaultCity = "Your City"; // e.g., "Mangaluru"
```

### Step 5: Configure Firebase

1. Go to [Firebase Console](https://console.firebase.google.com) → Create a project.
2. Add an Android app with your package name (`com.example.safezone` or your custom package).
3. Download `google-services.json` and place it in `safezone/android/app/`.
4. Enable **Cloud Messaging** in the Firebase project settings.

### Step 6: Enable Google Maps for Android

In `safezone/android/app/src/main/AndroidManifest.xml`, add your key inside the `<application>` tag:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY" />
```

### Step 7: Set Up Supabase

1. Create these tables in your Supabase project SQL editor: `profiles`, `complaints`, `alerts`, `emergency_details`, `incidents` (schema in the Database Schema section above).
2. Create these Storage buckets: `profile-images`, `complaint_media`, `emergency`.
3. Set appropriate RLS (Row Level Security) policies for each table.

### Step 8: Run the App

```bash
# Check connected devices
flutter devices

# Run on Android
flutter run

# Run on a specific device
flutter run -d <device-id>
```

---

## 📂 Project Structure

```
SafeZone/
└── safezone/
    ├── lib/
    │   ├── main.dart                  # App entry point, Supabase init, routing
    │   ├── welcome_page.dart          # Welcome/landing screen
    │   ├── login_page.dart            # Login screen
    │   ├── create_account.dart        # Sign up screen
    │   ├── reset_password.dart        # Password reset screen
    │   ├── user_details.dart          # User details on sign up
    │   ├── admin_dashboard.dart       # Admin complaint review panel
    │   ├── chatbot.dart               # AI Safety Chatbot (GPT-4o-mini)
    │   ├── features/
    │   │   ├── home_page.dart         # Main navigation scaffold + dashboard
    │   │   ├── emergency_page.dart    # SOS button, quick dial, video recording
    │   │   ├── map_page.dart          # Google Maps with safety markers & routing
    │   │   ├── complaint_page.dart    # Complaint submission form
    │   │   ├── map_picker_page.dart   # In-map location picker for complaints
    │   │   ├── user_profile.dart      # User profile settings tab
    │   │   └── manage_reports.dart    # User's own reports view
    │   └── settings/
    │       ├── account_page.dart      # Account settings (email, phone, delete)
    │       ├── edit_profile.dart      # Edit profile details
    │       ├── help_page.dart         # Help & support
    │       ├── invite_friend.dart     # Invite friends
    │       ├── notification.dart      # Notification settings
    │       └── privacy_page.dart      # Privacy policy
    ├── assets/
    │   └── icon/                      # App icons & nav bar images
    ├── flutter.env                    # 🔒 Secret environment variables (not in git)
    ├── pubspec.yaml                   # Flutter dependencies
    └── android/
        └── app/
            └── google-services.json  # 🔒 Firebase config (not in git)
```

---

## 🔮 Future Enhancements

- [ ] **Real-Time Location Sharing** — Live GPS broadcast to emergency contacts during an SOS using Supabase Realtime.
- [ ] **Offline SOS Mode** — Trigger SMS-only SOS without internet connectivity.
- [ ] **Heat Map Visualization** — Display crime density heat maps based on complaint clusters on the Safety Map.
- [ ] **Community Safety Score** — Rate neighborhoods based on verified complaint history.
- [ ] **Multi-Language Support** — Add Kannada, Hindi, and other regional languages using Flutter's i18n.
- [ ] **In-App Alerts Feed** — A notification center showing live community alerts from nearby users.
- [ ] **Trusted Contacts Management** — Add/manage multiple emergency contacts with priority levels.
- [ ] **SOS History** — View past SOS events with timestamps, locations, and video evidence.
- [ ] **Voice-Activated SOS** — Trigger SOS via voice command without touching the phone.
- [ ] **Government API Integration** — Integrate with official police/fire APIs for verified incident cross-referencing.
- [ ] **iOS Full Support** — Ensure telephony/SMS features work natively on iOS.
- [ ] **FCM HTTP v2 API Migration** — Migrate from FCM legacy API to the newer HTTP v2 protocol using service account authentication.
- [ ] **Web Admin Panel** — A dedicated web dashboard for admins to manage complaints, users, and analytics.
- [ ] **Dark Mode** — Full dark theme support for better usability at night.

---

## 🤝 Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 📬 Contact

**Sagar Shetty**  
📧 sagarshettyy11@gmail.com  
🔗 [GitHub](https://github.com/sagarshettyy11)

---

<p align="center">Made with ❤️ to make communities safer</p>
