# Free Render Deployment Guide (Python FastAPI Backend)

This guide shows how to deploy the NGO Finance App backend onto Render's free tier.

---

## 1. Push Code to GitHub

1. Create a repository on GitHub named `ngo-finance-manager`.
2. Push this project folder (`ngo_finance_app`) to the repository:
   ```bash
   git init
   git add .
   git commit -m "Initial commit of NGO Finance Mobile App"
   git remote add origin https://github.com/your-username/ngo-finance-manager.git
   git push -u origin main
   ```

---

## 2. Deploy on Render (Free Web Service)

1. Go to [https://render.com](https://render.com) and create a free account.
2. Click **New +** -> **Web Service**.
3. Select your GitHub repository `ngo-finance-manager`.
4. Render will automatically detect the settings from `render.yaml` or you can enter:
   - **Environment:** `Python 3`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn app:app --host 0.0.0.0 --port $PORT`
   - **Instance Type:** `Free`
5. Under **Environment Variables**, add:
   - `SUPABASE_URL`: `https://your-project.supabase.co`
   - `SUPABASE_KEY`: `your-supabase-anon-key`
6. Click **Deploy Web Service**.
7. In ~2 minutes, your web application will be live at a URL like:
   `https://ngo-finance-manager.onrender.com`

---

## 3. Use as Mobile App (PWA)

1. Open `https://ngo-finance-manager.onrender.com` in Google Chrome or Safari on your Android or iOS mobile phone.
2. Tap the browser menu (3 dots) and select **"Add to Home screen"** or **"Install App"**.
3. An app icon named **"MoneyMate NGO"** will appear on your mobile home screen, launching full-screen without browser bars, just like a native mobile app!
