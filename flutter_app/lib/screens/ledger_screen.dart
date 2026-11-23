import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class LedgerScreen extends StatefulWidget {
  final String? initialStaffId;

  const LedgerScreen({super.key, this.initialStaffId});

  @override
  State<LedgerScreen> createState() => LedgerScreenState();
}

class LedgerScreenState extends State<LedgerScreen> {
  final _apiService = ApiService();

  List<Staff> _staffList = [];
  String? _selectedStaffId;
  DateTime? _startDate;
  DateTime? _endDate;

  StaffLedger? _ledger;
  bool _isLoadingStaff = true;
  bool _isLoadingLedger = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingStaff = true;
      _errorMessage = null;
    });

    try {
      final staff = await _apiService.getStaff();
      if (!mounted) return;
      setState(() {
        _staffList = staff.where((s) => s.isActive).toList();
        _isLoadingStaff = false;

        if (_staffList.isNotEmpty) {
          _selectedStaffId = widget.initialStaffId ??
              (_apiService.currentUser != null && _staffList.any((s) => s.id == _apiService.currentUser!.id)
                  ? _apiService.currentUser!.id
                  : _staffList.first.id);
        }
      });

      if (_selectedStaffId != null) {
        refreshData();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingStaff = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> refreshData() async {
    if (_selectedStaffId == null) return;

    setState(() {
      _isLoadingLedger = true;
      _errorMessage = null;
    });

    try {
      final startStr = _startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : null;
      final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

      final ledger = await _apiService.getStaffLedger(
        staffId: _selectedStaffId!,
        startDate: startStr,
        endDate: endStr,
      );

      if (!mounted) return;
      setState(() {
        _ledger = ledger;
        _isLoadingLedger = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLedger = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
      refreshData();
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
      refreshData();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    refreshData();
  }

  void _showPrintPreview(StaffLedger ledger) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.print_outlined, color: Color(0xFF047857)),
            const SizedBox(width: 8),
            Text('${ledger.staffName} Ledger Statement', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'MoneyMate NGO Financial System',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade700),
                ),
                Text('Project: ${ledger.project} | Role: ${ledger.designation}', style: const TextStyle(fontSize: 12)),
                Text('Phone: +91 ${ledger.whatsappNumber}', style: const TextStyle(fontSize: 12)),
                const Divider(height: 16),
                Text('Statement Summary:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('• Total Entitlement & Claims (Dr): ${formatCurrency(ledger.totalDueInPeriod > 0 ? ledger.totalDueInPeriod : ledger.totalClaimsInPeriod)}'),
                Text('• Total Disbursed (Cr): ${formatCurrency(ledger.totalPaidInPeriod)}'),
                Text('• Total Current Pending Due: ${formatCurrency(ledger.totalCurrentPendingDue)}'),
                if (ledger.currentPendingSalaryDue > 0)
                  Text('  - Pending Salary Carry-Forward: ${formatCurrency(ledger.currentPendingSalaryDue)}'),
                if (ledger.currentPendingTaDue > 0)
                  Text('  - Pending Field TA Claims: ${formatCurrency(ledger.currentPendingTaDue)}'),
                const Divider(height: 16),
                Text('Total Entries: ${ledger.entries.length} transactions included.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ledger statement prepared for printing / PDF export.'),
                  backgroundColor: Color(0xFF047857),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Export PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Filter Controls Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Staff Selector: locked to logged-in user for regular staff, selectable for admin/treasurer
                if (_apiService.currentUser != null && !_apiService.currentUser!.isCoordinator)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, size: 22, color: Color(0xFF047857)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Salary & TA Ledger: ${_apiService.currentUser!.fullName}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                              Text(
                                '${_apiService.currentUser!.designation} • ${_apiService.currentUser!.project} Project',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.lock, size: 12, color: Color(0xFF475569)),
                              SizedBox(width: 4),
                              Text(
                                'My Account',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_isLoadingStaff)
                  const Center(child: LinearProgressIndicator(color: Color(0xFF047857)))
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedStaffId,
                        hint: const Text('Select Staff Member'),
                        items: _staffList.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.id,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (s.project == 'CSA' ? const Color(0xFF047857) : const Color(0xFF4F46E5))
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s.project,
                                    style: TextStyle(
                                      color: s.project == 'CSA' ? const Color(0xFF047857) : const Color(0xFF4F46E5),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${s.fullName} (${s.designation})',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId != null) {
                            setState(() => _selectedStaffId = newId);
                            refreshData();
                          }
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 10),

                // Date pickers row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickStartDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF047857)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _startDate != null ? DateFormat('dd MMM yyyy').format(_startDate!) : 'From Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _startDate != null ? FontWeight.bold : FontWeight.normal,
                                    color: _startDate != null ? const Color(0xFF1E293B) : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: _pickEndDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Color(0xFF047857)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : 'To Date',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: _endDate != null ? FontWeight.bold : FontWeight.normal,
                                    color: _endDate != null ? const Color(0xFF1E293B) : Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_startDate != null || _endDate != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                        onPressed: _clearDateFilter,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Clear Date Filter',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Ledger Content
          Expanded(
            child: _isLoadingLedger && _ledger == null
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF047857)))
                : _errorMessage != null && _ledger == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: refreshData, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _ledger == null
                        ? const Center(child: Text('Select a staff member to view ledger'))
                        : RefreshIndicator(
                            color: const Color(0xFF047857),
                            onRefresh: refreshData,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Summary Section Card
                                  _buildSummarySection(_ledger!),
                                  const SizedBox(height: 16),

                                  // Header for Table
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Ledger Statement Entries',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _showPrintPreview(_ledger!),
                                        icon: const Icon(Icons.print_rounded, size: 14),
                                        label: const Text('Print / Share', style: TextStyle(fontSize: 11)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF047857),
                                          side: const BorderSide(color: Color(0xFF047857)),
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Table Card
                                  if (_ledger!.entries.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No ledger entries found for the selected period.',
                                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                        ),
                                      ),
                                    )
                                  else
                                    _buildLedgerTable(_ledger!.entries),
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(StaffLedger ledger) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ledger.staffName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  Text(
                    '${ledger.designation} (${ledger.project})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Salary: ${formatCurrency(ledger.fixedSalary)}/mo',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // 3 Metric Boxes: Total Entitlements Dr, Total Paid Cr, Pending Due
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Entitled & Claims (Dr)',
                  value: formatCurrency(ledger.totalDueInPeriod > 0 ? ledger.totalDueInPeriod : ledger.totalClaimsInPeriod),
                  color: Colors.blue.shade900,
                  subtext: 'Salary + TA dues',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Disbursed (Cr)',
                  value: formatCurrency(ledger.totalPaidInPeriod),
                  color: const Color(0xFF047857),
                  subtext: 'Amount paid',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Pending Due (ബാക്കി)',
                  value: formatCurrency(ledger.totalCurrentPendingDue),
                  color: ledger.totalCurrentPendingDue > 0 ? Colors.red.shade800 : const Color(0xFF047857),
                  subtext: ledger.totalCurrentPendingDue > 0 ? 'Remaining payable' : 'Fully settled',
                ),
              ),
            ],
          ),

          if (ledger.totalCurrentPendingDue > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, size: 18, color: Colors.amber.shade900),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ആകെ നൽകാൻ ബാക്കി: ${formatCurrency(ledger.totalCurrentPendingDue)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (ledger.currentPendingSalaryDue > 0)
                    Text(
                      '• Carry-Forward Salary Due: ${formatCurrency(ledger.currentPendingSalaryDue)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                    ),
                  if (ledger.currentPendingTaDue > 0)
                    Text(
                      '• Pending Field TA Claims: ${formatCurrency(ledger.currentPendingTaDue)}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'ഫണ്ട് വരുന്ന മുറയ്ക്ക് അതാത് മാസം വരെയുള്ള ബാക്കി തുക അനുവദിക്കുന്നതാണ്.',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Dues Fully Settled (No Pending Balance)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(subtext, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildLedgerTable(List<LedgerEntry> entries) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
            horizontalMargin: 12,
            columnSpacing: 16,
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
            columns: const [
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Particulars')),
              DataColumn(label: Text('Entitled / Claim (Dr)')),
              DataColumn(label: Text('Paid Out (Cr)')),
              DataColumn(label: Text('Pending Balance')),
              DataColumn(label: Text('Status')),
            ],
            rows: entries.map((e) {
              final isCr = e.isCreditPayout;
              final isDue = e.dueAmount > 0;
              final isPaid = e.paidAmount > 0;
              final isSettled = e.isSettled;

              Color statusBg = isSettled ? Colors.green.shade50 : Colors.amber.shade50;
              Color statusBorder = isSettled ? Colors.green.shade200 : Colors.amber.shade200;
              Color statusText = isSettled ? Colors.green.shade800 : Colors.amber.shade900;

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      formatDateDisplay(e.date),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            e.description,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          Text(
                            e.type,
                            style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      isDue ? formatCurrency(e.dueAmount) : '—',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isDue ? FontWeight.bold : FontWeight.normal,
                        color: isDue ? Colors.blue.shade900 : Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      isPaid ? formatCurrency(e.paidAmount) : '—',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isPaid ? FontWeight.bold : FontWeight.normal,
                        color: isPaid ? const Color(0xFF047857) : Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      formatCurrency(e.runningBalance),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: e.runningBalance > 0 ? Colors.red.shade800 : const Color(0xFF047857),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusBorder),
                      ),
                      child: Text(
                        e.status.isNotEmpty ? e.status : (isSettled ? 'Settled' : 'Pending'),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: statusText,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
