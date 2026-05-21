# VoxNote — App Store Submission Checklist

## App Store Connect Setup

### 1. Create the App Record
- [ ] Log in to [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Click + → New App
- [ ] Platform: iOS
- [ ] Name: **VoxNote - AI Voice Transcription**
- [ ] Primary Language: English
- [ ] Bundle ID: **com.voxnote.app** (register in Certificates, IDs & Profiles first)
- [ ] SKU: **VOXNOTE001**

### 2. App Information Tab
- [ ] Subtitle: **Record. Transcribe. Summarize.**
- [ ] Category: **Utilities** (primary) / **Productivity** (secondary)
- [ ] Content Rights: No third-party content
- [ ] Age Rating: **4+** (complete questionnaire — all NONE)

### 3. Pricing and Availability
- [ ] Price: **Free**
- [ ] Availability: All territories (or Japan + US at minimum)
- [ ] Pre-Orders: Off

### 4. In-App Purchases
Go to App Store Connect → Your App → In-App Purchases → (+)

**Product 1 — Monthly Subscription**
- [ ] Type: Auto-Renewable Subscription
- [ ] Reference Name: VoxNote Pro Monthly
- [ ] Product ID: `com.voxnote.app.pro.monthly`
- [ ] Subscription Group: Create new → "VoxNote Pro"
- [ ] Duration: 1 Month
- [ ] Price: Tier 4 ($3.99 / ¥600)
- [ ] Free Trial: 3 days
- [ ] Localization EN: Display Name "VoxNote Pro Monthly", Description as in metadata.json
- [ ] Localization JA: 「VoxNote Pro 月額プラン」

**Product 2 — Annual Subscription**
- [ ] Type: Auto-Renewable Subscription
- [ ] Reference Name: VoxNote Pro Annual
- [ ] Product ID: `com.voxnote.app.pro.annual`
- [ ] Subscription Group: VoxNote Pro (same group as monthly)
- [ ] Duration: 1 Year
- [ ] Price: Tier 13 ($24.99 / ¥3,600)
- [ ] Free Trial: 7 days
- [ ] Mark as: Featured plan

**Product 3 — Lifetime**
- [ ] Type: Non-Consumable
- [ ] Reference Name: VoxNote Lifetime
- [ ] Product ID: `com.voxnote.app.lifetime`
- [ ] Price: Tier 20 ($29.99 / ¥4,500)

### 5. Version Information (1.0.0)
- [ ] What's New: paste `whats_new_en.txt` (EN) and `whats_new_ja.txt` (JA)
- [ ] Description EN: paste `description_en.txt`
- [ ] Description JA: paste `description_ja.txt`
- [ ] Keywords EN: `voice memo,transcription,voice recorder,ai notes,speech to text,meeting notes,dictation,audio recorder`
- [ ] Keywords JA: `音声メモ,文字起こし,ボイスレコーダー,AIノート,議事録,授業録音,音声認識,ディクテーション`
- [ ] Promotional Text EN: paste from metadata.json
- [ ] Support URL: https://github.com/Koki-coder-crypto/LynQ_backend/issues
- [ ] Privacy Policy URL: https://github.com/Koki-coder-crypto/LynQ_backend/blob/master/app_store/privacy_policy.html

### 6. App Privacy
- [ ] Data Collection: No (VoxNote does not collect or share user data)
- [ ] Privacy Nutrition Label: all unchecked

### 7. Review Information
- [ ] First Name: Koki
- [ ] Last Name: Developer
- [ ] Email: kouki_1203@icloud.com
- [ ] Demo Account: Not required
- [ ] Notes: paste `review_notes.txt`

## Xcode Setup

### 8. Xcode Project
- [ ] Create new Xcode project: App / SwiftUI / Swift
- [ ] Bundle Identifier: `com.voxnote.app`
- [ ] Deployment Target: iOS 17.0
- [ ] Add all Swift files from `ios_app/` to the project
- [ ] Add `Info.plist` entries (or configure in target settings):
  - NSMicrophoneUsageDescription
  - NSSpeechRecognitionUsageDescription
  - ANTHROPIC_API_KEY (add to build settings / xcconfig)
- [ ] Sign with your Apple Developer account (Koki)

### 9. Capabilities (Signing & Capabilities tab)
- [ ] In-App Purchase — ON
- [ ] (StoreKit 2 is used automatically)

### 10. App Icon
- [ ] Create 1024×1024 PNG app icon (purple waveform on white/dark background)
- [ ] Add to Assets.xcassets → AppIcon

### 11. Screenshots (required)
- [ ] 6.7" iPhone (iPhone 15 Pro Max): minimum 3 screenshots
  1. Record screen (recording in progress)
  2. Memo detail (AI summary shown)
  3. Memo list (multiple memos)
- [ ] Optional: 12.9" iPad

### 12. Build & Upload
- [ ] Product → Archive
- [ ] Distribute App → App Store Connect
- [ ] Upload and wait for processing (~10 min)
- [ ] Select build in App Store Connect → Version Information

### 13. Submit for Review
- [ ] All sections show green checkmarks
- [ ] Click "Submit for Review"
- [ ] Review time: typically 24–72 hours

## Post-Approval
- [ ] Set release: Automatic or Manual
- [ ] Monitor for any reviewer follow-up emails
