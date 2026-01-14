# Smartsheets Offline Capabilities

A native iOS and iPadOS SwiftUI app developed for internal use at Norwegian Cruise Line (NCL). This tool connects with the Smartsheet API to allow offline access, editing, and conflict resolution of spreadsheet data, for usage in low-connectivity environments.

## ✨ Features

- ✅ OAuth 2.0 authentication with Smartsheet
- ✅ View and interact with Smartsheet spreadsheets via native UI
- ✅ Offline editing with sync when online
- ✅ Conflict resolution UI for managing data clashes
- ✅ Nested comment threads with indentation
- ✅ MVVM architecture with Dependency Injection
- ✅ Unit tested core logic

## 📦 Tech Stack

- Swift 5, SwiftUI, Combine
- Smartsheet REST API (OAuth 2.0)
- MVVM + Dependency Injection
- SpreadsheetView (via Swift Package Manager)

## 🛠️ Installation

> ⚠️ This project is for internal use and requires valid Smartsheet credentials and access tokens.

1. Clone the repository:
```bash
git clone https://github.com/nclcorp/SmartsheetsOfflineCapabilities.git
```

2. Open the project:
```bash
open SmartsheetsOfflineCapabilities.xcodeproj
```

3. Dependencies are managed via **Swift Package Manager**, including:

- [`SpreadsheetView`](https://github.com/kishikawakatsumi/SpreadsheetView)

4. Set up your OAuth credentials for Smartsheet in the appropriate environment files or secrets manager.

## ▶️ Screenshots

<img width="1563" height="923" alt="Screenshot 2025-09-25 at 13 50 15" src="https://github.com/user-attachments/assets/50a417ce-6356-432f-9953-60a4fc4e9a5e" />
<img width="1573" height="926" alt="Screenshot 2025-10-01 at 15 36 31" src="https://github.com/user-attachments/assets/4ef883a7-6822-4e58-83cf-e868571983ec" />
<img width="1563" height="923" alt="Screenshot 2025-09-25 at 13 23 13" src="https://github.com/user-attachments/assets/65400e3e-8039-417d-acb6-17cdbe39305d" />
<img width="1563" height="923" alt="Screenshot 2025-09-25 at 13 22 56" src="https://github.com/user-attachments/assets/fbb67f24-dbe6-465a-b03d-2399a58eea63" />
<img width="1563" height="923" alt="Screenshot 2025-09-25 at 13 22 48" src="https://github.com/user-attachments/assets/cea3bdcf-5ec0-4a4a-9c8d-fa7145cff085" />
<img width="1563" height="923" alt="Screenshot 2025-09-25 at 13 22 37" src="https://github.com/user-attachments/assets/87a666f7-240d-48ab-9ec8-0f1f56fcc863" />
<img width="1563" height="923" alt="Screenshot 2025-09-25 at 13 23 27" src="https://github.com/user-attachments/assets/fadce0ed-07c0-48d1-ba63-ea5fcb99081e" />
<img width="1563" height="923" alt="Screenshot 2025-09-25 at 13 46 26" src="https://github.com/user-attachments/assets/bb3a2ea1-b47a-4f79-8081-f5ecfa6d45bc" />
<img width="1563" height="923" alt="Screenshot 2025-09-25 at 13 47 53" src="https://github.com/user-attachments/assets/8e6021c2-83ff-4713-8310-d27fd9d05947" />
<img width="1563" height="923" alt="Screenshot 2025-09-25 at 13 27 12" src="https://github.com/user-attachments/assets/325c3a5b-aec2-41cd-a78f-fdddb01b75f0" />
<img width="1563" height="923" alt="Screenshot 2025-09-25 at 13 27 18" src="https://github.com/user-attachments/assets/031c54ae-6f31-4802-b944-d6ad3a3138b9" />

---

> Internal tool built by the NCL iOS team. Not intended for public distribution
