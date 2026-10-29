import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/server_config_dialog.dart';
import 'approval_screen.dart';
import 'dashboard_screen.dart';
import 'ledger_screen.dart';
import 'login_screen.dart';
import 'settlement_screen.dart';
import 'transactions_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _apiService = ApiService();
  late int _currentIndex;

  int _unreadNotifCount = 0;
  List<AppNotification> _notifications = [];

  // Keys to trigger refresh on current child screen
  final _dashboardKey = GlobalKey<DashboardScreenState>();
  final _transactionsKey = GlobalKey<TransactionsScreenState>();
  final _ledgerKey = GlobalKey<LedgerScreenState>();
  final _settlementKey = GlobalKey<SettlementScreenState>();
  final _approvalKey = GlobalKey<ApprovalScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifs = await _apiService.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = notifs;
        _unreadNotifCount = notifs.where((n) => !n.isRead).length;
      });
    } catch (_) {}
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.notifications_outlined, color: Color(0xFF047857)),
                    SizedBox(width: 8),
                    Text(
                      'Notifications & Alerts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    await _apiService.markNotificationsRead();
                    setState(() {
                      _unreadNotifCount = 0;
                    });
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Mark all read', style: TextStyle(color: Color(0xFF047857), fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 20),
            Expanded(
              child: _notifications.isEmpty
                  ? Center(
                      child: Text(
                        'No notifications yet.',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final n = _notifications[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: n.isRead ? Colors.white : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: n.isRead ? Colors.grey.shade200 : const Color(0xFF34D399).withOpacity(0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    n.createdAtFormatted ?? formatDateDisplay(n.createdAt),
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                n.message,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of MoneyMate NGO?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _onServerConfigSaved() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Server URL updated! Refreshing data...'),
        backgroundColor: Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // Refresh the currently visible screen
    _refreshCurrentScreen();
    _loadNotifications();
  }

  void _refreshCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        _dashboardKey.currentState?.refreshData();
        break;
      case 1:
        _transactionsKey.currentState?.refreshData();
        break;
      case 2:
        _ledgerKey.currentState?.refreshData();
        break;
      case 3:
        _settlementKey.currentState?.refreshData();
        break;
      case 4:
        _approvalKey.currentState?.refreshData();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _apiService.currentUser;
    final isCsa = user?.project.toUpperCase() == 'CSA';
    final projectBadgeColor = isCsa ? const Color(0xFF34D399) : const Color(0xFFA5B4FC);

    final screens = [
      DashboardScreen(
        key: _dashboardKey,
        onNavigateToTransactions: () => setState(() => _currentIndex = 1),
      ),
      TransactionsScreen(key: _transactionsKey),
      LedgerScreen(key: _ledgerKey),
      SettlementScreen(key: _settlementKey),
      ApprovalScreen(key: _approvalKey),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF047857), // Emerald Green
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'MoneyMate NGO',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                if (user != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: projectBadgeColor.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: projectBadgeColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      user.project,
                      style: TextStyle(
                        color: projectBadgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              user != null ? '${user.fullName} • ${user.designation}' : '5-Staff Financial System',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Notification Bell
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                tooltip: 'Notifications',
                onPressed: _showNotificationsSheet,
              ),
              if (_unreadNotifCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_unreadNotifCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // Server settings
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Server Settings',
            onPressed: () => ServerConfigDialog.show(context, onSaved: _onServerConfigSaved),
          ),

          // User Menu / Logout
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (val) {
              if (val == 'logout') _handleLogout();
              if (val == 'settings') ServerConfigDialog.show(context, onSaved: _onServerConfigSaved);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'profile',
                enabled: false,
                child: Text(
                  'Signed in as:\n${user?.fullName ?? "Staff"}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Server Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Log Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() => _currentIndex = idx);
          _loadNotifications();
        },
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFF047857).withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF047857)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFF047857)),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded, color: Color(0xFF047857)),
            label: 'Ledger',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF047857)),
            label: 'Settlement',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded, color: Color(0xFF047857)),
            label: 'Dual Approval',
          ),
        ],
      ),
    );
  }
}
