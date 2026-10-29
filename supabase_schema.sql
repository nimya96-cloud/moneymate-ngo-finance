-- ==============================================================================
-- MoneyMate NGO Finance - CSA & CNCP Multi-Project System
-- Supabase PostgreSQL Database Schema
-- Projects: CSA (Child Support Action) & CNCP (Children in Need of Care & Protection)
-- Features:
-- 1. Dual Projects (CSA & CNCP) Inflows, Common Expenses, and Staff Field TA
-- 2. 4 Staff Roles: CSA Coordinator, CSA Case Worker, CNCP Coordinator, CNCP Case Worker
-- 3. Individual Staff Ledgers with Date Range
-- 4. Partial / Variable Monthly Salary Payout with Pending Salary Carry-Forward
-- 5. WhatsApp OTP Registration with Peer Approval Before Login
-- 6. Relieve Staff Deactivation with Peer Approval
-- 7. Live Activity Audit Trail in Indian Standard Time (IST)
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Set Timezone to Indian Standard Time (IST)
SET timezone = 'Asia/Kolkata';

-- 1. Projects Table
CREATE TABLE IF NOT EXISTS public.projects (
    id VARCHAR(10) PRIMARY KEY, -- 'CSA' or 'CNCP'
    name TEXT NOT NULL,
    full_title TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata')
);

INSERT INTO public.projects (id, name, full_title)
VALUES 
    ('CSA', 'CSA Project', 'Child Support & Care Action (CSA)'),
    ('CNCP', 'CNCP Project', 'Children in Need of Care and Protection (CNCP)')
ON CONFLICT (id) DO NOTHING;

-- 2. Staff Profiles
CREATE TABLE IF NOT EXISTS public.staff_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name TEXT NOT NULL,
    whatsapp_number TEXT NOT NULL UNIQUE,
    project VARCHAR(10) NOT NULL REFERENCES public.projects(id),
    designation VARCHAR(50) NOT NULL CHECK (designation IN (
        'CSA Coordinator', 'CSA Case Worker', 'CNCP Coordinator', 'CNCP Case Worker'
    )),
    fixed_salary NUMERIC(12, 2) DEFAULT 20000.00,
    security_pin VARCHAR(6) NOT NULL DEFAULT '123456',
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING_APPROVAL' CHECK (status IN ('ACTIVE', 'PENDING_APPROVAL', 'RELIEVED')),
    pending_salary_due NUMERIC(12, 2) DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata')
);

-- 3. Categories Table
CREATE TABLE IF NOT EXISTS public.categories (
    id VARCHAR(50) PRIMARY KEY,
    name TEXT NOT NULL,
    category_type VARCHAR(20) NOT NULL CHECK (category_type IN ('INCOME', 'COMMON_EXPENSE', 'FIELD_EXPENSE')),
    project VARCHAR(10) DEFAULT 'BOTH',
    description TEXT
);

-- 4. Transactions Table
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
    project VARCHAR(10) NOT NULL REFERENCES public.projects(id),
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('INCOME', 'COMMON_EXPENSE', 'FIELD_EXPENSE')),
    category_id VARCHAR(50) NOT NULL REFERENCES public.categories(id),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    description TEXT NOT NULL,
    created_by UUID NOT NULL REFERENCES public.staff_profiles(id),
    staff_id UUID REFERENCES public.staff_profiles(id), -- For Field TA claims
    is_settled BOOLEAN DEFAULT FALSE,
    settlement_id UUID,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMPTZ,
    deleted_by UUID REFERENCES public.staff_profiles(id),
    deletion_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata')
);

-- 5. Monthly Settlements (With Partial Payout & Carry-Forward Tracking)
CREATE TABLE IF NOT EXISTS public.settlements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id UUID NOT NULL REFERENCES public.staff_profiles(id),
    project VARCHAR(10) NOT NULL REFERENCES public.projects(id),
    month_period VARCHAR(7) NOT NULL, -- 'YYYY-MM'
    salary_entitlement NUMERIC(12, 2) NOT NULL,
    previous_salary_due NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    total_salary_due NUMERIC(12, 2) NOT NULL,
    ta_claims_total NUMERIC(12, 2) NOT NULL,
    total_due_payable NUMERIC(12, 2) NOT NULL,
    actual_amount_paid NUMERIC(12, 2) NOT NULL,
    pending_salary_carry_forward NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    pending_ta_carry_forward NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    payment_mode VARCHAR(30) DEFAULT 'Bank Transfer',
    reference_number TEXT,
    notes TEXT,
    settled_by UUID NOT NULL REFERENCES public.staff_profiles(id),
    settlement_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata')
);

-- 6. Dual Approval Requests Table
CREATE TABLE IF NOT EXISTS public.dual_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action_type VARCHAR(30) NOT NULL CHECK (action_type IN (
        'APPROVE_NEW_STAFF', 'RELIEVE_STAFF', 'NEW_CATEGORY', 'EDIT_TRANSACTION', 'DELETE_TRANSACTION', 'SETTLEMENT'
    )),
    target_table VARCHAR(50),
    target_id UUID,
    payload JSONB NOT NULL,
    requested_by UUID NOT NULL,
    requester_name TEXT,
    action_label TEXT NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
    approved_by UUID REFERENCES public.staff_profiles(id),
    approval_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata'),
    resolved_at TIMESTAMPTZ
);

-- 7. In-App Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type VARCHAR(30) NOT NULL DEFAULT 'INFO',
    project VARCHAR(10) DEFAULT 'ALL',
    sender_id UUID,
    related_id UUID,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata')
);

-- 8. Immutable Audit Trail
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(50) NOT NULL,
    record_id UUID NOT NULL,
    action VARCHAR(20) NOT NULL,
    performed_by UUID REFERENCES public.staff_profiles(id),
    change_summary TEXT,
    old_data JSONB,
    new_data JSONB,
    timestamp TIMESTAMPTZ DEFAULT (NOW() AT TIME ZONE 'Asia/Kolkata')
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_transactions_project ON public.transactions(project);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_staff ON public.transactions(staff_id);
CREATE INDEX IF NOT EXISTS idx_settlements_staff ON public.settlements(staff_id);

-- Initial 4 Active Staff Seed Profiles
INSERT INTO public.staff_profiles (id, full_name, whatsapp_number, project, designation, fixed_salary, security_pin, status)
VALUES 
    ('11111111-1111-1111-1111-111111111111', 'Rahul Nair', '9846011111', 'CSA', 'CSA Coordinator', 25000.00, '123456', 'ACTIVE'),
    ('22222222-2222-2222-2222-222222222222', 'Priya Menon', '9846022222', 'CSA', 'CSA Case Worker', 20000.00, '123456', 'ACTIVE'),
    ('33333333-3333-3333-3333-333333333333', 'Anand Kumar', '9846033333', 'CNCP', 'CNCP Coordinator', 25000.00, '123456', 'ACTIVE'),
    ('44444444-4444-4444-4444-444444444444', 'Deepa Varghese', '9846044444', 'CNCP', 'CNCP Case Worker', 20000.00, '123456', 'ACTIVE')
ON CONFLICT (id) DO NOTHING;
