Mobile Frontend: Flutter (Dart) with Riverpod, flutter_supabase, camera, qr_flutter, speech_to_text, and local storage Isar for offline queuing.



Frontend (Flutter): Build skeleton pages using AI/Figma plugins. Implement Google Login. Feature 4 (QR Groups): Generate QR codes with deep links (evenout://join-group?id=) and handle the incoming deep link to trigger the join API call. Feature 1 & 2 (Ledger & Offline Queue): Build the expense entry form. Tackling the offline-first action queue using local storage (Isar/Hive) is crucial here; generate UUIDs locally, save the payload, and use connectivity_plus to trigger a background worker that pushes to the NestJS API when online.


We wil have both light and dark themes