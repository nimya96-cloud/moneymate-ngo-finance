import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class TransactionFormSheet extends StatefulWidget {
  final TransactionModel? initialTransaction;
  final String? initialProject; // 'CSA' or 'CNCP'
  final String? initialType; // 'INCOME', 'COMMON_EXPENSE', 'FIELD_EXPENSE'

  const TransactionFormSheet({
    super.key,
    this.initialTransaction,
    this.initialProject,
    this.initialType,
  });

  static Future<TransactionModel?> show(
    BuildContext context, {
    TransactionModel? transaction,
    String? defaultProject,
    String? defaultType,
  }) {
    return showModalBottomSheet<TransactionModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionFormSheet(
        initialTransaction: transaction,
        initialProject: defaultProject,
        initialType: defaultType,
      ),
    );
  }

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  late String _selectedProject;
  late String _selectedType;
  String? _selectedCategoryId;
  String? _selectedStaffId;

  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;

  List<Category> _allCategories = [];
  List<Staff> _allStaff = [];
  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final tx = widget.initialTransaction;

    _selectedProject = tx?.project ?? widget.initialProject ?? 'CSA';
    _selectedType = tx?.transactionType ?? widget.initialType ?? 'COMMON_EXPENSE';
    _selectedCategoryId = tx?.categoryId;
    _selectedStaffId = tx?.staffId ?? _apiService.currentUser?.id;

    _amountController = TextEditingController(
      text: tx != null ? tx.amount.toStringAsFixed(2) : '',
    );
    _descriptionController = TextEditingController(
      text: tx?.description ?? '',
    );

    if (tx != null && tx.transactionDate.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(tx.transactionDate);
      } catch (_) {
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
    }

    _loadFormData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final cats = await _apiService.getCategories();
      final staffList = await _apiService.getStaff();

      if (!mounted) return;
      setState(() {
        _allCategories = cats;
        _allStaff = staffList.where((s) => s.isActive).toList();
        _isLoadingData = false;

        // Auto-select valid category if not already set or invalid
        final filteredCats = _getFilteredCategories();
        if (_selectedCategoryId == null || !filteredCats.any((c) => c.id == _selectedCategoryId)) {
          if (filteredCats.isNotEmpty) {
            _selectedCategoryId = filteredCats.first.id;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingData = false;
        _errorMessage = e.toString();
      });
    }
  }

  List<Category> _getFilteredCategories() {
    return _allCategories.where((c) {
      return c.categoryType == _selectedType;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF047857),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      setState(() => _errorMessage = 'Please select a category');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final desc = _descriptionController.text.trim();

      TransactionModel result;
      if (widget.initialTransaction != null) {
        result = await _apiService.updateTransaction(
          widget.initialTransaction!.id,
          amount: amount,
          description: desc,
          transactionDate: dateStr,
          categoryId: _selectedCategoryId,
        );
      } else {
        result = await _apiService.createTransaction(
          project: _selectedProject,
          transactionType: _selectedType,
          categoryId: _selectedCategoryId!,
          amount: amount,
          transactionDate: dateStr,
          description: desc,
          staffId: _selectedType == 'FIELD_EXPENSE' ? _selectedStaffId : null,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(result);
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
    final isEditing = widget.initialTransaction != null;
    final filteredCategories = _getFilteredCategories();

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

                // Sheet Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                        color: const Color(0xFF047857),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Edit Transaction' : 'Record Transaction',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'Update existing project entry'
                                : 'Grant Inflow, Common Office Expense, or Staff TA Claim',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
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

                if (_isLoadingData)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF047857)),
                    ),
                  )
                else ...[
                  // 1. Project Segmented Switch
                  const Text(
                    'Project',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _ProjectOptionCard(
                          title: 'CSA Project',
                          subtitle: 'Child Support Action',
                          color: const Color(0xFF047857),
                          isSelected: _selectedProject == 'CSA',
                          onTap: isEditing
                              ? null
                              : () => setState(() => _selectedProject = 'CSA'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProjectOptionCard(
                          title: 'CNCP Project',
                          subtitle: 'Children in Need',
                          color: const Color(0xFF4F46E5),
                          isSelected: _selectedProject == 'CNCP',
                          onTap: isEditing
                              ? null
                              : () => setState(() => _selectedProject = 'CNCP'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Transaction Type Selector
                  const Text(
                    'Transaction Type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('+ Grant Inflow'),
                        selected: _selectedType == 'INCOME',
                        selectedColor: const Color(0xFF047857).withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: _selectedType == 'INCOME' ? const Color(0xFF047857) : Colors.black87,
                          fontWeight: _selectedType == 'INCOME' ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        onSelected: isEditing
                            ? null
                            : (val) {
                                if (val) {
                                  setState(() {
                                    _selectedType = 'INCOME';
                                    final cats = _getFilteredCategories();
                                    _selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
                                  });
                                }
                              },
                      ),
                      ChoiceChip(
                        label: const Text('Office Expense'),
                        selected: _selectedType == 'COMMON_EXPENSE',
                        selectedColor: Colors.amber.shade100,
                        labelStyle: TextStyle(
                          color: _selectedType == 'COMMON_EXPENSE' ? Colors.amber.shade900 : Colors.black87,
                          fontWeight: _selectedType == 'COMMON_EXPENSE' ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        onSelected: isEditing
                            ? null
                            : (val) {
                                if (val) {
                                  setState(() {
                                    _selectedType = 'COMMON_EXPENSE';
                                    final cats = _getFilteredCategories();
                                    _selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
                                  });
                                }
                              },
                      ),
                      ChoiceChip(
                        label: const Text('Staff Field TA Claim'),
                        selected: _selectedType == 'FIELD_EXPENSE',
                        selectedColor: Colors.blue.shade100,
                        labelStyle: TextStyle(
                          color: _selectedType == 'FIELD_EXPENSE' ? Colors.blue.shade900 : Colors.black87,
                          fontWeight: _selectedType == 'FIELD_EXPENSE' ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        onSelected: isEditing
                            ? null
                            : (val) {
                                if (val) {
                                  setState(() {
                                    _selectedType = 'FIELD_EXPENSE';
                                    final cats = _getFilteredCategories();
                                    _selectedCategoryId = cats.isNotEmpty ? cats.first.id : null;
                                  });
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Category Dropdown
                  const Text(
                    'Category',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: filteredCategories.any((c) => c.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : (filteredCategories.isNotEmpty ? filteredCategories.first.id : null),
                        hint: const Text('Select category'),
                        items: filteredCategories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.id,
                            child: Text(
                              c.name,
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (newCat) {
                          setState(() => _selectedCategoryId = newCat);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // If Field Expense, show staff selector
                  if (_selectedType == 'FIELD_EXPENSE') ...[
                    const Text(
                      'Claiming Staff Member',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedStaffId,
                          hint: const Text('Select staff member'),
                          items: _allStaff.map((s) {
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(
                                '${s.fullName} (${s.designation})',
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: isEditing
                              ? null
                              : (newStaff) {
                                  setState(() => _selectedStaffId = newStaff);
                                },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4. Amount & Date Row
                  Row(
                    children: [
                      // Amount
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Amount (₹)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                hintText: '0.00',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Enter amount';
                                final num = double.tryParse(val.trim());
                                if (num == null || num <= 0) return 'Valid amount';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Date picker
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Date',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF047857)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        DateFormat('dd MMM yyyy').format(_selectedDate),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Description
                  const Text(
                    'Particulars / Description',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Travel to Palakkad for child home inspection visit',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter description';
                      return null;
                    },
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
                            isEditing ? 'Save Changes' : 'Record Transaction',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _ProjectOptionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
