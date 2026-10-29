import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/transaction_form.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTransactions;

  const DashboardScreen({super.key, this.onNavigateToTransactions});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();

  DashboardStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _apiService.getDashboardStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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

  void _openTransactionForm({required String defaultType}) async {
    final newTx = await TransactionFormSheet.show(
      context,
      defaultType: defaultType,
    );
    if (newTx != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transaction recorded: ${newTx.project} ${formatCurrency(newTx.amount)}'),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
      refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _stats == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF047857)),
      );
    }

    if (_errorMessage != null && _stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'Unable to load dashboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: refreshData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;

    return RefreshIndicator(
      color: const Color(0xFF047857),
      onRefresh: refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IST Timestamp header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Live Metrics',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Text(
                  stats.currentTimeIst,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Consolidated Total Card
            _buildConsolidatedCard(stats),
            const SizedBox(height: 14),

            // Unsettled TA Warning Banner
            if (stats.totalUnsettledTa > 0) ...[
              _buildUnsettledTaBanner(stats.totalUnsettledTa),
              const SizedBox(height: 14),
            ],

            // Project Balances Section Title
            const Text(
              'Project Balances',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),

            // Dual Project Cards: CSA (Emerald) & CNCP (Indigo)
            Row(
              children: [
                Expanded(
                  child: _buildProjectCard(
                    title: 'CSA Project',
                    fullTitle: 'Child Support Action',
                    color: const Color(0xFF047857),
                    lightBg: const Color(0xFFECFDF5),
                    stats: stats.csa,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildProjectCard(
                    title: 'CNCP Project',
                    fullTitle: 'Child Protection',
                    color: const Color(0xFF4F46E5),
                    lightBg: const Color(0xFFEEF2FF),
                    stats: stats.cncp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Quick Action Buttons
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: '+ Grant Income',
                    color: const Color(0xFF047857),
                    onTap: () => _openTransactionForm(defaultType: 'INCOME'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.receipt_long_rounded,
                    label: '+ Office Expense',
                    color: Colors.amber.shade800,
                    onTap: () => _openTransactionForm(defaultType: 'COMMON_EXPENSE'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.directions_car_rounded,
                    label: '+ Field TA Claim',
                    color: const Color(0xFF4F46E5),
                    onTap: () => _openTransactionForm(defaultType: 'FIELD_EXPENSE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Live Activity Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live Activity Feed',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (widget.onNavigateToTransactions != null)
                  TextButton(
                    onPressed: widget.onNavigateToTransactions,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    child: const Text('View All Transactions', style: TextStyle(fontSize: 12, color: Color(0xFF047857))),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (stats.liveFeed.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Text(
                    'No activities recorded yet.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stats.liveFeed.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = stats.liveFeed[index];
                  return _buildFeedItem(item);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsolidatedCard(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark Slate
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Consolidated Balance',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'CSA + CNCP',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatCurrency(stats.totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF34D399)),
                          SizedBox(width: 4),
                          Text('Total Grants', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatCurrency(stats.totalIncome),
                        style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 26, color: Colors.white24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFFF87171)),
                          SizedBox(width: 4),
                          Text('Total Outflows', style: TextStyle(color: Colors.white60, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatCurrency(stats.totalExpense),
                        style: const TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsettledTaBanner(double unsettledAmount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unsettled Staff Field TA Claims',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatCurrency(unsettledAmount)} pending clearance in staff settlements',
                  style: TextStyle(fontSize: 11, color: Colors.amber.shade900.withOpacity(0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard({
    required String title,
    required String fullTitle,
    required Color color,
    required Color lightBg,
    required ProjectStats stats,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lightBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Icon(Icons.bar_chart_rounded, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatCurrency(stats.balance),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Available Fund Balance',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const Divider(height: 16),
          _buildMiniStat('Grants:', formatCurrency(stats.income), const Color(0xFF047857)),
          const SizedBox(height: 3),
          _buildMiniStat('Expenses:', formatCurrency(stats.totalExpense), Colors.red.shade700),
          const SizedBox(height: 3),
          _buildMiniStat('Pending TA:', formatCurrency(stats.unsettledField), Colors.amber.shade800),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color valColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: valColor)),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedItem(ActivityFeedItem item) {
    IconData actionIcon = Icons.info_outline_rounded;
    Color actionColor = const Color(0xFF047857);

    if (item.action == 'INSERT') {
      actionIcon = Icons.add_circle_outline_rounded;
      actionColor = const Color(0xFF047857);
    } else if (item.action == 'UPDATE') {
      actionIcon = Icons.edit_note_rounded;
      actionColor = Colors.amber.shade800;
    } else if (item.action == 'SOFT_DELETE') {
      actionIcon = Icons.delete_outline_rounded;
      actionColor = Colors.red.shade700;
    } else if (item.action == 'EXECUTE') {
      actionIcon = Icons.payment_rounded;
      actionColor = const Color(0xFF4F46E5);
    } else if (item.action == 'APPROVED') {
      actionIcon = Icons.verified_user_rounded;
      actionColor = const Color(0xFF047857);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(actionIcon, size: 16, color: actionColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.summary,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'By ${item.performer}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                    Text(
                      item.timestampFormatted,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
