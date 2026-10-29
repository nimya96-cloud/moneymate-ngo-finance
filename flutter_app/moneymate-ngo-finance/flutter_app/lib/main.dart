import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase Configuration
const String supabaseUrl = 'YOUR_SUPABASE_PROJECT_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase if keys provided
  if (supabaseUrl != 'YOUR_SUPABASE_PROJECT_URL') {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  runApp(const NGOFinanceApp());
}

class NGOFinanceApp extends StatelessWidget {
  const NGOFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyMate NGO Finance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF047857), // Emerald Green
          primary: const Color(0xFF047857),
          secondary: const Color(0xFF0F766E),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const MobileMainScreen(),
    );
  }
}

class MobileMainScreen extends StatefulWidget {
  const MobileMainScreen({super.key});

  @override
  State<MobileMainScreen> createState() => _MobileMainScreenState();
}

class _MobileMainScreenState extends State<MobileMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    Center(child: Text("ഡാഷ്‌ബോർഡ് (ഹോം)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    Center(child: Text("ഇടപാടുകൾ (Transactions)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    Center(child: Text("സ്റ്റാഫ് ഫീൽഡ് സെറ്റിൽമെന്റ്", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    Center(child: Text("ഡ്യുവൽ അപ്രൂവൽ (OTP സുരക്ഷ)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
    Center(child: Text("റിപ്പോർട്ടുകൾ & ബാക്കപ്പ്", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("MoneyMate NGO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text("5-Staff Financial System", style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF047857),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: "ഹോം"),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: "ഇടപാടുകൾ"),
          NavigationDestination(icon: Icon(Icons.wallet_outlined), label: "സെറ്റിൽമെന്റ്"),
          NavigationDestination(icon: Icon(Icons.shield_outlined), label: "OTP സുരക്ഷ"),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: "റിപ്പോർട്ടുകൾ"),
        ],
      ),
    );
  }
}
