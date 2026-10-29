import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/transaction_form.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  final _apiService = ApiService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedTypeFilter = 'ALL'; // ALL, INCOME, COMMON_EXPENSE, FIELD_EXPENSE
  String _selectedProjectFilter = 'ALL'; // ALL, CSA, CNCP
  String _searchQuery = '';

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
      final list = await _apiService.getTransactions(
        project: _selectedProjectFilter,
        transactionType: _selectedTypeFilter,
      );
      if (!mounted) return;
      setState(() {
        _transactions = list;
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

  void _openAddTransaction() async {
    final result = await TransactionFormSheet.show(
      context,
      defaultProject: _selectedProjectFilter != 'ALL' ? _selectedProjectFilter : 'CSA',
      defaultType: _selectedTypeFilter != 'ALL' ? _selectedTypeFilter : 'COMMON_EXPENSE',
    );
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ${result.project} ${formatCurrency(result.amount)}'),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
      refreshData();
    }
  }

  void _openEditTransaction(TransactionModel tx) async {
    final result = await TransactionFormSheet.show(
      context,
      transaction: tx,
    );
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction updated successfully'),
          backgroundColor: Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );
      refreshData();
    }
  }

  void _confirmDelete(TransactionModel tx) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ${formatCurrency(tx.amount)} (${tx.description})?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Deletion',
                hintText: 'e.g. Duplicate entry',
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
                await _apiService.deleteTransaction(tx.id, reason: reason);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction deleted successfully'),
                    backgroundColor: Colors.red,
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Client-side search query filtering
    final filtered = _transactions.where((t) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final desc = t.description.toLowerCase();
      final cat = (t.categoryName ?? '').toLowerCase();
      final staff = (t.staffName ?? t.createdByName ?? '').toLowerCase();
      return desc.contains(query) || cat.contains(query) || staff.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Filter Chips and Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search description, category, staff...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 10),

                // Type filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Project chips
                      _buildChip('All Projects', _selectedProjectFilter == 'ALL', () {
                        setState(() => _selectedProjectFilter = 'ALL');
                        refreshData();
                      }),
                      const SizedBox(width: 6),
                      _buildChip('CSA Project', _selectedProjectFilter == 'CSA', () {
                        setState(() => _selectedProjectFilter = 'CSA');
                        refreshData();
                      }, color: const Color(0xFF047857)),
                      const SizedBox(width: 6),
                      _buildChip('CNCP Project', _selectedProjectFilter == 'CNCP', () {
                        setState(() => _selectedProjectFilter = 'CNCP');
                        refreshData();
                      }, color: const Color(0xFF4F46E5)),
                      const SizedBox(width: 12),
                      Container(width: 1, height: 20, color: Colors.grey.shade300),
                      const SizedBox(width: 12),

                      // Transaction Type chips
                      _buildChip('All Types', _selectedTypeFilter == 'ALL', () {
                        setState(() => _selectedTypeFilter = 'ALL');
                        refreshData();
                      }),
                      const SizedBox(width: 6),
                      _buildChip('Grants', _selectedTypeFilter == 'INCOME', () {
                        setState(() => _selectedTypeFilter = 'INCOME');
                        refreshData();
                      }, color: const Color(0xFF047857)),
                      const SizedBox(width: 6),
                      _buildChip('Office Exp', _selectedTypeFilter == 'COMMON_EXPENSE', () {
                        setState(() => _selectedTypeFilter = 'COMMON_EXPENSE');
                        refreshData();
                      }, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      _buildChip('Staff TA', _selectedTypeFilter == 'FIELD_EXPENSE', () {
                        setState(() => _selectedTypeFilter = 'FIELD_EXPENSE');
                        refreshData();
                      }, color: Colors.blue.shade800),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Transaction List
          Expanded(
            child: _isLoading && _transactions.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF047857)))
                : _errorMessage != null && _transactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: refreshData, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No transactions found.',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF047857),
                            onRefresh: refreshData,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final tx = filtered[index];
                                return _buildTransactionCard(tx);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        backgroundColor: const Color(0xFF047857),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onTap, {Color? color}) {
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
      onSelected: (_) => onTap(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    final isCsa = tx.project == 'CSA';
    final projectColor = isCsa ? const Color(0xFF047857) : const Color(0xFF4F46E5);

    Color typeColor;
    String typeLabel;
    IconData typeIcon;

    if (tx.isIncome) {
      typeColor = const Color(0xFF047857);
      typeLabel = 'Grant Inflow';
      typeIcon = Icons.arrow_downward_rounded;
    } else if (tx.isCommonExpense) {
      typeColor = Colors.amber.shade900;
      typeLabel = 'Office Expense';
      typeIcon = Icons.arrow_upward_rounded;
    } else {
      typeColor = Colors.blue.shade800;
      typeLabel = 'Field TA';
      typeIcon = Icons.directions_car_rounded;
    }

    final isMine = _apiService.currentUser?.id == tx.createdBy;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Project Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: projectColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tx.project,
                      style: TextStyle(color: projectColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(typeIcon, size: 12, color: typeColor),
                        const SizedBox(width: 4),
                        Text(
                          typeLabel,
                          style: TextStyle(color: typeColor, fontWeight: FontWeight.w600, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (tx.isFieldExpense) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: tx.isSettled ? Colors.green.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: tx.isSettled ? Colors.green.shade200 : Colors.amber.shade200,
                        ),
                      ),
                      child: Text(
                        tx.isSettled ? 'Settled' : 'Pending Claim',
                        style: TextStyle(
                          color: tx.isSettled ? Colors.green.shade800 : Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Date
              Text(
                formatDateDisplay(tx.transactionDate),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Amount & Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.categoryName ?? 'Project Transaction',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                (tx.isIncome ? '+ ' : '- ') + formatCurrency(tx.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: tx.isIncome ? const Color(0xFF047857) : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const Divider(height: 16),

          // Footer Row: Staff name & Actions (Edit/Delete)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    tx.staffName != null
                        ? 'Staff: ${tx.staffName}'
                        : 'By ${tx.createdByName ?? "Staff"}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                children: [
                  // Edit Button
                  InkWell(
                    onTap: () => _openEditTransaction(tx),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 14, color: Colors.grey.shade700),
                          const SizedBox(width: 3),
                          Text('Edit', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Delete Button
                  InkWell(
                    onTap: () => _confirmDelete(tx),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 14, color: Colors.red.shade700),
                          const SizedBox(width: 3),
                          Text('Delete', style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
