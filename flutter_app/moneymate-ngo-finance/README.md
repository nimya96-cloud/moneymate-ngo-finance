# MoneyMate NGO Finance - CSA & CNCP Multi-Project System

A collaborative, mobile-first financial and field expense management application designed specifically for **CSA** (Child Support & Care Action) and **CNCP** (Children in Need of Care & Protection) projects.

---

## 🌟 Key Features Built Exactly to Requirements

### 1. Dual Projects Tracking: CSA & CNCP
- **Separate & Consolidated Fund Accounts**:
  - Track grant income inflows, common office expenses, and staff field claims separately for **CSA Project** and **CNCP Project**.
  - Dashboard displays individual project cards (Income, Outflow, Net Balance) as well as the **Consolidated Total**.
  - Filter transactions by project or view all together.

### 2. 4 Active Staff Roles
The system is built around the 4 core staff positions:
1. **CSA Coordinator** (e.g. Rahul Nair - `9846011111`)
2. **CSA Case Worker** (e.g. Priya Menon - `9846022222`)
3. **CNCP Coordinator** (e.g. Anand Kumar - `9846033333`)
4. **CNCP Case Worker** (e.g. Deepa Varghese - `9846044444`)

### 3. WhatsApp OTP Registration with Peer Approval Before Login
- When a new staff member registers:
  1. Enters Name, WhatsApp Phone, Project, Designation, and sets a 6-digit PIN.
  2. Receives a 6-digit OTP via direct WhatsApp link (`wa.me/91...`).
  3. Enters the OTP to verify their phone.
  4. The account enters `PENDING_APPROVAL` status. **Login is blocked until an existing active staff member approves it with their PIN!**

### 4. Staff Relieving / Deactivation with Peer Approval
- When a staff member leaves or is relieved:
  - Any active user can click **"Relieve Staff"** and enter a reason.
  - A 6-digit Dual Approval OTP request is generated.
  - Another staff member must approve the request with their PIN to deactivate the account (`RELIEVED` status), permanently disabling login.

### 5. Individual Staff Ledgers (Date Range & PDF Statement)
- Each staff member has their own **Field TA, Food, and Salary Ledger**:
  - Filter by Staff Member and **Date Range** (`From Date` - `To Date`).
  - Itemized table with TA Claims (Dr), Salary Accruals, and Disbursed Payouts (Cr).
  - Shows Net Outstanding Carry-Forward Due.
  - **One-Click Print / Save as PDF**: Formats into a professional official statement with NGO header, project tags, and signature space.
  - Everyone can view each other's ledger for full team transparency.

### 6. 1st of Month Salary Settlement (With Variable / Partial Payout & Carry-Forward)
- On the 1st of each month (or whenever funds arrive):
  - Calculates: `Agreed Monthly Salary + Previous Unpaid Salary Carry-Forward + Accumulated Pending Field TA Claims`.
  - **Variable Payout Support**: If available project grant funds are limited (e.g. only ₹10,000 can be paid out of ₹25,000 due):
    - The user enters the actual amount paid now (₹10,000).
    - The unpaid remainder (₹15,000) automatically carries forward as **Pending Salary Due** for the next month!
    - Deducts only the disbursed amount from the project fund and updates the staff member's ledger.

### 7. Live Activity Audit Feed with Indian Standard Time (IST)
- Every transaction recorded, edited, deleted, settled, or approved appears in real-time on the Dashboard with full **Indian Standard Time (IST)** timestamps (e.g. `29-Oct-2026, 05:32 PM IST`).

---

## 🚀 How to Run Locally

1. Open PowerShell and navigate to the project directory:
   ```powershell
   cd C:\Users\Administrator\.gemini\antigravity\scratch\ngo_finance_app
   ```
2. Start the server:
   ```powershell
   python app.py
   ```
3. Open in your browser:
   [http://localhost:8000](http://localhost:8000)
4. Use the quick login demo buttons for any of the 4 staff members (PIN: `123456`) or register a new staff member to test WhatsApp OTP verification and peer approval!
