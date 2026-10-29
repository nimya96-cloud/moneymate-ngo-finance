# MoneyMate NGO - Flutter APK Build Guide

## 🚀 Step-by-Step: GitHub Actions വഴി APK ഉണ്ടാക്കുന്നത്

### Step 1: GitHub-ൽ Account ഉണ്ടോ? ഇല്ലെങ്കിൽ ഉണ്ടാക്കുക
👉 [https://github.com/signup](https://github.com/signup) - Free account

---

### Step 2: GitHub-ൽ Repository ഉണ്ടാക്കുക

1. Login → **"+"** button → **"New repository"**
2. Repository name: `moneymate-ngo`
3. **Private** ആക്കുക (NGO data secure ആക്കാൻ)
4. **Create repository** click ചെയ്യുക

---

### Step 3: Code Upload ചെയ്യുക

**Option A: GitHub Desktop App (ഏറ്റവും എളുപ്പം)**
1. [GitHub Desktop](https://desktop.github.com/) download ചെയ്ത് install ചെയ്യുക
2. File → Clone Repository → URL paste ചെയ്ത് clone ചെയ്യുക
3. ഈ folder-ലെ files മുഴുവൻ clone ചെയ്ത location-ലേക്ക് copy ചെയ്യുക
4. GitHub Desktop-ൽ "Commit to main" → "Push origin"

**Option B: Git command line (Git installed ആണെങ്കിൽ)**
```powershell
cd "C:\Users\LAPTOP\Downloads\ngo_finance_app-20261029T145949Z-1-001\ngo_finance_app"
git init
git add .
git commit -m "Initial MoneyMate NGO Flutter App"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/moneymate-ngo.git
git push -u origin main
```

---

### Step 4: APK Build തുടങ്ങുന്നതു കാണുക

1. GitHub-ൽ repository-ലേക്ക് പോകുക
2. **"Actions"** tab click ചെയ്യുക
3. **"Build Flutter APK"** workflow കാണും - automatically start ആകും!
4. Build complete ആകാൻ **5-8 minutes** കാത്തിരിക്കുക ✅

---

### Step 5: APK Download ചെയ്യുക

1. Actions → Build run click ചെയ്യുക
2. Page-ന്റെ bottom-ൽ **"Artifacts"** section കാണും
3. **"MoneyMate-NGO-APK"** click ചെയ്ത് download ചെയ്യുക
4. ZIP file unzip ചെയ്ത് `app-release.apk` കിട്ടും

---

### Step 6: ഫോണിൽ Install ചെയ്യുക

1. APK file WhatsApp/Telegram/USB/Email വഴി ഫോണിലേക്ക് അയക്കുക
2. ഫോണിൽ: **Settings → Security → Unknown Sources** enable ചെയ്യുക
   (Android 8+: Settings → Apps → Special App Access → Install Unknown Apps → Files/Chrome → Allow)
3. APK file open ചെയ്ത് **Install** tap ചെയ്യുക
4. **MoneyMate NGO** icon home screen-ൽ വരും! 🎉

---

### Step 7: Backend Configure ചെയ്യുക

App open ചെയ്ത back-ൽ **⚙️ Settings** icon tap ചെയ്ത് backend URL set ചെയ്യുക:

**Local Network-ലാണ് backend run ആകുന്നതെങ്കിൽ:**
```
http://192.168.1.XXX:8000
```
(XXX = നിങ്ങളുടെ PC-യുടെ local IP address)

**Render.com-ൽ deploy ചെയ്തിട്ടുണ്ടെങ്കിൽ:**
```
https://your-app-name.onrender.com
```

---

## 👥 Default Login Credentials

| Staff Member | Phone | PIN |
|--------------|-------|-----|
| Rahul Nair (CSA Coordinator) | 9846011111 | 123456 |
| Priya Menon (CSA Case Worker) | 9846022222 | 123456 |
| Anand Kumar (CNCP Coordinator) | 9846033333 | 123456 |
| Deepa Varghese (CNCP Case Worker) | 9846044444 | 123456 |

---

## 🏗️ Project Structure

```
ngo_finance_app/
├── .github/
│   └── workflows/
│       └── build-apk.yml      ← GitHub Actions CI/CD (APK build)
├── flutter_app/               ← Flutter Android App Source Code
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/
│   │   ├── services/
│   │   ├── screens/
│   │   └── widgets/
│   ├── android/               ← Android native config
│   └── pubspec.yaml
├── app.py                     ← Python FastAPI Backend
├── static/index.html          ← Web version
└── ngo_data.json              ← Local data store
```

---

## 🔄 APK Update ചെയ്യാൻ

Code-ൽ changes ചെയ്ത് GitHub-ലേക്ക് push ചെയ്ത് Actions tab-ൽ നിന്ന് new APK download ചെയ്യുക. Old APK uninstall ചെയ്ത് new one install ചെയ്യണം.
