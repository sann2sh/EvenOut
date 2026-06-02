# EvenOut

EvenOut is a smart group expense management application designed to eliminate the friction of shared expenses. Targeted for eSewa users in Nepal, it handles expense logging, scanning, splitting, tracking, and settling debts—with gamification built in to encourage fast repayments.

## 🏗️ Architecture & Technology Stack

The project utilizes a strict monorepo architecture for synchronized models, types, and rapid deployment.

- **Mobile Frontend**: Flutter (Dart) with Riverpod, offline queuing (Isar/Hive), camera, qr_flutter, and speech_to_text.
- **Backend API**: Node.js + NestJS via REST endpoints, deployed on Render.
- **Database & BaaS**: Supabase (PostgreSQL, Row-Level Security, Auth, Storage) and Realtime WebSockets.
- **External APIs**: Google Cloud Vision / Anthropic API (OCR), Gemini API (Fast NLP), Firebase Cloud Messaging (FCM).

### Repository Structure
```
/evenout-monorepo
├── /backend-evenout  # Main monolithic API (Node.js/NestJS)
├── /frontend_evenout # Primary user application (Flutter)
└── /supabase         # Database schemas, RLS policies, and SQL Views
```

## ✨ Core Features

1. **The Ledger Engine**: Foundational layer tracking peer obligations using a flat PostgreSQL schema with real-time sync. Settling up triggers an eSewa deep link.
2. **Offline-First Action Queue**: Users can log expenses offline. A local queue caches requests and pushes to the backend upon network restoration.
3. **QR Group Creation**: Frictionless onboarding for table groups using dynamic QR codes and deep links.
4. **Intelligent OCR Bill Scanning**: Scans physical receipts and auto-populates structured split allocations via Cloud Vision API.
5. **Hands-Free Voice Payments**: Voice-to-text logging using LLM APIs to extract the payer, payee, and amount automatically.
6. **Context-Aware Notifications**: Quirky, gamified "Duolingo-style" push notifications to nudge users about pending debts.
7. **Gamified Splitting ("Chaos Roulette" & SplitScore)**: Features a high-stakes digital spin wheel for randomized splits and a credit score system to reward timely settlements.
8. **Greedy Debt Simplification**: A mathematical engine that minimizes the total number of transactions required to settle a group by bypassing intermediate debtors.

## 🛠️ Getting Started

### Backend Setup
- Navigate to `/backend-evenout`.
- Configure your `.env` variables for Supabase and APIs.
- Run `npm install` and `npm run start:dev`.

### Frontend Setup
- Navigate to `/frontend_evenout`.
- Run `flutter pub get`.
- Run `flutter run` on your preferred emulator or device.

---
*Built to make settling up seamless, fun, and fast.*
