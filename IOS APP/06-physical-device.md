# Phase 6 — Physical iPhone (after Simulator works)

Deploy **household_expense** to a real iPhone. Requires a free or paid **Apple Developer** account.

---

## 6.1 Apple Developer account

1. Go to [https://developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple ID
3. Accept developer agreement (free tier allows device testing)

---

## 6.2 Bundle identifier

Already set to **`com.householdexpense.app`** (same as Android). Confirm in Xcode → **Runner** → **Signing & Capabilities**. Only change it if that ID is already taken on your Apple team.

---

## 6.3 Enable automatic signing

In Xcode → **Runner** → **Signing & Capabilities**:

1. Check **Automatically manage signing**
2. **Team:** your Apple ID team
3. Fix any provisioning errors Xcode shows

---

## 6.4 Trust the Mac on iPhone

1. Connect iPhone via USB (or enable wireless debugging in Xcode)
2. On iPhone: tap **Trust This Computer**
3. **Settings → Privacy & Security → Developer Mode** → ON (iOS 16+)
4. Reboot iPhone if prompted

---

## 6.5 Run on device from terminal

```bash
cd /Users/harshuuu/household_expense
flutter devices
```

Note your iPhone name or ID, then:

```bash
flutter run -d "Your iPhone Name"
```

First install may require unlocking the phone and confirming the developer app trust:

**Settings → General → VPN & Device Management → [Your Developer ID] → Trust**

---

## 6.6 Release / TestFlight (later)

Not required for local testing. When ready:

```bash
flutter build ipa
```

Upload via Xcode **Organizer** or **Transporter** app.

---

## Back to simulator docs

→ [05-testing-and-running.md](./05-testing-and-running.md)
