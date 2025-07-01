# 📱 PSV Frontend – Flutter App

This is the Flutter-based frontend for the PSV Sacco Management App. The app allows passengers, vehicle owners, and sacco admins to interact with the system — including registering vehicles, viewing sacco performance, and submitting reviews.

> ⚠️ **This app depends on the Django REST API backend**:  
> Please ensure the backend is running and accessible. [Backend Repo](https://github.com/Muchire/SeniorProject)

---

## 📦 Tech Stack

- Flutter 3.x (Dart)
- Google Sign-In
- REST API integration (Django backend)
- Material UI Components
- State management (e.g. Provider/Riverpod – if used)

---

## 🔗 Backend Dependency

This app **requires a running Django REST API**, available here:  
👉 [`https://github.com/Muchire/SeniorProject`](https://github.com/Muchire/SeniorProject)

The backend is responsible for:
- Google token verification
- Managing Sacco, vehicle, and review data
- Returning sacco financial performance metrics

> 🔴 If the backend is not running or connected properly, this app will **not function correctly**.

### 📍 How to Link the Frontend to the Backend

Edit the file `lib/services/api_service.dart`:


const String baseUrl = "http://<your-local-ip>:8000/api/";
Replace <your-local-ip> with:

127.0.0.1 if running in browser

Your LAN IP (e.g., 192.168.1.42) when testing on mobile device

🚀 Getting Started
✅ Prerequisites
Flutter SDK

Android Studio or VS Code

Firebase Project

Git

🧰 Setup
bash
Copy
Edit
git clone https://github.com/Muchire/psv_frontend.git
cd psv_frontend
flutter pub get
🔐 Firebase Setup
Go to Firebase Console

Create a new project

Enable Google Sign-In under Authentication

Download google-services.json

Place it inside the android/app/ directory

📱 Running the App
For Android/iOS:
bash
Copy
Edit
flutter run
For Web (port 8080):
bash
Copy
Edit
flutter run -d chrome --web-port=8080
🧩 Features
🔐 Google login 

🚗 Vehicle registration

🚌 Sacco discovery by route

💬 Sacco reviews and ratings

📊 Sacco financial performance display

👥 Role-based UI:

Passenger

Vehicle Owner

Sacco Admin

