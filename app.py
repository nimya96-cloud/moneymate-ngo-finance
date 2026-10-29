import os
import json
import uuid
import io
import re
import urllib.parse
from datetime import datetime, timezone, timedelta, date
from typing import Optional, List, Dict, Any
from fastapi import FastAPI, HTTPException, UploadFile, File, Form, Depends, Query, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse, JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image

# Indian Standard Time (IST = UTC + 5:30)
IST = timezone(timedelta(hours=5, minutes=30))

def now_ist() -> datetime:
    return datetime.now(IST)

def now_ist_iso() -> str:
    return now_ist().isoformat()

def now_ist_str() -> str:
    return now_ist().strftime("%d-%b-%Y, %I:%M %p IST")

app = FastAPI(title="MoneyMate NGO Finance - CSA & CNCP Projects", version="2.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DATA_FILE = os.path.join(os.path.dirname(__file__), "ngo_data.json")
UPLOADS_DIR = os.path.join(os.path.dirname(__file__), "uploads")
STATIC_DIR = os.path.join(os.path.dirname(__file__), "static")
os.makedirs(UPLOADS_DIR, exist_ok=True)
os.makedirs(STATIC_DIR, exist_ok=True)

# Default 4 Staff Members across CSA and CNCP Projects
DEFAULT_DATA = {
    "projects": [
        {"id": "CSA", "name": "CSA Project", "full_title": "Child Support & Care Action (CSA)", "color": "emerald"},
        {"id": "CNCP", "name": "CNCP Project", "full_title": "Children in Need of Care and Protection (CNCP)", "color": "indigo"}
    ],
    "staff_profiles": [
        {
            "id": "11111111-1111-1111-1111-111111111111",
            "full_name": "Rahul Nair",
            "whatsapp_number": "9846011111",
            "project": "CSA",
            "designation": "CSA Coordinator",
            "fixed_salary": 25000.00,
            "security_pin": "123456",
            "status": "ACTIVE",  # ACTIVE, PENDING_APPROVAL, RELIEVED
            "pending_salary_due": 0.0,
            "created_at": now_ist_iso()
        },
        {
            "id": "22222222-2222-2222-2222-222222222222",
            "full_name": "Priya Menon",
            "whatsapp_number": "9846022222",
            "project": "CSA",
            "designation": "CSA Case Worker",
            "fixed_salary": 20000.00,
            "security_pin": "123456",
            "status": "ACTIVE",
            "pending_salary_due": 0.0,
            "created_at": now_ist_iso()
        },
        {
            "id": "33333333-3333-3333-3333-333333333333",
            "full_name": "Anand Kumar",
            "whatsapp_number": "9846033333",
            "project": "CNCP",
            "designation": "CNCP Coordinator",
            "fixed_salary": 25000.00,
            "security_pin": "123456",
            "status": "ACTIVE",
            "pending_salary_due": 0.0,
            "created_at": now_ist_iso()
        },
        {
            "id": "44444444-4444-4444-4444-444444444444",
            "full_name": "Deepa Varghese",
            "whatsapp_number": "9846044444",
            "project": "CNCP",
            "designation": "CNCP Case Worker",
            "fixed_salary": 20000.00,
            "security_pin": "123456",
            "status": "ACTIVE",
            "pending_salary_due": 0.0,
            "created_at": now_ist_iso()
        }
    ],
    "categories": [
        # Income Categories
        {"id": "cat_inc_1", "name": "Govt / Foundation Project Grant", "category_type": "INCOME", "project": "BOTH", "description": "Principal grant funding"},
        {"id": "cat_inc_2", "name": "CSR & Corporate Donation", "category_type": "INCOME", "project": "BOTH", "description": "CSR support funds"},
        {"id": "cat_inc_3", "name": "Public / Individual Contribution", "category_type": "INCOME", "project": "BOTH", "description": "Community donations"},
        
        # Common Expenses
        {"id": "cat_exp_1", "name": "Office Rent & Facility Maintenance", "category_type": "COMMON_EXPENSE", "project": "BOTH", "description": "Shared office rent"},
        {"id": "cat_exp_2", "name": "Electricity, Water & Internet Bills", "category_type": "COMMON_EXPENSE", "project": "BOTH", "description": "Utilities"},
        {"id": "cat_exp_3", "name": "Monthly Staff Salary Payout", "category_type": "COMMON_EXPENSE", "project": "BOTH", "description": "Salary disbursement"},
        {"id": "cat_exp_4", "name": "Documentation, Printing & Stationeries", "category_type": "COMMON_EXPENSE", "project": "BOTH", "description": "Office supplies"},
        {"id": "cat_exp_5", "name": "Case Review Meeting & Refreshments", "category_type": "COMMON_EXPENSE", "project": "BOTH", "description": "Meeting expenses"},
        
        # Staff Field Expenses (TA, Food, Case Support)
        {"id": "cat_field_1", "name": "Field Travel Allowance (TA) & Fuel", "category_type": "FIELD_EXPENSE", "project": "BOTH", "description": "Bus, auto, bike travel for home visits"},
        {"id": "cat_field_2", "name": "Field Food & Daily Subsistence", "category_type": "FIELD_EXPENSE", "project": "BOTH", "description": "Meals during remote field visits"},
        {"id": "cat_field_3", "name": "Child Emergency Assistance / Medicines", "category_type": "FIELD_EXPENSE", "project": "BOTH", "description": "Immediate support on field"},
        {"id": "cat_field_4", "name": "Station Stay & Camp Accommodation", "category_type": "FIELD_EXPENSE", "project": "BOTH", "description": "Night halts for distant cases"}
    ],
    "transactions": [
        # CSA Initial Grant
        {
            "id": "tx_csa_grant",
            "transaction_date": str(date.today() - timedelta(days=20)),
            "project": "CSA",
            "transaction_type": "INCOME",
            "category_id": "cat_inc_1",
            "amount": 150000.00,
            "description": "CSA Project Q3 Grant received from Child Welfare Dept",
            "created_by": "11111111-1111-1111-1111-111111111111",
            "staff_id": None,
            "is_settled": False,
            "settlement_id": None,
            "is_deleted": False,
            "documents": [],
            "created_at": (now_ist() - timedelta(days=20)).isoformat()
        },
        # CNCP Initial Grant
        {
            "id": "tx_cncp_grant",
            "transaction_date": str(date.today() - timedelta(days=18)),
            "project": "CNCP",
            "transaction_type": "INCOME",
            "category_id": "cat_inc_1",
            "amount": 180000.00,
            "description": "CNCP Annual Care Grant tranche credited",
            "created_by": "33333333-3333-3333-3333-333333333333",
            "staff_id": None,
            "is_settled": False,
            "settlement_id": None,
            "is_deleted": False,
            "documents": [],
            "created_at": (now_ist() - timedelta(days=18)).isoformat()
        },
        # Common Office Rent (Split across projects)
        {
            "id": "tx_office_rent_csa",
            "transaction_date": str(date.today() - timedelta(days=10)),
            "project": "CSA",
            "transaction_type": "COMMON_EXPENSE",
            "category_id": "cat_exp_1",
            "amount": 6000.00,
            "description": "Office Rent Share (50% CSA)",
            "created_by": "11111111-1111-1111-1111-111111111111",
            "staff_id": None,
            "is_settled": False,
            "settlement_id": None,
            "is_deleted": False,
            "documents": [],
            "created_at": (now_ist() - timedelta(days=10)).isoformat()
        },
        {
            "id": "tx_office_rent_cncp",
            "transaction_date": str(date.today() - timedelta(days=10)),
            "project": "CNCP",
            "transaction_type": "COMMON_EXPENSE",
            "category_id": "cat_exp_1",
            "amount": 6000.00,
            "description": "Office Rent Share (50% CNCP)",
            "created_by": "33333333-3333-3333-3333-333333333333",
            "staff_id": None,
            "is_settled": False,
            "settlement_id": None,
            "is_deleted": False,
            "documents": [],
            "created_at": (now_ist() - timedelta(days=10)).isoformat()
        },
        # Priya (CSA Case Worker) Field TA Claim
        {
            "id": "tx_field_priya_1",
            "transaction_date": str(date.today() - timedelta(days=5)),
            "project": "CSA",
            "transaction_type": "FIELD_EXPENSE",
            "category_id": "cat_field_1",
            "amount": 1250.00,
            "description": "CSA Case Home Investigation: Malappuram Tribal Ward travel bike fuel",
            "created_by": "22222222-2222-2222-2222-222222222222",
            "staff_id": "22222222-2222-2222-2222-222222222222",
            "is_settled": False,
            "settlement_id": None,
            "is_deleted": False,
            "documents": [],
            "created_at": (now_ist() - timedelta(days=5)).isoformat()
        },
        {
            "id": "tx_field_priya_2",
            "transaction_date": str(date.today() - timedelta(days=4)),
            "project": "CSA",
            "transaction_type": "FIELD_EXPENSE",
            "category_id": "cat_field_2",
            "amount": 350.00,
            "description": "Lunch & refreshments during field survey with CWC team",
            "created_by": "22222222-2222-2222-2222-222222222222",
            "staff_id": "22222222-2222-2222-2222-222222222222",
            "is_settled": False,
            "settlement_id": None,
            "is_deleted": False,
            "documents": [],
            "created_at": (now_ist() - timedelta(days=4)).isoformat()
        },
        # Deepa (CNCP Case Worker) Field TA Claim
        {
            "id": "tx_field_deepa_1",
            "transaction_date": str(date.today() - timedelta(days=3)),
            "project": "CNCP",
            "transaction_type": "FIELD_EXPENSE",
            "category_id": "cat_field_1",
            "amount": 950.00,
            "description": "CNCP Child Care Home Visit KSRTC Bus fare & auto",
            "created_by": "44444444-4444-4444-4444-444444444444",
            "staff_id": "44444444-4444-4444-4444-444444444444",
            "is_settled": False,
            "settlement_id": None,
            "is_deleted": False,
            "documents": [],
            "created_at": (now_ist() - timedelta(days=3)).isoformat()
        }
    ],
    "settlements": [],
    "dual_approvals": [],
    "active_otps": {},  # phone -> {otp, expiry}
    "notifications": [
        {
            "id": str(uuid.uuid4()),
            "title": "Welcome to MoneyMate NGO System",
            "message": "CSA and CNCP projects initialized. 4 active staff accounts ready with individual TA ledgers.",
            "notification_type": "INFO",
            "project": "ALL",
            "sender_id": "11111111-1111-1111-1111-111111111111",
            "is_read": False,
            "created_at": now_ist_iso(),
            "created_at_formatted": now_ist_str()
        }
    ],
    "audit_logs": [
        {
            "id": str(uuid.uuid4()),
            "table_name": "system",
            "record_id": "00000000-0000-0000-0000-000000000000",
            "action": "INIT",
            "performed_by": "11111111-1111-1111-1111-111111111111",
            "change_summary": "System initialized for CSA & CNCP projects with 4 staff profiles.",
            "timestamp": now_ist_iso(),
            "timestamp_formatted": now_ist_str()
        }
    ]
}

def normalize_phone(p: str) -> str:
    clean = re.sub(r"\D", "", str(p)).strip()
    if clean.startswith("91") and len(clean) == 12:
        clean = clean[2:]
    return clean

def load_data():
    if not os.path.exists(DATA_FILE):
        save_data(DEFAULT_DATA)
        return DEFAULT_DATA
    try:
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return DEFAULT_DATA

def save_data(data):
    with open(DATA_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def log_audit(data, table_name, record_id, action, performed_by, change_summary, old_data=None, new_data=None):
    log_entry = {
        "id": str(uuid.uuid4()),
        "table_name": table_name,
        "record_id": str(record_id),
        "action": action,
        "performed_by": str(performed_by),
        "change_summary": change_summary,
        "old_data": old_data,
        "new_data": new_data,
        "timestamp": now_ist_iso(),
        "timestamp_formatted": now_ist_str()
    }
    data["audit_logs"].insert(0, log_entry)

def broadcast_notification(data, title, message, notif_type, sender_id, project="ALL", related_id=None):
    notif = {
        "id": str(uuid.uuid4()),
        "title": title,
        "message": message,
        "notification_type": notif_type,
        "project": project,
        "sender_id": str(sender_id),
        "related_id": str(related_id) if related_id else None,
        "is_read": False,
        "created_at": now_ist_iso(),
        "created_at_formatted": now_ist_str()
    }
    data["notifications"].insert(0, notif)

# Models
class SendOtpRequest(BaseModel):
    whatsapp_number: str
    full_name: str

class VerifyAndRegisterRequest(BaseModel):
    full_name: str
    whatsapp_number: str
    project: str  # CSA or CNCP
    designation: str  # CSA Coordinator, CSA Case Worker, CNCP Coordinator, CNCP Case Worker
    fixed_salary: float
    security_pin: str
    otp_code: str

class LoginRequest(BaseModel):
    identifier: str
    pin: str

class TransactionCreate(BaseModel):
    transaction_date: str
    project: str  # CSA or CNCP
    transaction_type: str  # INCOME, COMMON_EXPENSE, FIELD_EXPENSE
    category_id: str
    amount: float
    description: str
    created_by: str
    staff_id: Optional[str] = None
    documents: Optional[List[Dict[str, Any]]] = []

class TransactionUpdate(BaseModel):
    transaction_date: Optional[str] = None
    category_id: Optional[str] = None
    amount: Optional[float] = None
    description: Optional[str] = None
    updated_by: str

class DeleteRequest(BaseModel):
    deleted_by: str
    reason: str

class SettlementRequest(BaseModel):
    staff_id: str
    project: str  # CSA or CNCP
    month_period: str  # e.g. "2026-11"
    salary_entitlement: float  # Agreed fixed monthly salary
    accumulated_ta_claims: float  # Field claims sum
    actual_amount_paid_now: float  # What is actually paid now (could be less!)
    payment_mode: str = "Bank Transfer"
    reference_number: Optional[str] = ""
    notes: Optional[str] = ""
    settled_by: str

class ApprovalResolve(BaseModel):
    approval_id: str
    resolved_by: str
    decision: str  # APPROVED or REJECTED
    pin: str
    notes: Optional[str] = ""

class RelieveStaffRequest(BaseModel):
    target_staff_id: str
    requested_by: str
    reason: str

# Serve Static App Files
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
app.mount("/uploads", StaticFiles(directory=UPLOADS_DIR), name="uploads")

@app.get("/", response_class=HTMLResponse)
async def serve_index():
    index_file = os.path.join(STATIC_DIR, "index.html")
    if os.path.exists(index_file):
        with open(index_file, "r", encoding="utf-8") as f:
            return f.read()
    return "<h1>MoneyMate NGO Finance Backend</h1>"

# ==============================================================
# AUTHENTICATION & WHATSAPP OTP ENDPOINTS
# ==============================================================

@app.post("/api/auth/send-registration-otp")
def send_registration_otp(req: SendOtpRequest):
    data = load_data()
    clean_phone = normalize_phone(req.whatsapp_number)
    
    if len(clean_phone) != 10:
        raise HTTPException(status_code=400, detail="Please enter a valid 10-digit WhatsApp number.")
        
    # Check if already active
    for s in data["staff_profiles"]:
        if normalize_phone(s.get("whatsapp_number", "")) == clean_phone and s.get("status") == "ACTIVE":
            raise HTTPException(status_code=400, detail="This WhatsApp number is already registered and active. Please log in.")

    import random
    otp = f"{random.randint(100000, 999999)}"
    expiry = (now_ist() + timedelta(minutes=10)).isoformat()
    
    if "active_otps" not in data:
        data["active_otps"] = {}
    data["active_otps"][clean_phone] = {"otp": otp, "expiry": expiry}
    save_data(data)
    
    # Pre-formatted WhatsApp direct link
    message = (
        f"🔐 *MoneyMate NGO Finance — Registration Verification*\n\n"
        f"Hello *{req.full_name}*,\n\n"
        f"Your WhatsApp Registration OTP for CSA/CNCP Project Portal is:\n"
        f"👉 *{otp}*\n\n"
        f"⏱️ Valid for 10 minutes. Please enter this in the app.\n"
        f"_MoneyMate NGO Financial System_"
    )
    encoded = urllib.parse.quote(message)
    wa_link = f"https://wa.me/91{clean_phone}?text={encoded}"
    
    return {
        "status": "success",
        "message": f"OTP generated for +91 {clean_phone}",
        "otp": otp,
        "whatsapp_url": wa_link
    }

@app.post("/api/auth/verify-and-register")
def verify_and_register(req: VerifyAndRegisterRequest):
    data = load_data()
    clean_phone = normalize_phone(req.whatsapp_number)
    
    # Verify OTP
    active_otps = data.get("active_otps", {})
    record = active_otps.get(clean_phone)
    if not record or record.get("otp") != req.otp_code.strip():
        raise HTTPException(status_code=400, detail="Invalid or expired OTP entered.")
        
    # Valid designations check
    allowed_designations = [
        "CSA Coordinator",
        "CSA Case Worker",
        "CNCP Coordinator",
        "CNCP Case Worker"
    ]
    if req.designation not in allowed_designations:
        raise HTTPException(status_code=400, detail=f"Designation must be one of: {', '.join(allowed_designations)}")

    new_id = str(uuid.uuid4())
    # User is initially created with PENDING_APPROVAL status!
    new_user = {
        "id": new_id,
        "full_name": req.full_name.strip(),
        "whatsapp_number": clean_phone,
        "project": req.project.strip().upper(),
        "designation": req.designation.strip(),
        "fixed_salary": float(req.fixed_salary or 0.0),
        "security_pin": req.security_pin.strip(),
        "status": "PENDING_APPROVAL",  # Peer must approve before login!
        "pending_salary_due": 0.0,
        "created_at": now_ist_iso()
    }
    data["staff_profiles"].append(new_user)
    
    # Create Dual Approval Request for peer approval
    approval_id = str(uuid.uuid4())
    import random
    otp_code = f"{random.randint(100000, 999999)}"
    approval_record = {
        "id": approval_id,
        "action_type": "APPROVE_NEW_STAFF",
        "target_table": "staff_profiles",
        "target_id": new_id,
        "payload": {
            "staff_id": new_id,
            "full_name": new_user["full_name"],
            "designation": new_user["designation"],
            "project": new_user["project"],
            "fixed_salary": new_user["fixed_salary"],
            "whatsapp_number": clean_phone
        },
        "requested_by": new_id,
        "requester_name": new_user["full_name"],
        "action_label": f"Approve New Staff Onboarding: {new_user['full_name']} ({new_user['designation']})",
        "otp_code": otp_code,
        "status": "PENDING",
        "approved_by": None,
        "approval_notes": "",
        "created_at": now_ist_iso(),
        "resolved_at": None
    }
    data["dual_approvals"].insert(0, approval_record)
    
    # Remove consumed OTP
    active_otps.pop(clean_phone, None)
    
    log_audit(
        data, "staff_profiles", new_id, "REGISTER_REQUEST", new_id,
        f"New staff registration submitted: {new_user['full_name']} ({new_user['designation']} - {new_user['project']}). Awaiting peer approval."
    )
    broadcast_notification(
        data,
        "New Staff Awaiting Peer Approval",
        f"{new_user['full_name']} registered as {new_user['designation']} ({new_user['project']}). Another team member must approve to allow login.",
        "APPROVAL_REQUEST",
        new_id,
        project=new_user["project"],
        related_id=approval_id
    )
    
    save_data(data)
    return {
        "status": "success",
        "message": "Registration OTP verified! Your account is submitted for peer approval. Any active staff member can approve your account so you can log in.",
        "user_id": new_id,
        "needs_peer_approval": True
    }

@app.post("/api/auth/login")
def login_user(req: LoginRequest):
    data = load_data()
    clean_id = normalize_phone(req.identifier)
    
    user = None
    for s in data["staff_profiles"]:
        staff_phone = normalize_phone(s.get("whatsapp_number", ""))
        staff_name = s.get("full_name", "").lower().replace(" ", "").strip()
        if clean_id in [staff_phone, staff_name]:
            user = s
            break
            
    if not user:
        raise HTTPException(status_code=401, detail="Staff account not found. Please register first.")
    
    if user.get("security_pin", "123456") != req.pin.strip():
        raise HTTPException(status_code=401, detail="Incorrect security PIN entered.")
        
    if user.get("status") == "PENDING_APPROVAL":
        raise HTTPException(
            status_code=403,
            detail="Your registration is currently pending peer approval. Another active staff member must approve your account before you can log in."
        )
        
    if user.get("status") == "RELIEVED":
        raise HTTPException(
            status_code=403,
            detail="This staff account has been relieved / deactivated. Login access has ended."
        )
        
    log_audit(
        data, "staff_profiles", user["id"], "LOGIN", user["id"],
        f"{user['full_name']} ({user['designation']}) logged in."
    )
    save_data(data)
    
    safe_profile = dict(user)
    safe_profile.pop("security_pin", None)
    return {
        "status": "success",
        "message": f"Welcome back, {user['full_name']}!",
        "user": safe_profile
    }

# ==============================================================
# STAFF DIRECTORY & RELIEVING (DEACTIVATION) WITH PEER APPROVAL
# ==============================================================

@app.get("/api/staff")
def get_staff(project: Optional[str] = None):
    data = load_data()
    safe_staff = []
    for s in data["staff_profiles"]:
        if project and s.get("project") != project:
            continue
        item = dict(s)
        item.pop("security_pin", None)
        safe_staff.append(item)
    return safe_staff

@app.post("/api/staff/request-relieve")
def request_relieve_staff(req: RelieveStaffRequest):
    data = load_data()
    target = next((s for s in data["staff_profiles"] if s["id"] == req.target_staff_id), None)
    if not target:
        raise HTTPException(status_code=404, detail="Target staff not found")
        
    requester = next((s for s in data["staff_profiles"] if s["id"] == req.requested_by), None)
    requester_name = requester["full_name"] if requester else "A team member"
    
    approval_id = str(uuid.uuid4())
    import random
    otp_code = f"{random.randint(100000, 999999)}"
    
    approval_record = {
        "id": approval_id,
        "action_type": "RELIEVE_STAFF",
        "target_table": "staff_profiles",
        "target_id": req.target_staff_id,
        "payload": {
            "staff_id": req.target_staff_id,
            "staff_name": target["full_name"],
            "designation": target["designation"],
            "reason": req.reason
        },
        "requested_by": req.requested_by,
        "requester_name": requester_name,
        "action_label": f"Relieve Staff Member: {target['full_name']} ({target['designation']})",
        "otp_code": otp_code,
        "status": "PENDING",
        "approved_by": None,
        "approval_notes": "",
        "created_at": now_ist_iso(),
        "resolved_at": None
    }
    data["dual_approvals"].insert(0, approval_record)
    
    broadcast_notification(
        data,
        "Staff Relieving Approval Required",
        f"{requester_name} initiated relieving of {target['full_name']}. Reason: '{req.reason}'. Verification OTP: {otp_code}.",
        "APPROVAL_REQUEST",
        req.requested_by,
        project=target.get("project", "ALL"),
        related_id=approval_id
    )
    
    save_data(data)
    return {"status": "success", "approval_id": approval_id, "otp": otp_code, "message": "Relieving request submitted for peer approval."}

# ==============================================================
# DUAL APPROVALS RESOLUTION
# ==============================================================

@app.get("/api/approvals")
def get_approvals(status: Optional[str] = None):
    data = load_data()
    approvals = data["dual_approvals"]
    if status:
        approvals = [a for a in approvals if a["status"] == status]
    return approvals

@app.post("/api/approvals/resolve")
def resolve_approval(req: ApprovalResolve):
    data = load_data()
    approval = next((a for a in data["dual_approvals"] if a["id"] == req.approval_id), None)
    if not approval:
        raise HTTPException(status_code=404, detail="Approval request not found")
    
    if approval["status"] != "PENDING":
        raise HTTPException(status_code=400, detail="Approval request is already resolved")
    
    # Strict rule: Requester CANNOT approve their own request!
    if approval["requested_by"] == req.resolved_by:
        raise HTTPException(status_code=403, detail="Security Rule: You cannot approve your own request! Another staff member must approve.")
    
    resolver = next((s for s in data["staff_profiles"] if s["id"] == req.resolved_by), None)
    if not resolver or resolver.get("security_pin") != req.pin:
        raise HTTPException(status_code=401, detail="Invalid security PIN entered.")
    
    approval["status"] = req.decision
    approval["approved_by"] = req.resolved_by
    approval["approval_notes"] = req.notes
    approval["resolved_at"] = now_ist_iso()
    
    resolver_name = resolver["full_name"]
    action_label = approval.get("action_label", approval["action_type"])
    
    # Execute effect if APPROVED
    if req.decision == "APPROVED":
        if approval["action_type"] == "APPROVE_NEW_STAFF":
            target_staff_id = approval["payload"]["staff_id"]
            for s in data["staff_profiles"]:
                if s["id"] == target_staff_id:
                    s["status"] = "ACTIVE"
                    break
        elif approval["action_type"] == "RELIEVE_STAFF":
            target_staff_id = approval["payload"]["staff_id"]
            for s in data["staff_profiles"]:
                if s["id"] == target_staff_id:
                    s["status"] = "RELIEVED"
                    break
    
    log_audit(
        data, "dual_approvals", req.approval_id, req.decision,
        req.resolved_by, f"{resolver_name} {req.decision} request: {action_label}"
    )
    broadcast_notification(
        data,
        f"Request {req.decision}",
        f"{resolver_name} {req.decision.lower()} '{action_label}'.",
        "INFO",
        req.resolved_by,
        related_id=req.approval_id
    )
    
    save_data(data)
    return {"status": "success", "decision": req.decision, "approval": approval}

# ==============================================================
# TRANSACTIONS (CSA / CNCP FUND INFLOWS, COMMON EXPS, TA CLAIMS)
# ==============================================================

@app.get("/api/transactions")
def get_transactions(
    project: Optional[str] = None,
    transaction_type: Optional[str] = None,
    staff_id: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None
):
    data = load_data()
    staff_map = {s["id"]: s["full_name"] for s in data["staff_profiles"]}
    cat_map = {c["id"]: c["name"] for c in data["categories"]}
    
    result = []
    for t in data["transactions"]:
        if t.get("is_deleted", False):
            continue
        if project and project != "ALL" and t.get("project") != project:
            continue
        if transaction_type and transaction_type != "ALL" and t.get("transaction_type") != transaction_type:
            continue
        if staff_id and t.get("staff_id") != staff_id and t.get("created_by") != staff_id:
            continue
        if start_date and str(t.get("transaction_date", "")) < start_date:
            continue
        if end_date and str(t.get("transaction_date", "")) > end_date:
            continue
            
        item = dict(t)
        item["created_by_name"] = staff_map.get(t.get("created_by"), "Unknown")
        item["staff_name"] = staff_map.get(t.get("staff_id"), None) if t.get("staff_id") else None
        item["category_name"] = cat_map.get(t.get("category_id"), "Expense/Grant")
        result.append(item)
        
    result.sort(key=lambda x: (x.get("transaction_date", ""), x.get("created_at", "")), reverse=True)
    return result

@app.post("/api/transactions")
def create_transaction(tx: TransactionCreate):
    data = load_data()
    staff = next((s for s in data["staff_profiles"] if s["id"] == tx.created_by), None)
    staff_name = staff["full_name"] if staff else "A team member"
    
    tx_id = str(uuid.uuid4())
    new_tx = {
        "id": tx_id,
        "transaction_date": tx.transaction_date,
        "project": tx.project.upper(),
        "transaction_type": tx.transaction_type,
        "category_id": tx.category_id,
        "amount": tx.amount,
        "description": tx.description,
        "created_by": tx.created_by,
        "staff_id": tx.staff_id if tx.transaction_type == "FIELD_EXPENSE" else None,
        "is_settled": False,
        "settlement_id": None,
        "is_deleted": False,
        "documents": tx.documents or [],
        "created_at": now_ist_iso()
    }
    data["transactions"].insert(0, new_tx)
    
    log_audit(
        data, "transactions", tx_id, "INSERT", tx.created_by,
        f"{staff_name} recorded {tx.project} {tx.transaction_type}: ₹{tx.amount:,.2f} - '{tx.description}'",
        new_data=new_tx
    )
    broadcast_notification(
        data,
        f"New {tx.project} {tx.transaction_type.replace('_', ' ')}",
        f"{staff_name} entered ₹{tx.amount:,.2f} for '{tx.description}' in {tx.project}.",
        "INFO",
        tx.created_by,
        project=tx.project,
        related_id=tx_id
    )
    
    save_data(data)
    return {"status": "success", "transaction": new_tx}

@app.put("/api/transactions/{tx_id}")
def update_transaction(tx_id: str, update: TransactionUpdate):
    data = load_data()
    tx = next((t for t in data["transactions"] if t["id"] == tx_id), None)
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
        
    if tx["created_by"] != update.updated_by:
        raise HTTPException(status_code=403, detail="Security Violation: You can only edit your own entries!")
        
    old_copy = dict(tx)
    if update.amount is not None:
        tx["amount"] = update.amount
    if update.description is not None:
        tx["description"] = update.description
    if update.transaction_date is not None:
        tx["transaction_date"] = update.transaction_date
    if update.category_id is not None:
        tx["category_id"] = update.category_id
        
    updater = next((s for s in data["staff_profiles"] if s["id"] == update.updated_by), None)
    updater_name = updater["full_name"] if updater else "A team member"
    
    log_audit(
        data, "transactions", tx_id, "UPDATE", update.updated_by,
        f"{updater_name} updated transaction details to ₹{tx.get('amount')}: '{tx.get('description')}'",
        old_data=old_copy,
        new_data=tx
    )
    broadcast_notification(
        data,
        "Transaction Edited",
        f"{updater_name} modified entry: '{tx.get('description')}' to ₹{tx.get('amount'):,.2f}",
        "EDIT_ALERT",
        update.updated_by,
        project=tx.get("project", "ALL"),
        related_id=tx_id
    )
    
    save_data(data)
    return {"status": "success", "transaction": tx}

@app.delete("/api/transactions/{tx_id}")
def delete_transaction(tx_id: str, req: DeleteRequest):
    data = load_data()
    tx = next((t for t in data["transactions"] if t["id"] == tx_id), None)
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
        
    if tx["created_by"] != req.deleted_by:
        raise HTTPException(status_code=403, detail="Security Violation: You can only delete your own entries!")
        
    deleter = next((s for s in data["staff_profiles"] if s["id"] == req.deleted_by), None)
    deleter_name = deleter["full_name"] if deleter else "A team member"
    
    old_copy = dict(tx)
    tx["is_deleted"] = True
    tx["deleted_at"] = now_ist_iso()
    tx["deleted_by"] = req.deleted_by
    tx["deletion_reason"] = req.reason
    
    log_audit(
        data, "transactions", tx_id, "SOFT_DELETE", req.deleted_by,
        f"{deleter_name} deleted transaction of ₹{tx['amount']}: '{tx['description']}'. Reason: {req.reason}",
        old_data=old_copy,
        new_data=tx
    )
    broadcast_notification(
        data,
        "Transaction Deleted",
        f"{deleter_name} deleted an entry: '{tx['description']}' (₹{tx['amount']:,.2f}). Reason: {req.reason}",
        "DELETE_ALERT",
        req.deleted_by,
        project=tx.get("project", "ALL"),
        related_id=tx_id
    )
    
    save_data(data)
    return {"status": "success", "message": "Transaction deleted successfully"}

# ==============================================================
# MONTHLY SALARY & TA SETTLEMENT (WITH PARTIAL PAYOUT & CARRY-FORWARD)
# ==============================================================

@app.get("/api/settlements/pending-summary")
def get_pending_settlement_summary(project: Optional[str] = None):
    data = load_data()
    staff_summary = []
    
    for staff in data["staff_profiles"]:
        if staff.get("status") != "ACTIVE":
            continue
        if project and project != "ALL" and staff.get("project") != project:
            continue
            
        staff_id = staff["id"]
        # Unsettled TA / Field claims
        unsettled_claims = [
            t for t in data["transactions"]
            if t.get("transaction_type") == "FIELD_EXPENSE"
            and t.get("staff_id") == staff_id
            and not t.get("is_settled", False)
            and not t.get("is_deleted", False)
        ]
        
        ta_total = sum(float(t.get("amount", 0.0)) for t in unsettled_claims)
        fixed_salary = float(staff.get("fixed_salary", 0.0))
        previous_salary_due = float(staff.get("pending_salary_due", 0.0))
        
        # Total due for this month
        total_due = fixed_salary + previous_salary_due + ta_total
        
        staff_summary.append({
            "staff_id": staff_id,
            "staff_name": staff["full_name"],
            "project": staff.get("project", "CSA"),
            "designation": staff["designation"],
            "whatsapp_number": staff["whatsapp_number"],
            "fixed_salary": fixed_salary,
            "previous_salary_due": previous_salary_due,
            "current_unsettled_ta_claims_count": len(unsettled_claims),
            "current_unsettled_ta_total": ta_total,
            "total_due_payable": total_due,
            "unsettled_claims": [
                {"id": t["id"], "date": t["transaction_date"], "amount": t["amount"], "description": t["description"]}
                for t in unsettled_claims
            ]
        })
        
    return staff_summary

@app.post("/api/settlements/execute")
def execute_settlement(req: SettlementRequest):
    data = load_data()
    staff = next((s for s in data["staff_profiles"] if s["id"] == req.staff_id), None)
    if not staff:
        raise HTTPException(status_code=404, detail="Staff not found")
        
    settler = next((s for s in data["staff_profiles"] if s["id"] == req.settled_by), None)
    settler_name = settler["full_name"] if settler else "A team member"
    
    # 1. Fetch pending TA claims
    unsettled_claims = [
        t for t in data["transactions"]
        if t.get("transaction_type") == "FIELD_EXPENSE"
        and t.get("staff_id") == req.staff_id
        and not t.get("is_settled", False)
        and not t.get("is_deleted", False)
    ]
    actual_ta_sum = sum(float(t.get("amount", 0.0)) for t in unsettled_claims)
    
    # Total entitlement for this settlement
    prev_salary_due = float(staff.get("pending_salary_due", 0.0))
    total_salary_entitlement = req.salary_entitlement + prev_salary_due
    total_due = total_salary_entitlement + actual_ta_sum
    
    actual_paid = float(req.actual_amount_paid_now)
    
    # How much goes to TA vs Salary:
    # First clear TA claims, remaining pays salary
    paid_towards_ta = min(actual_paid, actual_ta_sum)
    remaining_for_salary = max(0.0, actual_paid - paid_towards_ta)
    
    new_pending_salary_due = max(0.0, total_salary_entitlement - remaining_for_salary)
    new_pending_ta_due = max(0.0, actual_ta_sum - paid_towards_ta)
    
    settlement_id = str(uuid.uuid4())
    settlement_record = {
        "id": settlement_id,
        "staff_id": req.staff_id,
        "staff_name": staff["full_name"],
        "project": req.project.upper(),
        "month_period": req.month_period,
        "salary_entitlement": req.salary_entitlement,
        "previous_salary_due": prev_salary_due,
        "total_salary_due": total_salary_entitlement,
        "ta_claims_total": actual_ta_sum,
        "total_due_payable": total_due,
        "actual_amount_paid": actual_paid,
        "pending_salary_carry_forward": new_pending_salary_due,
        "pending_ta_carry_forward": new_pending_ta_due,
        "payment_mode": req.payment_mode,
        "reference_number": req.reference_number,
        "notes": req.notes,
        "settled_by": req.settled_by,
        "settled_by_name": settler_name,
        "settlement_date": str(date.today()),
        "created_at": now_ist_iso()
    }
    data["settlements"].insert(0, settlement_record)
    
    # Update staff's pending salary balance
    staff["pending_salary_due"] = new_pending_salary_due
    
    # Mark the field claims as settled
    for t in unsettled_claims:
        t["is_settled"] = True
        t["settlement_id"] = settlement_id
        
    # Record Consolidated Common Expense payout transaction in the respective Project!
    if actual_paid > 0:
        payout_tx_id = str(uuid.uuid4())
        payout_tx = {
            "id": payout_tx_id,
            "transaction_date": str(date.today()),
            "project": req.project.upper(),
            "transaction_type": "COMMON_EXPENSE",
            "category_id": "cat_exp_3", # Staff Monthly Salary Payout
            "amount": actual_paid,
            "description": f"Salary & TA Payout for {staff['full_name']} ({req.month_period}): Paid ₹{actual_paid:,.2f} of ₹{total_due:,.2f} (Pending Carry-Forward: ₹{new_pending_salary_due:,.2f})",
            "created_by": req.settled_by,
            "staff_id": req.staff_id,
            "is_settled": True,
            "settlement_id": settlement_id,
            "is_deleted": False,
            "documents": [],
            "created_at": now_ist_iso()
        }
        data["transactions"].insert(0, payout_tx)
        
    log_audit(
        data, "settlements", settlement_id, "EXECUTE", req.settled_by,
        f"{settler_name} settled {req.month_period} dues for {staff['full_name']} ({req.project}): Total Due ₹{total_due:,.2f}, Paid ₹{actual_paid:,.2f}, Carry-Forward Due ₹{new_pending_salary_due:,.2f}"
    )
    broadcast_notification(
        data,
        f"Settlement Recorded ({req.project})",
        f"{staff['full_name']} {req.month_period} settlement: ₹{actual_paid:,.2f} disbursed. Remaining Pending: ₹{new_pending_salary_due:,.2f}.",
        "SETTLEMENT",
        req.settled_by,
        project=req.project,
        related_id=settlement_id
    )
    
    save_data(data)
    return {"status": "success", "settlement": settlement_record}

@app.get("/api/settlements")
def get_settlements(staff_id: Optional[str] = None, project: Optional[str] = None):
    data = load_data()
    settlements = data["settlements"]
    if staff_id:
        settlements = [s for s in settlements if s.get("staff_id") == staff_id]
    if project and project != "ALL":
        settlements = [s for s in settlements if s.get("project") == project]
    return settlements

# ==============================================================
# INDIVIDUAL STAFF LEDGER & DATE RANGE STATEMENTS
# ==============================================================

@app.get("/api/reports/staff-ledger")
def get_staff_ledger(
    staff_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None
):
    data = load_data()
    staff = next((s for s in data["staff_profiles"] if s["id"] == staff_id), None)
    if not staff:
        raise HTTPException(status_code=404, detail="Staff member not found")
        
    # Gather:
    # 1. All field expense claims made by this staff
    # 2. All settlement payouts made to this staff
    entries = []
    
    for t in data["transactions"]:
        if t.get("is_deleted", False):
            continue
        if t.get("staff_id") == staff_id or (t.get("created_by") == staff_id and t.get("transaction_type") == "FIELD_EXPENSE"):
            t_date = t.get("transaction_date", "")
            if start_date and t_date < start_date:
                continue
            if end_date and t_date > end_date:
                continue
                
            entries.append({
                "date": t_date,
                "type": t.get("transaction_type"),
                "project": t.get("project"),
                "description": t.get("description"),
                "amount": float(t.get("amount", 0.0)),
                "is_settled": t.get("is_settled", False),
                "voucher_id": t.get("id"),
                "is_credit_payout": t.get("category_id") == "cat_exp_3"
            })
            
    # Include settlement logs
    for s in data["settlements"]:
        if s.get("staff_id") == staff_id:
            s_date = s.get("settlement_date", "")
            if start_date and s_date < start_date:
                continue
            if end_date and s_date > end_date:
                continue
            entries.append({
                "date": s_date,
                "type": "SETTLEMENT_RECORD",
                "project": s.get("project"),
                "description": f"Salary & TA Settlement ({s.get('month_period')}) - Ref: {s.get('reference_number', 'N/A')}",
                "amount": float(s.get("actual_amount_paid", 0.0)),
                "is_settled": True,
                "voucher_id": s.get("id"),
                "is_credit_payout": True,
                "settlement_details": s
            })
            
    # Sort chronologically
    entries.sort(key=lambda x: x["date"])
    
    total_claims = sum(e["amount"] for e in entries if not e.get("is_credit_payout") and e["type"] == "FIELD_EXPENSE")
    total_paid = sum(e["amount"] for e in entries if e.get("is_credit_payout"))
    
    return {
        "staff_id": staff_id,
        "staff_name": staff["full_name"],
        "project": staff.get("project"),
        "designation": staff["designation"],
        "whatsapp_number": staff["whatsapp_number"],
        "fixed_salary": staff["fixed_salary"],
        "current_pending_salary_due": staff.get("pending_salary_due", 0.0),
        "total_claims_in_period": total_claims,
        "total_paid_in_period": total_paid,
        "entries": entries
    }

# ==============================================================
# DASHBOARD METRICS: DUAL PROJECT BREAKDOWN & LIVE FEED
# ==============================================================

@app.get("/api/dashboard/stats")
def get_dashboard_stats():
    data = load_data()
    active_txs = [t for t in data["transactions"] if not t.get("is_deleted", False)]
    
    def calc_project_stats(proj_code: str):
        proj_txs = [t for t in active_txs if t.get("project") == proj_code]
        income = sum(float(t["amount"]) for t in proj_txs if t["transaction_type"] == "INCOME")
        common_exp = sum(float(t["amount"]) for t in proj_txs if t["transaction_type"] == "COMMON_EXPENSE")
        field_exp = sum(float(t["amount"]) for t in proj_txs if t["transaction_type"] == "FIELD_EXPENSE")
        total_exp = common_exp + field_exp
        balance = income - total_exp
        unsettled_field = sum(float(t["amount"]) for t in proj_txs if t["transaction_type"] == "FIELD_EXPENSE" and not t.get("is_settled", False))
        return {
            "income": income,
            "common_expense": common_exp,
            "field_expense": field_exp,
            "total_expense": total_exp,
            "balance": balance,
            "unsettled_field": unsettled_field
        }
        
    csa_stats = calc_project_stats("CSA")
    cncp_stats = calc_project_stats("CNCP")
    
    total_income = csa_stats["income"] + cncp_stats["income"]
    total_expense = csa_stats["total_expense"] + cncp_stats["total_expense"]
    total_balance = total_income - total_expense
    total_unsettled = csa_stats["unsettled_field"] + cncp_stats["unsettled_field"]
    
    pending_approvals = len([a for a in data["dual_approvals"] if a.get("status") == "PENDING"])
    
    # Live activity feed formatted in IST
    live_feed = []
    for log in data["audit_logs"][:15]:
        live_feed.append({
            "id": log["id"],
            "summary": log["change_summary"],
            "action": log["action"],
            "performer": next((s["full_name"] for s in data["staff_profiles"] if s["id"] == log.get("performed_by")), "System"),
            "timestamp_formatted": log.get("timestamp_formatted", log.get("timestamp"))
        })
        
    return {
        "current_time_ist": now_ist_str(),
        "total_income": total_income,
        "total_expense": total_expense,
        "total_balance": total_balance,
        "total_unsettled_ta": total_unsettled,
        "pending_approvals_count": pending_approvals,
        "csa": csa_stats,
        "cncp": cncp_stats,
        "live_feed": live_feed
    }

# Document Upload with Compression
@app.post("/api/documents/upload")
async def upload_document(
    file: UploadFile = File(...),
    uploaded_by: str = Form(...)
):
    contents = await file.read()
    orig_size_kb = len(contents) / 1024.0
    ext = os.path.splitext(file.filename)[1].lower()
    file_id = str(uuid.uuid4())
    compressed_size_kb = orig_size_kb
    saved_filename = f"{file_id}{ext}"
    saved_path = os.path.join(UPLOADS_DIR, saved_filename)
    
    if ext in [".jpg", ".jpeg", ".png", ".webp"]:
        try:
            image = Image.open(io.BytesIO(contents))
            if image.mode in ("RGBA", "P"):
                image = image.convert("RGB")
            max_size = (1280, 1280)
            image.thumbnail(max_size, Image.Resampling.LANCZOS)
            compressed_filename = f"{file_id}.jpg"
            saved_path = os.path.join(UPLOADS_DIR, compressed_filename)
            saved_filename = compressed_filename
            image.save(saved_path, "JPEG", optimize=True, quality=72)
            compressed_size_kb = os.path.getsize(saved_path) / 1024.0
        except Exception:
            with open(saved_path, "wb") as f:
                f.write(contents)
    else:
        with open(saved_path, "wb") as f:
            f.write(contents)
            
    return {
        "id": file_id,
        "file_name": file.filename,
        "file_url": f"/uploads/{saved_filename}",
        "original_size_kb": round(orig_size_kb, 1),
        "compressed_size_kb": round(compressed_size_kb, 1),
        "mime_type": file.content_type,
        "uploaded_by": uploaded_by,
        "uploaded_at": now_ist_iso()
    }

@app.get("/api/notifications")
def get_notifications():
    data = load_data()
    return data["notifications"]

@app.post("/api/notifications/mark-read")
def mark_notifications_read():
    data = load_data()
    for n in data["notifications"]:
        n["is_read"] = True
    save_data(data)
    return {"status": "success"}

@app.get("/api/categories")
def get_categories():
    data = load_data()
    return data["categories"]

@app.get("/api/backup/export")
def export_backup():
    data = load_data()
    return JSONResponse(
        content=data,
        headers={"Content-Disposition": f"attachment; filename=moneymate_ngo_backup_{date.today()}.json"}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
