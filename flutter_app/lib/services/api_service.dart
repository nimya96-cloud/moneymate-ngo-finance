import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _keyBaseUrl = 'mm_ngo_base_url';
  static const String _keyCurrentUser = 'mm_ngo_current_user';
  static const String _defaultUrl = 'http://10.0.2.2:8000'; // Default for Android emulator, falls back to localhost

  String _baseUrl = _defaultUrl;
  Staff? _currentUser;

  Staff? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String get baseUrl => _baseUrl;

  /// Initialize service, load saved baseUrl and logged-in user
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_keyBaseUrl) ?? _defaultUrl;
    final userJson = prefs.getString(_keyCurrentUser);
    if (userJson != null) {
      try {
        _currentUser = Staff.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  /// Change the backend baseUrl
  Future<void> setBaseUrl(String newUrl) async {
    var clean = newUrl.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    _baseUrl = clean;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, _baseUrl);
  }

  /// Persist logged-in staff
  Future<void> saveCurrentUser(Staff staff) async {
    _currentUser = staff;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, jsonEncode(staff.toJson()));
  }

  /// Logout current staff
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
  }

  // --------------------------------------------------------------------------
  // HTTP Helpers with timeout and error extraction
  // --------------------------------------------------------------------------
  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? queryParams]) {
    String cleanBase = _baseUrl;
    if (cleanBase.endsWith('/')) {
      cleanBase = cleanBase.substring(0, cleanBase.length - 1);
    }
    final urlStr = '$cleanBase$path';
    final uri = Uri.parse(urlStr);
    if (queryParams != null && queryParams.isNotEmpty) {
      final sanitizedParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          sanitizedParams[key] = value.toString();
        }
      });
      return uri.replace(queryParameters: sanitizedParams);
    }
    return uri;
  }

  Never _handleError(dynamic error) {
    if (error is ApiException) throw error;
    if (error is SocketException) {
      throw ApiException(
        'Unable to connect to backend server at $_baseUrl. Please verify the URL in Settings and ensure the server is running.',
      );
    }
    if (error is TimeoutException) {
      throw ApiException('Connection timed out. Please check your network and server status.');
    }
    if (error is http.ClientException) {
      throw ApiException('Network connection failed: ${error.message}');
    }
    throw ApiException('An unexpected error occurred: ${error.toString()}');
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    String message = 'Request failed (${response.statusCode})';
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic> && decoded.containsKey('detail')) {
        message = decoded['detail'].toString();
      } else if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
        message = decoded['message'].toString();
      }
    } catch (_) {}
    throw ApiException(message, response.statusCode);
  }

  // ==========================================================================
  // AUTHENTICATION
  // ==========================================================================

  /// Phone + 6-digit PIN login
  Future<Staff> login(String identifier, String pin) async {
    try {
      final response = await http
          .post(
            _uri('/api/auth/login'),
            headers: _headers(),
            body: jsonEncode({'identifier': identifier.trim(), 'pin': pin.trim()}),
          )
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final userMap = data['user'] as Map<String, dynamic>;
      final staff = Staff.fromJson(userMap);
      await saveCurrentUser(staff);
      return staff;
    } catch (e) {
      _handleError(e);
    }
  }

  /// Request WhatsApp OTP for new staff registration
  Future<Map<String, dynamic>> sendRegistrationOtp(String fullName, String whatsappNumber) async {
    try {
      final response = await http
          .post(
            _uri('/api/auth/send-registration-otp'),
            headers: _headers(),
            body: jsonEncode({
              'full_name': fullName.trim(),
              'whatsapp_number': whatsappNumber.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      _handleError(e);
    }
  }

  /// Verify WhatsApp OTP and register new staff
  Future<Map<String, dynamic>> verifyAndRegister({
    required String fullName,
    required String whatsappNumber,
    required String project,
    required String designation,
    required double fixedSalary,
    required String securityPin,
    required String otpCode,
  }) async {
    try {
      final response = await http
          .post(
            _uri('/api/auth/verify-and-register'),
            headers: _headers(),
            body: jsonEncode({
              'full_name': fullName.trim(),
              'whatsapp_number': whatsappNumber.trim(),
              'project': project.trim().toUpperCase(),
              'designation': designation.trim(),
              'fixed_salary': fixedSalary,
              'security_pin': securityPin.trim(),
              'otp_code': otpCode.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      _handleError(e);
    }
  }

  // ==========================================================================
  // DASHBOARD STATS
  // ==========================================================================

  Future<DashboardStats> getDashboardStats() async {
    try {
      final response = await http
          .get(_uri('/api/dashboard/stats'), headers: _headers())
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return DashboardStats.fromJson(json);
    } catch (e) {
      _handleError(e);
    }
  }

  // ==========================================================================
  // STAFF DIRECTORY & RELIEVING
  // ==========================================================================

  Future<List<Staff>> getStaff({String? project}) async {
    try {
      final query = project != null && project != 'ALL' ? {'project': project} : null;
      final response = await http
          .get(_uri('/api/staff', query), headers: _headers())
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return list.map((item) => Staff.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<Map<String, dynamic>> requestRelieveStaff({
    required String targetStaffId,
    required String reason,
  }) async {
    if (_currentUser == null) throw ApiException('You must be logged in to relieve staff.');
    try {
      final response = await http
          .post(
            _uri('/api/staff/request-relieve'),
            headers: _headers(),
            body: jsonEncode({
              'target_staff_id': targetStaffId,
              'staff_id_to_relieve': targetStaffId,
              'requested_by': _currentUser!.id,
              'reason': reason.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      _handleError(e);
    }
  }

  // ==========================================================================
  // CATEGORIES
  // ==========================================================================

  Future<List<Category>> getCategories() async {
    try {
      final response = await http
          .get(_uri('/api/categories'), headers: _headers())
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return list.map((item) => Category.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      _handleError(e);
    }
  }

  // ==========================================================================
  // TRANSACTIONS
  // ==========================================================================

  Future<List<TransactionModel>> getTransactions({
    String? project,
    String? transactionType,
    String? staffId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (project != null && project != 'ALL') query['project'] = project;
      if (transactionType != null && transactionType != 'ALL') query['transaction_type'] = transactionType;
      if (staffId != null && staffId.isNotEmpty) query['staff_id'] = staffId;
      if (startDate != null && startDate.isNotEmpty) query['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) query['end_date'] = endDate;

      final response = await http
          .get(_uri('/api/transactions', query), headers: _headers())
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return list.map((item) => TransactionModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<TransactionModel> createTransaction({
    required String project,
    required String transactionType,
    required String categoryId,
    required double amount,
    required String transactionDate,
    required String description,
    String? staffId,
    List<dynamic>? documents,
  }) async {
    if (_currentUser == null) throw ApiException('User must be logged in to create transactions.');
    try {
      final body = {
        'project': project.toUpperCase(),
        'transaction_type': transactionType.toUpperCase(),
        'category_id': categoryId,
        'amount': amount,
        'transaction_date': transactionDate,
        'description': description.trim(),
        'created_by': _currentUser!.id,
        'staff_id': transactionType.toUpperCase() == 'FIELD_EXPENSE' ? (staffId ?? _currentUser!.id) : null,
        'documents': documents ?? [],
      };

      final response = await http
          .post(_uri('/api/transactions'), headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final resJson = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final txMap = resJson['transaction'] as Map<String, dynamic>;
      return TransactionModel.fromJson(txMap);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<TransactionModel> updateTransaction(
    String txId, {
    double? amount,
    String? description,
    String? transactionDate,
    String? categoryId,
  }) async {
    if (_currentUser == null) throw ApiException('User must be logged in to update transactions.');
    try {
      final body = <String, dynamic>{
        'updated_by': _currentUser!.id,
      };
      if (amount != null) body['amount'] = amount;
      if (description != null) body['description'] = description.trim();
      if (transactionDate != null) body['transaction_date'] = transactionDate;
      if (categoryId != null) body['category_id'] = categoryId;

      final response = await http
          .put(_uri('/api/transactions/$txId'), headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final resJson = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final txMap = resJson['transaction'] as Map<String, dynamic>;
      return TransactionModel.fromJson(txMap);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<bool> deleteTransaction(String txId, {required String reason}) async {
    if (_currentUser == null) throw ApiException('User must be logged in to delete transactions.');
    try {
      final response = await http
          .delete(
            _uri('/api/transactions/$txId'),
            headers: _headers(),
            body: jsonEncode({
              'deleted_by': _currentUser!.id,
              'reason': reason.trim(),
            }),
          )
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      return true;
    } catch (e) {
      _handleError(e);
    }
  }

  // ==========================================================================
  // SETTLEMENTS
  // ==========================================================================

  Future<List<PendingSettlementStaff>> getPendingSettlementSummary({String? project}) async {
    try {
      final query = project != null && project != 'ALL' ? {'project': project} : null;
      final response = await http
          .get(_uri('/api/settlements/pending-summary', query), headers: _headers())
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return list.map((item) => PendingSettlementStaff.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<Settlement> executeSettlement({
    required String staffId,
    required String project,
    required String monthPeriod,
    required double salaryEntitlement,
    required double accumulatedTaClaims,
    required double actualAmountPaidNow,
    String paymentMode = 'Bank Transfer',
    String referenceNumber = '',
    String notes = '',
  }) async {
    if (_currentUser == null) throw ApiException('User must be logged in to execute settlement.');
    try {
      final body = {
        'staff_id': staffId,
        'project': project.toUpperCase(),
        'month_period': monthPeriod,
        'salary_entitlement': salaryEntitlement,
        'accumulated_ta_claims': accumulatedTaClaims,
        'actual_amount_paid_now': actualAmountPaidNow,
        'payment_mode': paymentMode,
        'reference_number': referenceNumber.trim(),
        'notes': notes.trim(),
        'settled_by': _currentUser!.id,
      };

      final response = await http
          .post(_uri('/api/settlements/execute'), headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final resJson = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final setMap = resJson['settlement'] as Map<String, dynamic>;
      return Settlement.fromJson(setMap);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<List<Settlement>> getSettlements({String? staffId, String? project}) async {
    try {
      final query = <String, dynamic>{};
      if (staffId != null && staffId.isNotEmpty) query['staff_id'] = staffId;
      if (project != null && project != 'ALL') query['project'] = project;

      final response = await http
          .get(_uri('/api/settlements', query), headers: _headers())
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return list.map((item) => Settlement.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      _handleError(e);
    }
  }

  // ==========================================================================
  // STAFF LEDGER
  // ==========================================================================

  Future<StaffLedger> getStaffLedger({
    required String staffId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final query = <String, dynamic>{'staff_id': staffId};
      if (startDate != null && startDate.isNotEmpty) query['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) query['end_date'] = endDate;

      final response = await http
          .get(_uri('/api/reports/staff-ledger', query), headers: _headers())
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final resJson = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return StaffLedger.fromJson(resJson);
    } catch (e) {
      _handleError(e);
    }
  }

  // ==========================================================================
  // DUAL APPROVALS
  // ==========================================================================

  Future<List<DualApproval>> getApprovals({String? status}) async {
    try {
      final query = status != null ? {'status': status} : null;
      final response = await http
          .get(_uri('/api/approvals', query), headers: _headers())
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return list.map((item) => DualApproval.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<Map<String, dynamic>> resolveApproval({
    required String approvalId,
    required String decision, // APPROVED or REJECTED
    required String pin,
    String notes = '',
  }) async {
    if (_currentUser == null) throw ApiException('User must be logged in to approve or reject.');
    try {
      final body = {
        'approval_id': approvalId,
        'resolved_by': _currentUser!.id,
        'approving_staff_id': _currentUser!.id,
        'decision': decision.toUpperCase(),
        'pin': pin.trim(),
        'approver_pin': pin.trim(),
        'notes': notes.trim(),
      };

      final response = await http
          .post(_uri('/api/approvals/resolve'), headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 12));

      _checkResponse(response);
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      _handleError(e);
    }
  }

  // ==========================================================================
  // NOTIFICATIONS
  // ==========================================================================

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await http
          .get(_uri('/api/notifications'), headers: _headers())
          .timeout(const Duration(seconds: 10));

      _checkResponse(response);
      final list = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return list.map((item) => AppNotification.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<bool> markNotificationsRead() async {
    try {
      final response = await http
          .post(_uri('/api/notifications/mark-read'), headers: _headers())
          .timeout(const Duration(seconds: 10));

      _checkResponse(response);
      return true;
    } catch (e) {
      _handleError(e);
    }
  }
}
