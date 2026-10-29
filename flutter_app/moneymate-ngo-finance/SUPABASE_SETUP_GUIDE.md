# Supabase Free Tier Setup & Configuration Guide

This guide walks you through setting up the free Supabase PostgreSQL database, Storage bucket, and Row Level Security for the NGO Finance Mobile Application.

---

## 1. Create a Free Supabase Account & Project

1. Go to [https://supabase.com](https://supabase.com) and click **Start your project** (Free).
2. Create a new organization and project:
   - **Name:** `MoneyMate-NGO-Finance`
   - **Database Password:** (Choose a secure password and save it)
   - **Region:** `Central India (Mumbai)` or closest region for low latency.
   - **Pricing Plan:** Free tier (includes 500 MB DB, 1 GB file storage, unlimited API calls).

---

## 2. Execute SQL Schema & Database Rules

1. In your Supabase dashboard, click on the **SQL Editor** icon in the left menu.
2. Click **New query**.
3. Copy the entire contents of `supabase_schema.sql` located in this project directory.
4. Paste it into the SQL Editor and click **Run** (Ctrl + Enter).
5. Verify that the tables are created:
   - `staff_profiles` (5 default team members pre-populated)
   - `categories` (Income, Common Expense, Field Work categories)
   - `transactions` (with soft delete and audit trigger)
   - `settlements` (monthly salary + field expenses)
   - `dual_approvals` (OTP verification table)
   - `notifications` (broadcast system)
   - `audit_logs` (immutable trail)
   - `transaction_documents` (metadata with compressed sizes)

---

## 3. Create Storage Bucket for Compressed Bills & Receipts

1. Go to **Storage** in the left menu.
2. Click **New bucket**:
   - **Bucket Name:** `transaction-receipts`
   - **Public bucket:** OFF (Keep Private for NGO financial privacy)
3. Under bucket policies, add the policy allowing authenticated users to upload and view receipts.

---

## 4. Connect with the Application

1. Go to **Project Settings** -> **API**.
2. Copy:
   - **Project URL** (e.g. `https://xyzcompany.supabase.co`)
   - **anon / public key** (e.g. `eyJhbGciOi...`)
3. Create a `.env` file in the project folder:
   ```env
   SUPABASE_URL=https://your-project-id.supabase.co
   SUPABASE_KEY=your-anon-key-here
   ```
4. Now both the FastAPI backend and the Flutter mobile app will automatically talk to your live Supabase cloud database!
