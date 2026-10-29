import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class SettlementFormSheet extends StatefulWidget {
  final PendingSettlementStaff staff;

  const SettlementFormSheet({super.key, required this.staff});

  static Future<Settlement?> show(
    BuildContext context, {
    required PendingSettlementStaff staff,
  }) {
    return showModalBottomSheet<Settlement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SettlementFormSheet(staff: staff),
    );
  }

  @override
  State<SettlementFormSheet> createState() => _SettlementFormSheetState();
}

class _SettlementFormSheetState extends State<SettlementFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late TextEditingController _monthPeriodController;
  late TextEditingController _salaryEntitlementController;
  late TextEditingController _taClaimsController;
  late TextEditingController _actualPaidController;
  late TextEditingController _referenceController;
  late TextEditingController _notesController;

  String _paymentMode = 'Bank Transfer';
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final currentMonth = DateFormat('yyyy-MM').format(now);

    _monthPeriodController = TextEditingController(text: currentMonth);
    _salaryEntitlementController = TextEditingController(
      text: widget.staff.fixedSalary.toStringAsFixed(2),
    );
    _taClaimsController = TextEditingController(
      text: widget.staff.currentUnsettledTaTotal.toStringAsFixed(2),
    );
    // Default actual paid is the total due payable
    _actualPaidController = TextEditingController(
      text: widget.staff.totalDuePayable.toStringAsFixed(2),
    );
    _referenceController = TextEditingController();
    _notesController = TextEditingController();

    _actualPaidController.addListener(() => setState(() {}));
    _salaryEntitlementController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _monthPeriodController.dispose();
    _salaryEntitlementController.dispose();
    _taClaimsController.dispose();
    _actualPaidController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _currentSalaryEntitlement =>
      double.tryParse(_salaryEntitlementController.text.trim()) ?? widget.staff.fixedSalary;

  double get _currentTaClaims =>
      double.tryParse(_taClaimsController.text.trim()) ?? widget.staff.currentUnsettledTaTotal;

  double get _currentActualPaid =>
      double.tryParse(_actualPaidController.text.trim()) ?? 0.0;

  double get _calculatedTotalDue {
    return _currentSalaryEntitlement + widget.staff.previousSalaryDue + _currentTaClaims;
  }

  double get _calculatedPaidTowardsTa {
    return _currentActualPaid < _currentTaClaims ? _currentActualPaid : _currentTaClaims;
  }

  double get _calculatedRemainingForSalary {
    final rem = _currentActualPaid - _calculatedPaidTowardsTa;
    return rem > 0 ? rem : 0.0;
  }

  double get _calculatedCarryForwardSalary {
    final totalSalaryEntitlement = _currentSalaryEntitlement + widget.staff.previousSalaryDue;
    final diff = totalSalaryEntitlement - _calculatedRemainingForSalary;
    return diff > 0 ? diff : 0.0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final settlement = await _apiService.executeSettlement(
        staffId: widget.staff.staffId,
        project: widget.staff.project,
        monthPeriod: _monthPeriodController.text.trim(),
        salaryEntitlement: _currentSalaryEntitlement,
        accumulatedTaClaims: _currentTaClaims,
        actualAmountPaidNow: _currentActualPaid,
        paymentMode: _paymentMode,
        referenceNumber: _referenceController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(settlement);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCsa = widget.staff.project.toUpperCase() == 'CSA';
    final projectColor = isCsa ? const Color(0xFF047857) : const Color(0xFF4F46E5);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: projectColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded, color: projectColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Execute Staff Settlement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${widget.staff.staffName} (${widget.staff.designation})',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: projectColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.staff.project,
                        style: TextStyle(
                          color: projectColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Dues Breakdown Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDueRow('Monthly Fixed Salary', formatCurrency(_currentSalaryEntitlement)),
                      const SizedBox(height: 6),
                      _buildDueRow(
                        'Previous Unpaid Due',
                        formatCurrency(widget.staff.previousSalaryDue),
                        valueColor: widget.staff.previousSalaryDue > 0 ? Colors.red.shade700 : null,
                      ),
                      const SizedBox(height: 6),
                      _buildDueRow(
                        'Pending Field TA (${widget.staff.currentUnsettledTaClaimsCount} claims)',
                        formatCurrency(_currentTaClaims),
                        valueColor: Colors.amber.shade900,
                      ),
                      const Divider(height: 16),
                      _buildDueRow(
                        'Total Payable Entitlement',
                        formatCurrency(_calculatedTotalDue),
                        isBold: true,
                        valueColor: projectColor,
                        fontSize: 15,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Month Period & Mode
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Period (YYYY-MM)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _monthPeriodController,
                            decoration: InputDecoration(
                              hintText: '2026-10',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Enter period';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Mode',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _paymentMode,
                                items: const [
                                  DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                                  DropdownMenuItem(value: 'UPI Transfer', child: Text('UPI Transfer')),
                                  DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                                  DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _paymentMode = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Actual Paid Now Input (Variable Payout)
                const Text(
                  'Actual Amount Paid Now (₹)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _actualPaidController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    hintText: '0.00',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Enter payout amount';
                    final num = double.tryParse(val.trim());
                    if (num == null || num < 0) return 'Invalid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Quick Payout Options
                Wrap(
                  spacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Pay Full Due', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        setState(() {
                          _actualPaidController.text = _calculatedTotalDue.toStringAsFixed(2);
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Only Clear TA', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        setState(() {
                          _actualPaidController.text = _currentTaClaims.toStringAsFixed(2);
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Only Fixed Salary', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        setState(() {
                          _actualPaidController.text = _currentSalaryEntitlement.toStringAsFixed(2);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Carry Forward Live Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _calculatedCarryForwardSalary > 0 ? Colors.amber.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _calculatedCarryForwardSalary > 0 ? Colors.amber.shade300 : Colors.green.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _calculatedCarryForwardSalary > 0 ? Icons.info_outline_rounded : Icons.check_circle_rounded,
                            size: 18,
                            color: _calculatedCarryForwardSalary > 0 ? Colors.amber.shade900 : Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _calculatedCarryForwardSalary > 0
                                ? 'Partial Payment: Salary Carry-Forward'
                                : 'Full Settlement (Zero Carry-Forward)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _calculatedCarryForwardSalary > 0 ? Colors.amber.shade900 : Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Clears TA Claims: ${formatCurrency(_calculatedPaidTowardsTa)}'
                        '\n• Clears Salary: ${formatCurrency(_calculatedRemainingForSalary)}'
                        '${_calculatedCarryForwardSalary > 0 ? '\n• Unpaid Salary Carry Forward to Next Month: ${formatCurrency(_calculatedCarryForwardSalary)}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _calculatedCarryForwardSalary > 0 ? Colors.amber.shade900 : Colors.green.shade800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Reference / UTR
                const Text(
                  'Reference / UTR Number',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _referenceController,
                  decoration: InputDecoration(
                    hintText: 'e.g. UTR20261029000123',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                const Text(
                  'Remarks / Notes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'e.g. Cleared October salary with 3 field trip TA vouchers',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF047857),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Disburse ${formatCurrency(_currentActualPaid)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDueRow(String label, String value, {bool isBold = false, Color? valueColor, double fontSize = 13}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
