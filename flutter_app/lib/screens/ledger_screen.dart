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
                Text('• Total Claims (Dr): ${formatCurrency(ledger.totalClaimsInPeriod)}'),
                Text('• Total Disbursed (Cr): ${formatCurrency(ledger.totalPaidInPeriod)}'),
                Text('• Net Statement Balance: ${formatCurrency(ledger.netOutstanding)}'),
                Text('• Current Pending Salary Due: ${formatCurrency(ledger.currentPendingSalaryDue)}'),
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
                // Staff Dropdown
                if (_isLoadingStaff)
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

          // 3 Metric Boxes: Total Claims Dr, Total Paid Cr, Net Outstanding
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Claims (Dr)',
                  value: formatCurrency(ledger.totalClaimsInPeriod),
                  color: Colors.blue.shade900,
                  subtext: 'Field TA claims',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Total Paid (Cr)',
                  value: formatCurrency(ledger.totalPaidInPeriod),
                  color: const Color(0xFF047857),
                  subtext: 'Disbursed dues',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  title: 'Net Period Diff',
                  value: formatCurrency(ledger.netOutstanding),
                  color: ledger.netOutstanding > 0 ? Colors.red.shade800 : Colors.grey.shade800,
                  subtext: 'Dr vs Cr balance',
                ),
              ),
            ],
          ),

          if (ledger.currentPendingSalaryDue > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Unpaid Carry-Forward Salary Due: ${formatCurrency(ledger.currentPendingSalaryDue)}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
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
              DataColumn(label: Text('TA Claim (Dr)')),
              DataColumn(label: Text('Paid Out (Cr)')),
              DataColumn(label: Text('Status')),
            ],
            rows: entries.map((e) {
              final isCr = e.isCreditPayout;
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
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        e.description,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      !isCr ? formatCurrency(e.amount) : '—',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: !isCr ? FontWeight.bold : FontWeight.normal,
                        color: !isCr ? Colors.blue.shade900 : Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      isCr ? formatCurrency(e.amount) : '—',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCr ? FontWeight.bold : FontWeight.normal,
                        color: isCr ? const Color(0xFF047857) : Colors.grey,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: e.isSettled ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: e.isSettled ? Colors.green.shade200 : Colors.amber.shade200,
                        ),
                      ),
                      child: Text(
                        e.isSettled ? 'Settled' : 'Unsettled',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: e.isSettled ? Colors.green.shade800 : Colors.amber.shade900,
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
