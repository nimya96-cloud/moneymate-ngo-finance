import 'package:intl/intl.dart';

/// Formats any number into Indian Rupee format (₹xx,xx,xxx.xx)
String formatCurrency(num? amount) {
  if (amount == null) return '₹0.00';
  final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
  return formatter.format(amount);
}

/// Formats date string (YYYY-MM-DD) into readable IST format (e.g. 29 Oct 2026)
String formatDateDisplay(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '—';
  try {
    final parsed = DateTime.parse(dateStr);
    return DateFormat('dd MMM yyyy').format(parsed);
  } catch (_) {
    return dateStr;
  }
}

// ============================================================================
// STAFF MODEL
// ============================================================================
class Staff {
  final String id;
  final String fullName;
  final String whatsappNumber;
  final String project; // CSA or CNCP
  final String designation; // CSA Coordinator, CSA Case Worker, etc.
  final double fixedSalary;
  final String? securityPin;
  final String status; // ACTIVE, PENDING_APPROVAL, RELIEVED
  final double pendingSalaryDue;
  final String createdAt;

  const Staff({
    required this.id,
    required this.fullName,
    required this.whatsappNumber,
    required this.project,
    required this.designation,
    required this.fixedSalary,
    this.securityPin,
    required this.status,
    required this.pendingSalaryDue,
    required this.createdAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isPendingApproval => status.toUpperCase() == 'PENDING_APPROVAL';
  bool get isRelieved => status.toUpperCase() == 'RELIEVED';
  bool get isCoordinator => designation.toLowerCase().contains('coordinator');

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      whatsappNumber: json['whatsapp_number']?.toString() ?? '',
      project: (json['project']?.toString() ?? 'CSA').toUpperCase(),
      designation: json['designation']?.toString() ?? '',
      fixedSalary: (json['fixed_salary'] as num?)?.toDouble() ?? 0.0,
      securityPin: json['security_pin']?.toString(),
      status: (json['status']?.toString() ?? 'ACTIVE').toUpperCase(),
      pendingSalaryDue: (json['pending_salary_due'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'whatsapp_number': whatsappNumber,
      'project': project,
      'designation': designation,
      'fixed_salary': fixedSalary,
      if (securityPin != null) 'security_pin': securityPin,
      'status': status,
      'pending_salary_due': pendingSalaryDue,
      'created_at': createdAt,
    };
  }
}

// ============================================================================
// CATEGORY MODEL
// ============================================================================
class Category {
  final String id;
  final String name;
  final String categoryType; // INCOME, COMMON_EXPENSE, FIELD_EXPENSE
  final String? project; // CSA, CNCP, or BOTH
  final String? description;

  const Category({
    required this.id,
    required this.name,
    required this.categoryType,
    this.project,
    this.description,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categoryType: (json['category_type']?.toString() ?? 'COMMON_EXPENSE').toUpperCase(),
      project: json['project']?.toString(),
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category_type': categoryType,
      'project': project,
      'description': description,
    };
  }
}

// ============================================================================
// TRANSACTION MODEL
// ============================================================================
class TransactionModel {
  final String id;
  final String transactionDate;
  final String project; // CSA or CNCP
  final String transactionType; // INCOME, COMMON_EXPENSE, FIELD_EXPENSE
  final String categoryId;
  final double amount;
  final String description;
  final String createdBy;
  final String? staffId;
  final bool isSettled;
  final String? settlementId;
  final bool isDeleted;
  final String? createdAt;
  final String? categoryName;
  final String? createdByName;
  final String? staffName;
  final List<dynamic>? documents;

  const TransactionModel({
    required this.id,
    required this.transactionDate,
    required this.project,
    required this.transactionType,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.createdBy,
    this.staffId,
    required this.isSettled,
    this.settlementId,
    required this.isDeleted,
    this.createdAt,
    this.categoryName,
    this.createdByName,
    this.staffName,
    this.documents,
  });

  bool get isIncome => transactionType == 'INCOME';
  bool get isCommonExpense => transactionType == 'COMMON_EXPENSE';
  bool get isFieldExpense => transactionType == 'FIELD_EXPENSE';

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id']?.toString() ?? '',
      transactionDate: json['transaction_date']?.toString() ?? '',
      project: (json['project']?.toString() ?? 'CSA').toUpperCase(),
      transactionType: (json['transaction_type']?.toString() ?? 'COMMON_EXPENSE').toUpperCase(),
      categoryId: json['category_id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      staffId: json['staff_id']?.toString(),
      isSettled: json['is_settled'] == true,
      settlementId: json['settlement_id']?.toString(),
      isDeleted: json['is_deleted'] == true,
      createdAt: json['created_at']?.toString(),
      categoryName: json['category_name']?.toString(),
      createdByName: json['created_by_name']?.toString(),
      staffName: json['staff_name']?.toString(),
      documents: json['documents'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_date': transactionDate,
      'project': project,
      'transaction_type': transactionType,
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'created_by': createdBy,
      'staff_id': staffId,
      'is_settled': isSettled,
      'settlement_id': settlementId,
      'is_deleted': isDeleted,
      'created_at': createdAt,
      'category_name': categoryName,
      'created_by_name': createdByName,
      'staff_name': staffName,
      'documents': documents,
    };
  }
}

// ============================================================================
// SETTLEMENT MODEL
// ============================================================================
class Settlement {
  final String id;
  final String staffId;
  final String? staffName;
  final String project;
  final String monthPeriod; // e.g. "2026-11"
  final double salaryEntitlement;
  final double previousSalaryDue;
  final double totalSalaryDue;
  final double taClaimsTotal;
  final double totalDuePayable;
  final double actualAmountPaid;
  final double pendingSalaryCarryForward;
  final double? pendingTaCarryForward;
  final String paymentMode;
  final String? referenceNumber;
  final String? notes;
  final String settledBy;
  final String? settledByName;
  final String settlementDate;
  final String? createdAt;

  const Settlement({
    required this.id,
    required this.staffId,
    this.staffName,
    required this.project,
    required this.monthPeriod,
    required this.salaryEntitlement,
    required this.previousSalaryDue,
    required this.totalSalaryDue,
    required this.taClaimsTotal,
    required this.totalDuePayable,
    required this.actualAmountPaid,
    required this.pendingSalaryCarryForward,
    this.pendingTaCarryForward,
    required this.paymentMode,
    this.referenceNumber,
    this.notes,
    required this.settledBy,
    this.settledByName,
    required this.settlementDate,
    this.createdAt,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) {
    return Settlement(
      id: json['id']?.toString() ?? '',
      staffId: json['staff_id']?.toString() ?? '',
      staffName: json['staff_name']?.toString(),
      project: (json['project']?.toString() ?? 'CSA').toUpperCase(),
      monthPeriod: json['month_period']?.toString() ?? '',
      salaryEntitlement: (json['salary_entitlement'] as num?)?.toDouble() ?? 0.0,
      previousSalaryDue: (json['previous_salary_due'] as num?)?.toDouble() ?? 0.0,
      totalSalaryDue: (json['total_salary_due'] as num?)?.toDouble() ?? 0.0,
      taClaimsTotal: (json['ta_claims_total'] as num?)?.toDouble() ?? 0.0,
      totalDuePayable: (json['total_due_payable'] as num?)?.toDouble() ?? 0.0,
      actualAmountPaid: (json['actual_amount_paid'] as num?)?.toDouble() ?? 0.0,
      pendingSalaryCarryForward: (json['pending_salary_carry_forward'] as num?)?.toDouble() ?? 0.0,
      pendingTaCarryForward: (json['pending_ta_carry_forward'] as num?)?.toDouble(),
      paymentMode: json['payment_mode']?.toString() ?? 'Bank Transfer',
      referenceNumber: json['reference_number']?.toString(),
      notes: json['notes']?.toString(),
      settledBy: json['settled_by']?.toString() ?? '',
      settledByName: json['settled_by_name']?.toString(),
      settlementDate: json['settlement_date']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staff_id': staffId,
      'staff_name': staffName,
      'project': project,
      'month_period': monthPeriod,
      'salary_entitlement': salaryEntitlement,
      'previous_salary_due': previousSalaryDue,
      'total_salary_due': totalSalaryDue,
      'ta_claims_total': taClaimsTotal,
      'total_due_payable': totalDuePayable,
      'actual_amount_paid': actualAmountPaid,
      'pending_salary_carry_forward': pendingSalaryCarryForward,
      'pending_ta_carry_forward': pendingTaCarryForward,
      'payment_mode': paymentMode,
      'reference_number': referenceNumber,
      'notes': notes,
      'settled_by': settledBy,
      'settled_by_name': settledByName,
      'settlement_date': settlementDate,
      'created_at': createdAt,
    };
  }
}

// ============================================================================
// DUAL APPROVAL MODEL
// ============================================================================
class DualApproval {
  final String id;
  final String actionType;
  final String? targetTable;
  final String? targetId;
  final Map<String, dynamic>? payload;
  final String requestedBy;
  final String requesterName;
  final String actionLabel;
  final String otpCode;
  final String status; // PENDING, APPROVED, REJECTED
  final String? approvedBy;
  final String? approvalNotes;
  final String createdAt;
  final String? resolvedAt;

  const DualApproval({
    required this.id,
    required this.actionType,
    this.targetTable,
    this.targetId,
    this.payload,
    required this.requestedBy,
    required this.requesterName,
    required this.actionLabel,
    required this.otpCode,
    required this.status,
    this.approvedBy,
    this.approvalNotes,
    required this.createdAt,
    this.resolvedAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  factory DualApproval.fromJson(Map<String, dynamic> json) {
    return DualApproval(
      id: json['id']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? '',
      targetTable: json['target_table']?.toString(),
      targetId: json['target_id']?.toString(),
      payload: json['payload'] is Map<String, dynamic> ? json['payload'] as Map<String, dynamic> : null,
      requestedBy: json['requested_by']?.toString() ?? '',
      requesterName: json['requester_name']?.toString() ?? 'Team Member',
      actionLabel: json['action_label']?.toString() ?? 'Approval Request',
      otpCode: json['otp_code']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'PENDING').toUpperCase(),
      approvedBy: json['approved_by']?.toString(),
      approvalNotes: json['approval_notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      resolvedAt: json['resolved_at']?.toString(),
    );
  }
}

// ============================================================================
// DASHBOARD STATS MODEL
// ============================================================================
class DashboardStats {
  final String currentTimeIst;
  final double totalIncome;
  final double totalExpense;
  final double totalBalance;
  final double totalUnsettledTa;
  final int pendingApprovalsCount;
  final ProjectStats csa;
  final ProjectStats cncp;
  final List<ActivityFeedItem> liveFeed;

  const DashboardStats({
    required this.currentTimeIst,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalBalance,
    required this.totalUnsettledTa,
    required this.pendingApprovalsCount,
    required this.csa,
    required this.cncp,
    required this.liveFeed,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      currentTimeIst: json['current_time_ist']?.toString() ?? '',
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0.0,
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      totalUnsettledTa: (json['total_unsettled_ta'] as num?)?.toDouble() ?? 0.0,
      pendingApprovalsCount: (json['pending_approvals_count'] as num?)?.toInt() ?? 0,
      csa: ProjectStats.fromJson(json['csa'] as Map<String, dynamic>? ?? {}),
      cncp: ProjectStats.fromJson(json['cncp'] as Map<String, dynamic>? ?? {}),
      liveFeed: (json['live_feed'] as List<dynamic>? ?? [])
          .map((item) => ActivityFeedItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProjectStats {
  final double income;
  final double commonExpense;
  final double fieldExpense;
  final double totalExpense;
  final double balance;
  final double unsettledField;

  const ProjectStats({
    required this.income,
    required this.commonExpense,
    required this.fieldExpense,
    required this.totalExpense,
    required this.balance,
    required this.unsettledField,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    return ProjectStats(
      income: (json['income'] as num?)?.toDouble() ?? 0.0,
      commonExpense: (json['common_expense'] as num?)?.toDouble() ?? 0.0,
      fieldExpense: (json['field_expense'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      unsettledField: (json['unsettled_field'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ActivityFeedItem {
  final String id;
  final String summary;
  final String action;
  final String performer;
  final String timestampFormatted;

  const ActivityFeedItem({
    required this.id,
    required this.summary,
    required this.action,
    required this.performer,
    required this.timestampFormatted,
  });

  factory ActivityFeedItem.fromJson(Map<String, dynamic> json) {
    return ActivityFeedItem(
      id: json['id']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      action: json['action']?.toString() ?? 'ACTIVITY',
      performer: json['performer']?.toString() ?? 'System',
      timestampFormatted: json['timestamp_formatted']?.toString() ?? '',
    );
  }
}

// ============================================================================
// PENDING SETTLEMENT STAFF SUMMARY MODEL
// ============================================================================
class PendingSettlementStaff {
  final String staffId;
  final String staffName;
  final String project;
  final String designation;
  final String whatsappNumber;
  final double fixedSalary;
  final double previousSalaryDue;
  final int currentUnsettledTaClaimsCount;
  final double currentUnsettledTaTotal;
  final double totalDuePayable;
  final List<UnsettledClaimItem> unsettledClaims;

  const PendingSettlementStaff({
    required this.staffId,
    required this.staffName,
    required this.project,
    required this.designation,
    required this.whatsappNumber,
    required this.fixedSalary,
    required this.previousSalaryDue,
    required this.currentUnsettledTaClaimsCount,
    required this.currentUnsettledTaTotal,
    required this.totalDuePayable,
    required this.unsettledClaims,
  });

  factory PendingSettlementStaff.fromJson(Map<String, dynamic> json) {
    return PendingSettlementStaff(
      staffId: json['staff_id']?.toString() ?? '',
      staffName: json['staff_name']?.toString() ?? '',
      project: (json['project']?.toString() ?? 'CSA').toUpperCase(),
      designation: json['designation']?.toString() ?? '',
      whatsappNumber: json['whatsapp_number']?.toString() ?? '',
      fixedSalary: (json['fixed_salary'] as num?)?.toDouble() ?? 0.0,
      previousSalaryDue: (json['previous_salary_due'] as num?)?.toDouble() ?? 0.0,
      currentUnsettledTaClaimsCount: (json['current_unsettled_ta_claims_count'] as num?)?.toInt() ?? 0,
      currentUnsettledTaTotal: (json['current_unsettled_ta_total'] as num?)?.toDouble() ?? 0.0,
      totalDuePayable: (json['total_due_payable'] as num?)?.toDouble() ?? 0.0,
      unsettledClaims: (json['unsettled_claims'] as List<dynamic>? ?? [])
          .map((c) => UnsettledClaimItem.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UnsettledClaimItem {
  final String id;
  final String date;
  final double amount;
  final String description;

  const UnsettledClaimItem({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
  });

  factory UnsettledClaimItem.fromJson(Map<String, dynamic> json) {
    return UnsettledClaimItem(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
    );
  }
}

// ============================================================================
// STAFF LEDGER MODEL
// ============================================================================
class StaffLedger {
  final String staffId;
  final String staffName;
  final String project;
  final String designation;
  final String whatsappNumber;
  final double fixedSalary;
  final double currentPendingSalaryDue;
  final double totalClaimsInPeriod;
  final double totalPaidInPeriod;
  final List<LedgerEntry> entries;

  const StaffLedger({
    required this.staffId,
    required this.staffName,
    required this.project,
    required this.designation,
    required this.whatsappNumber,
    required this.fixedSalary,
    required this.currentPendingSalaryDue,
    required this.totalClaimsInPeriod,
    required this.totalPaidInPeriod,
    required this.entries,
  });

  double get netOutstanding => totalClaimsInPeriod - totalPaidInPeriod;

  factory StaffLedger.fromJson(Map<String, dynamic> json) {
    return StaffLedger(
      staffId: json['staff_id']?.toString() ?? '',
      staffName: json['staff_name']?.toString() ?? '',
      project: (json['project']?.toString() ?? 'CSA').toUpperCase(),
      designation: json['designation']?.toString() ?? '',
      whatsappNumber: json['whatsapp_number']?.toString() ?? '',
      fixedSalary: (json['fixed_salary'] as num?)?.toDouble() ?? 0.0,
      currentPendingSalaryDue: (json['current_pending_salary_due'] as num?)?.toDouble() ?? 0.0,
      totalClaimsInPeriod: (json['total_claims_in_period'] as num?)?.toDouble() ?? 0.0,
      totalPaidInPeriod: (json['total_paid_in_period'] as num?)?.toDouble() ?? 0.0,
      entries: (json['entries'] as List<dynamic>? ?? [])
          .map((e) => LedgerEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LedgerEntry {
  final String date;
  final String type;
  final String project;
  final String description;
  final double amount;
  final bool isSettled;
  final String? voucherId;
  final bool isCreditPayout;
  final Map<String, dynamic>? settlementDetails;

  const LedgerEntry({
    required this.date,
    required this.type,
    required this.project,
    required this.description,
    required this.amount,
    required this.isSettled,
    this.voucherId,
    required this.isCreditPayout,
    this.settlementDetails,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      date: json['date']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      project: (json['project']?.toString() ?? 'CSA').toUpperCase(),
      description: json['description']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isSettled: json['is_settled'] == true,
      voucherId: json['voucher_id']?.toString(),
      isCreditPayout: json['is_credit_payout'] == true,
      settlementDetails: json['settlement_details'] is Map<String, dynamic>
          ? json['settlement_details'] as Map<String, dynamic>
          : null,
    );
  }
}

// ============================================================================
// NOTIFICATION MODEL
// ============================================================================
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String notificationType;
  final String project;
  final String senderId;
  final String? relatedId;
  final bool isRead;
  final String createdAt;
  final String? createdAtFormatted;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.project,
    required this.senderId,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
    this.createdAtFormatted,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      notificationType: json['notification_type']?.toString() ?? 'INFO',
      project: json['project']?.toString() ?? 'ALL',
      senderId: json['sender_id']?.toString() ?? '',
      relatedId: json['related_id']?.toString(),
      isRead: json['is_read'] == true,
      createdAt: json['created_at']?.toString() ?? '',
      createdAtFormatted: json['created_at_formatted']?.toString(),
    );
  }
}
