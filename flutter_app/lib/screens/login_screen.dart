import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/server_config_dialog.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();

  late TabController _tabController;

  // Login form controllers
  final _loginIdentifierController = TextEditingController();
  final _loginPinController = TextEditingController();
  bool _isLoggingIn = false;
  String? _loginError;

  // Registration form controllers
  final _regNameController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regSalaryController = TextEditingController(text: '20000');
  final _regPinController = TextEditingController();
  final _regOtpController = TextEditingController();

  String _regProject = 'CSA';
  String _regDesignation = 'CSA Case Worker';

  bool _isSendingOtp = false;
  bool _isRegistering = false;
  String? _regError;
  String? _regSuccessMessage;
  String? _generatedOtpForDemo;
  String? _whatsappDirectUrl;

  final List<Map<String, String>> _quickUsers = const [
    {
      'name': 'Rahul Nair',
      'role': 'CSA Coordinator',
      'project': 'CSA',
      'phone': '9846011111',
      'pin': '123456',
    },
    {
      'name': 'Priya Menon',
      'role': 'CSA Case Worker',
      'project': 'CSA',
      'phone': '9846022222',
      'pin': '123456',
    },
    {
      'name': 'Anand Kumar',
      'role': 'CNCP Coordinator',
      'project': 'CNCP',
      'phone': '9846033333',
      'pin': '123456',
    },
    {
      'name': 'Deepa Varghese',
      'role': 'CNCP Case Worker',
      'project': 'CNCP',
      'phone': '9846044444',
      'pin': '123456',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginIdentifierController.dispose();
    _loginPinController.dispose();
    _regNameController.dispose();
    _regPhoneController.dispose();
    _regSalaryController.dispose();
    _regPinController.dispose();
    _regOtpController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin({String? overridePhone, String? overridePin}) async {
    final phone = overridePhone ?? _loginIdentifierController.text.trim();
    final pin = overridePin ?? _loginPinController.text.trim();

    if (phone.isEmpty || pin.isEmpty) {
      setState(() => _loginError = 'Please enter both phone number and 6-digit PIN');
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });

    try {
      final staff = await _apiService.login(phone, pin);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${staff.fullName} (${staff.designation})!'),
          backgroundColor: const Color(0xFF047857),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoggingIn = false;
        _loginError = e.toString();
      });
    }
  }

  Future<void> _handleSendOtp() async {
    final name = _regNameController.text.trim();
    final phone = _regPhoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      setState(() => _regError = 'Please provide full name and WhatsApp number first.');
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _regError = null;
      _regSuccessMessage = null;
    });

    try {
      final res = await _apiService.sendRegistrationOtp(name, phone);
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _generatedOtpForDemo = res['otp']?.toString();
        _whatsappDirectUrl = res['whatsapp_url']?.toString();
        _regSuccessMessage = 'WhatsApp OTP Generated: ${_generatedOtpForDemo ?? ""}';
        if (_generatedOtpForDemo != null) {
          _regOtpController.text = _generatedOtpForDemo!;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingOtp = false;
        _regError = e.toString();
      });
    }
  }

  Future<void> _handleRegister() async {
    final name = _regNameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final salary = double.tryParse(_regSalaryController.text.trim()) ?? 0.0;
    final pin = _regPinController.text.trim();
    final otp = _regOtpController.text.trim();

    if (name.isEmpty || phone.isEmpty || pin.length < 4 || otp.isEmpty) {
      setState(() => _regError = 'Please fill all fields properly, including 6-digit PIN and OTP.');
      return;
    }

    setState(() {
      _isRegistering = true;
      _regError = null;
    });

    try {
      final res = await _apiService.verifyAndRegister(
        fullName: name,
        whatsappNumber: phone,
        project: _regProject,
        designation: _regDesignation,
        fixedSalary: salary,
        securityPin: pin,
        otpCode: otp,
      );

      if (!mounted) return;
      setState(() {
        _isRegistering = false;
        _regSuccessMessage = res['message']?.toString() ??
            'Registration successful! Your account is submitted for peer approval. Any active staff member can approve your account.';
      });

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Color(0xFF047857)),
              SizedBox(width: 8),
              Text('Registration Submitted', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            res['message']?.toString() ??
                'Registration OTP verified! An existing active staff member needs to approve your registration in the Dual Approval tab before you can log in.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _tabController.animateTo(0);
                _loginIdentifierController.text = phone;
                _loginPinController.text = pin;
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRegistering = false;
        _regError = e.toString();
      });
    }
  }

  void _openWhatsAppOtpLink() async {
    if (_whatsappDirectUrl != null) {
      final uri = Uri.parse(_whatsappDirectUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Emerald Gradient Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF065F46), // Deep emerald
                    Color(0xFF047857), // Primary emerald
                    Color(0xFF0F766E), // Tealish emerald
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  // App Bar Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.account_balance_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MoneyMate NGO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'CSA & CNCP Financial Portal',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Configure Backend Server URL',
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        onPressed: () => ServerConfigDialog.show(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Tab Bar (Login vs Register)
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(21),
                      ),
                      labelColor: const Color(0xFF047857),
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Staff Login'),
                        Tab(text: 'Register New Staff'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildRegisterTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Login Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sign In to Your Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Enter your registered WhatsApp number & 6-digit PIN',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  if (_loginError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _loginError!,
                              style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Phone Input
                  TextField(
                    controller: _loginIdentifierController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp Phone Number',
                      hintText: '9846011111',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF047857)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // PIN Input
                  TextField(
                    controller: _loginPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: '6-Digit Security PIN',
                      hintText: '••••••',
                      counterText: '',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xFF047857)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: _isLoggingIn ? null : () => _handleLogin(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoggingIn
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Log In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // 4 Quick Login Buttons Header
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 6),
              Text(
                'Demo One-Tap Quick Logins',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap any profile below to instantly log in as that coordinator or case worker:',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),

          // 4 Grid Buttons
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
            ),
            itemCount: _quickUsers.length,
            itemBuilder: (context, index) {
              final user = _quickUsers[index];
              final isCsa = user['project'] == 'CSA';
              final color = isCsa ? const Color(0xFF047857) : const Color(0xFF4F46E5);

              return InkWell(
                onTap: _isLoggingIn
                    ? null
                    : () {
                        _loginIdentifierController.text = user['phone']!;
                        _loginPinController.text = user['pin']!;
                        _handleLogin(overridePhone: user['phone'], overridePin: user['pin']);
                      },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withOpacity(0.3)),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: color.withOpacity(0.12),
                            child: Text(
                              user['name']!.substring(0, 1),
                              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user['project']!,
                              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name']!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user['role']!,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'WhatsApp OTP Registration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Register your profile with peer approval workflow',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              if (_regError != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_regError!, style: TextStyle(color: Colors.red.shade800, fontSize: 12)),
                ),
              ],

              if (_regSuccessMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _regSuccessMessage!,
                        style: TextStyle(color: Colors.green.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      if (_whatsappDirectUrl != null) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _openWhatsAppOtpLink,
                          child: const Text(
                            'Click here to open WhatsApp with prefilled message',
                            style: TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 11,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // Full Name
              TextField(
                controller: _regNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'e.g. Meera Krishnan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // WhatsApp Phone + OTP Action
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _regPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'WhatsApp (10 Digits)',
                        hintText: '9846055555',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSendingOtp ? null : _handleSendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSendingOtp
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send OTP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Project
              DropdownButtonFormField<String>(
                value: _regProject,
                decoration: InputDecoration(
                  labelText: 'Assigned Project',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'CSA', child: Text('CSA Project (Child Care Action)')),
                  DropdownMenuItem(value: 'CNCP', child: Text('CNCP Project (Child Protection)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _regProject = val;
                      _regDesignation = val == 'CSA' ? 'CSA Case Worker' : 'CNCP Case Worker';
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Designation
              DropdownButtonFormField<String>(
                value: _regDesignation,
                decoration: InputDecoration(
                  labelText: 'Designation / Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: [
                  if (_regProject == 'CSA') ...const [
                    DropdownMenuItem(value: 'CSA Coordinator', child: Text('CSA Coordinator')),
                    DropdownMenuItem(value: 'CSA Case Worker', child: Text('CSA Case Worker')),
                  ] else ...const [
                    DropdownMenuItem(value: 'CNCP Coordinator', child: Text('CNCP Coordinator')),
                    DropdownMenuItem(value: 'CNCP Case Worker', child: Text('CNCP Case Worker')),
                  ],
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _regDesignation = val);
                },
              ),
              const SizedBox(height: 12),

              // Fixed Salary
              TextField(
                controller: _regSalaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Fixed Monthly Salary (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Security PIN & OTP
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _regPinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '6-Digit PIN',
                        hintText: '123456',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _regOtpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'WhatsApp OTP',
                        hintText: 'Enter OTP',
                        counterText: '',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              ElevatedButton(
                onPressed: _isRegistering ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isRegistering
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify & Submit Registration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
