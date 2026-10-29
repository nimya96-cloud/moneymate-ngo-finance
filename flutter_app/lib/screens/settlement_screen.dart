import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/settlement_form.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => SettlementScreenState();
}

class SettlementScreenState extends State<SettlementScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();

  late TabController _subTabController;

  List<PendingSettlementStaff> _pendingStaff = [];
  List<Settlement> _settlementHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedProjectFilter = 'ALL'; // ALL, CSA, CNCP

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    refreshData();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pendingFuture = _apiService.getPendingSettlementSummary(project: _selectedProjectFilter);
      final historyFuture = _apiService.getSettlements(project: _selectedProjectFilter);

      final results = await Future.wait([pendingFuture, historyFuture]);

      if (!mounted) return;
      setState(() {
        _pendingStaff = results[0] as List<PendingSettlementStaff>;
        _settlementHistory = results[1] as List<Settlement>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _openSettlementModal(PendingSettlementStaff staff) async {
    final result = await SettlementFormSheet.show(context, staff: staff);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Settlement recorded: Disbursed ${formatCurrency(result.actualAmountPaid)} to ${result.staffName ?? staff.staffName}'),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
      refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Sub-Tab Switcher & Project Filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: [
                // 2 Tabs: Pending Dues & History
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: TabBar(
                    controller: _subTabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF047857),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    tabs: const [
                      Tab(text: 'Pending Staff Dues'),
                      Tab(text: 'Settlement History'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Project Filter Chips
                Row(
                  children: [
                    const Text('Project: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 4),
                    _buildProjectChip('All', 'ALL'),
                    const SizedBox(width: 6),
                    _buildProjectChip('CSA Only', 'CSA', color: const Color(0xFF047857)),
                    const SizedBox(width: 6),
                    _buildProjectChip('CNCP Only', 'CNCP', color: const Color(0xFF4F46E5)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Content Tab Views
          Expanded(
            child: _isLoading && _pendingStaff.isEmpty && _settlementHistory.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF047857)))
                : _errorMessage != null && _pendingStaff.isEmpty
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
                    : TabBarView(
                        controller: _subTabController,
                        children: [
                          _buildPendingStaffTab(),
                          _buildHistoryTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectChip(String label, String code, {Color? color}) {
    final isSelected = _selectedProjectFilter == code;
    final activeColor = color ?? const Color(0xFF1E293B);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: activeColor.withOpacity(0.15),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? activeColor : Colors.grey.shade700,
      ),
      onSelected: (val) {
        if (val) {
          setState(() => _selectedProjectFilter = code);
          refreshData();
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildPendingStaffTab() {
    if (_pendingStaff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.shade400),
            const SizedBox(height: 12),
            const Text(
              'All staff accounts are settled!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text('No pending claims or unpaid balances found.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF047857),
      onRefresh: refreshData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        itemCount: _pendingStaff.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final staff = _pendingStaff[index];
          return _buildStaffSettlementCard(staff);
        },
      ),
    );
  }

  Widget _buildStaffSettlementCard(PendingSettlementStaff staff) {
    final isCsa = staff.project == 'CSA';
    final projectColor = isCsa ? const Color(0xFF047857) : const Color(0xFF4F46E5);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: projectColor.withOpacity(0.12),
                    child: Text(
                      staff.staffName.isNotEmpty ? staff.staffName[0] : 'S',
                      style: TextStyle(color: projectColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.staffName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        staff.designation,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: projectColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  staff.project,
                  style: TextStyle(color: projectColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Details Grid
          Row(
            children: [
              Expanded(
                child: _buildDetailCell('Fixed Salary', formatCurrency(staff.fixedSalary), const Color(0xFF1E293B)),
              ),
              Expanded(
                child: _buildDetailCell(
                  'Carry-Forward Due',
                  formatCurrency(staff.previousSalaryDue),
                  staff.previousSalaryDue > 0 ? Colors.red.shade700 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDetailCell(
                  'Field TA Claims (${staff.currentUnsettledTaClaimsCount})',
                  formatCurrency(staff.currentUnsettledTaTotal),
                  Colors.amber.shade900,
                ),
              ),
              Expanded(
                child: _buildDetailCell(
                  'Total Due Payable',
                  formatCurrency(staff.totalDuePayable),
                  projectColor,
                  isBold: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Settle Monthly Dues Button
          ElevatedButton.icon(
            onPressed: () => _openSettlementModal(staff),
            icon: const Icon(Icons.payment_rounded, size: 16),
            label: Text('Execute Settlement (${formatCurrency(staff.totalDuePayable)})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: projectColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCell(String label, String value, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    if (_settlementHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No past settlements found.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF047857),
      onRefresh: refreshData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        itemCount: _settlementHistory.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final s = _settlementHistory[index];
          final isCsa = s.project == 'CSA';
          final color = isCsa ? const Color(0xFF047857) : const Color(0xFF4F46E5);

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.project,
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Period: ${s.monthPeriod}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formatDateDisplay(s.settlementDate),
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.staffName ?? 'Staff Member',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          'Mode: ${s.paymentMode}${s.referenceNumber != null && s.referenceNumber!.isNotEmpty ? " (Ref: ${s.referenceNumber})" : ""}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatCurrency(s.actualAmountPaid),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                        ),
                        Text(
                          'of ${formatCurrency(s.totalDuePayable)} due',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),

                if (s.pendingSalaryCarryForward > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      'Unpaid Carry-Forward: ${formatCurrency(s.pendingSalaryCarryForward)} remaining for next month',
                      style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
