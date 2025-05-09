# iLaps

A modern, open-source macOS app for securely viewing Local Administrator Password Solution (LAPS) passwords for managed Macs. Built for IT admins and the community, iLaps Admin fetches LAPS passwords from Azure Key Vault and displays them in a beautiful, user-friendly interface.

---

## Features
- View all managed Macs and their compliance status
- Fetch and display the current LAPS admin password from Azure Key Vault
- Copy password to clipboard securely
- Modern SwiftUI interface with dark mode support
- No password rotation or account creation—designed for script/MDM-based LAPS workflows

---

## Screenshots
<img width="1012" alt="Screenshot 2025-05-09 at 12 00 45" src="https://github.com/user-attachments/assets/142d3f06-7506-4c6c-8d4a-34d104770859" />

<img width="1012" alt="Screenshot 2025-05-09 at 12 01 27" src="https://github.com/user-attachments/assets/609334ca-8b12-4280-bcf6-b4ae80f1eec4" />
<img width="1012" alt="Screenshot 2025-05-09 at 12 01 37" src="https://github.com/user-attachments/assets/960fed6c-2f57-445a-80ec-ee54e81435e1" />

---

## Requirements
- macOS
- Azure Key Vault (for password storage)
- Microsoft Intune or compatible MDM for device management
- LAPS admin account and password rotation handled by your MDM/scripts

---

## Installation
1. **Clone this repository:**
2. **Open `iLaps.xcodeproj` in Xcode**
3. **Build and run** on your Mac

---

## Usage
- Sign in with your Microsoft account
- View your managed Macs
- Select a device to view its LAPS password
- Click the copy icon to copy the password to your clipboard

---

## Contributing
Contributions are welcome! Please open issues or pull requests for bug fixes, features, or improvements.

---

