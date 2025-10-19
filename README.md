<p align="center">
  <img src="assets/images/logo.jpg" alt="Progdia Logo" width="180"/>
</p>

<h1 align="center">🦥 Progdia — Gamified Habit Tracker</h1>

<p align="center">
  Turn your daily routines into progress — with your sloth companion by your side.
  <br>
  Built using <b>Flutter</b> and <b>Firebase</b> • Designed by <b>Eyad Khedr</b>
</p>

---

## 🌱 Vision

**Progdia** reimagines productivity for a generation raised on interactivity.  
Instead of boring checklists, users build consistency through play —  
earning coins, customizing avatars, and competing with friends to create positive habits that actually stick.

It’s not just a task manager — it’s motivation you *enjoy* using.

---

## 🚀 Features

- ✅ **Daily Task System** – Build and complete personal habits with ease.  
- 💰 **Gamified Rewards** – Earn coins to buy clothes and accessories for your sloth avatar.  
- 🔐 **Firebase Authentication** – Sign in securely via Google or email.  
- ☁️ **Firestore Sync** – Real-time habit and character data across devices.  
- 👥 **Friends System** – See your friends’ avatars and motivate each other.  
- 🔥 **Streak Calendar** – Visualize your consistency and progress.

---

## 🧩 Tech Stack

| Layer | Tools / Frameworks |
|-------|--------------------|
| **Frontend** | Flutter (Dart) |
| **Backend** | Firebase (Auth, Firestore) |
| **State Management** | Provider |
| **AI Service** | Gemini API |
| **UI Assets** | Custom PNG & SVG Illustrations |

---

## 📁 Project Structure

```

launchx_app/
│
├── lib/
│   ├── main.dart                # App entry point
│   ├── firebase_options.dart    # Firebase configuration
│   ├── theme.dart               # Global app theme
│   ├── providers/               # Habit & friends logic
│   ├── services/                # Gemini and Firebase services
│   ├── screens/                 # UI screens (tasks, profile, shop, etc.)
│   └── widgets/                 # Reusable UI components
│
├── assets/
│   └── images/                  # Character outfits, hats, ties, etc.
│
├── pubspec.yaml                 # Dependencies and assets
├── firebase.json                # Firebase config
└── README.md

````

---

## ⚙️ Setup Instructions

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/eyadkhedr/progdia-app.git
cd progdia-app
````

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

### 3️⃣ Set Up Firebase

* Add your **`google-services.json`** (Android) and **`GoogleService-Info.plist`** (iOS) files.
* Replace the existing Firebase configuration if needed.

### 4️⃣ Run the App

```bash
flutter run
```

---

## 🧠 Developer

**👤 Eyad Khedr** — Obour STEM School, Egypt
Email: [eyada0103@gmail.com](mailto:eyada0103@gmail.com)

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).