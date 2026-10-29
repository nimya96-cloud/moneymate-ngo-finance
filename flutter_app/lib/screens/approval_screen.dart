import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => ApprovalScreenState();
}

class ApprovalScreenState extends State<ApprovalScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();

  late TabController _tabController;

  List<DualApproval> _approvals = [];
  List<Staff> _allStaff = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final approvalsFuture = _apiService.getApprovals();
      final staffFuture = _apiService.getStaff();

      final results = await Future.wait([approvalsFuture, staffFuture]);

      if (!mounted) return;
      setState(() {
        _approvals = results[0] as List<DualApproval>;
        _allStaff = results[1] as List<Staff>;
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

  void _showResolveDialog(DualApproval approval, String decision) {
    final isCurrentUserRequester = _apiService.currentUser?.id == approval.requestedBy;

    if (isCurrentUserRequester) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.amber),
              SizedBox(width: 8),
              Text('Security Rule Violation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Dual-Approval Security Rule:\nYou cannot approve or reject your own request! Another active staff member must verify and approve it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
      return;
    }

    final pinController = TextEditingController();
    final notesController = TextEditingController();
    final isApprove = decision == 'APPROVED';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.verified_user_rounded : Icons.cancel_outlined,
              color: isApprove ? const Color(0xFF047857) : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              isApprove ? 'Confirm Approval' : 'Confirm Rejection',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${isApprove ? "Approving" : "Rejecting"}: ${approval.actionLabel}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Text(
                'Verification OTP: ${approval.otpCode}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Your 6-Digit Security PIN',
                hintText: '123456',
                counterText: '',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Approval Notes (Optional)',
                hintText: 'Verified credentials',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.isEmpty) return;
              Navigator.of(ctx).pop();

              try {
                await _apiService.resolveApproval(
                  approvalId: approval.id,
                  decision: decision,
                  pin: pin,
                  notes: notesController.text.trim(),
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request marked as $decision'),
                    backgroundColor: isApprove ? const Color(0xFF047857) : Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                refreshData();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red.shade900,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? const Color(0xFF047857) : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _showRelieveStaffDialog(Staff staff) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Relieve Staff Member', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Initiate relieving / exit process for ${staff.fullName} (${staff.designation} - ${staff.project})?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'A dual-approval request with OTP will be dispatched to peer coordinators.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason for Relieving',
                hintText: 'e.g. Contract completed / Resignation submitted',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.of(ctx).pop();

              try {
                final res = await _apiService.requestRelieveStaff(
                  targetStaffId: staff.id,
                  reason: reason,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message']?.toString() ?? 'Relieving request initiated with OTP'),
                    backgroundColor: const Color(0xFF047857),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                refreshData();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red.shade900,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _approvals.where((a) => a.isPending).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Sub-Tab Switcher
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF047857),
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Dual Approvals'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$pendingCount',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: 'Staff Directory'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Tab Views
          Expanded(
            child: _isLoading && _approvals.isEmpty && _allStaff.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF047857)))
                : _errorMessage != null && _approvals.isEmpty
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
                        controller: _tabController,
                        children: [
                          _buildApprovalsTab(),
                          _buildStaffDirectoryTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsTab() {
    if (_approvals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 52, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'No dual approval requests.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 4),
            Text('All staff on-boarding and relieving actions are resolved.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF047857),
      onRefresh: refreshData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        itemCount: _approvals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _approvals[index];
          return _buildApprovalCard(item);
        },
      ),
    );
  }

  Widget _buildApprovalCard(DualApproval item) {
    Color statusColor;
    IconData statusIcon;

    if (item.isPending) {
      statusColor = Colors.amber.shade800;
      statusIcon = Icons.hourglass_top_rounded;
    } else if (item.isApproved) {
      statusColor = const Color(0xFF047857);
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = Colors.red.shade700;
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPending ? Colors.amber.shade300 : Colors.grey.shade200,
          width: item.isPending ? 1.5 : 1,
        ),
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
          // Header with status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      item.status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Text(
                formatDateDisplay(item.createdAt),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Action Label & Requester
          Text(
            item.actionLabel,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            'Requested by: ${item.requesterName}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),

          // OTP Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Verification OTP:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                Text(
                  item.otpCode,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),

          if (item.approvalNotes != null && item.approvalNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${item.approvalNotes}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ],

          // Action Buttons if PENDING
          if (item.isPending) ...[
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showResolveDialog(item, 'REJECTED'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showResolveDialog(item, 'APPROVED'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Approve with PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStaffDirectoryTab() {
    return RefreshIndicator(
      color: const Color(0xFF047857),
      onRefresh: refreshData,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
        itemCount: _allStaff.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final staff = _allStaff[index];
          final isCsa = staff.project == 'CSA';
          final projectColor = isCsa ? const Color(0xFF047857) : const Color(0xFF4F46E5);
          final isSelf = _apiService.currentUser?.id == staff.id;

          Color statusColor;
          if (staff.isActive) {
            statusColor = Colors.green.shade700;
          } else if (staff.isPendingApproval) {
            statusColor = Colors.amber.shade800;
          } else {
            statusColor = Colors.red.shade700;
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: projectColor.withOpacity(0.12),
                          child: Text(
                            staff.fullName.isNotEmpty ? staff.fullName[0] : 'S',
                            style: TextStyle(color: projectColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  staff.fullName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                ),
                                if (isSelf) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF047857).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('You', style: TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              '${staff.designation} (${staff.project})',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        staff.status,
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('WhatsApp: +91 ${staff.whatsappNumber}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    Text('Fixed Salary: ${formatCurrency(staff.fixedSalary)}/mo', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),

                // Relieve staff button for ACTIVE colleagues
                if (staff.isActive && !isSelf) ...[
                  const Divider(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _showRelieveStaffDialog(staff),
                      icon: const Icon(Icons.person_remove_outlined, size: 14, color: Colors.red),
                      label: const Text('Relieve Staff', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
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
