import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// NIRIKSHAN - LEGAL METROLOGY INSPECTION APP
// SIH 2026 - Problem Statement 26034
// ============================================================

// ---------------------------
// APP COLORS
// ---------------------------

class AppColors {
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color secondary = Color(0xFF00ACC1);

  static const Color background = Color(0xFFF5F7FA);
  static const Color card = Colors.white;

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color danger = Color(0xFFC62828);

  static const Color textPrimary = Color(0xFF17202A);
  static const Color textSecondary = Color(0xFF607080);
}

// ---------------------------
// MAIN
// ---------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await InspectionStore.load();

  runApp(const NirikshanApp());
}

// ---------------------------
// HELPER FUNCTIONS
// ---------------------------

Color statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PASS':
      return AppColors.success;

    case 'PARTIAL':
      return AppColors.warning;

    case 'VIOLATION':
      return AppColors.danger;

    default:
      return AppColors.textSecondary;
  }
}

IconData statusIcon(String status) {
  switch (status.toUpperCase()) {
    case 'PASS':
      return Icons.check_circle;

    case 'PARTIAL':
      return Icons.warning_rounded;

    case 'VIOLATION':
      return Icons.error;

    default:
      return Icons.help_outline;
  }
}

String formatDateTime(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final year = dateTime.year.toString();

  final hour = dateTime.hour == 0
      ? 12
      : dateTime.hour > 12
      ? dateTime.hour - 12
      : dateTime.hour;

  final minute = dateTime.minute.toString().padLeft(2, '0');

  final period = dateTime.hour >= 12 ? 'PM' : 'AM';

  return '$day/$month/$year  $hour:$minute $period';
}

String pdfSafe(String value) {
  return value
      .replaceAll('₹', 'INR ')
      .replaceAll('•', '-')
      .replaceAll('–', '-')
      .replaceAll('—', '-');
}

// ---------------------------
// REUSABLE STATUS BADGE
// ---------------------------

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon(status), size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------
// SECTION TITLE
// ---------------------------

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------
// PRIMARY BUTTON
// ---------------------------

class PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(
          loading ? 'Please wait...' : text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ---------------------------
// EMPTY STATE
// ---------------------------

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// PART 2/8
// DATA MODELS + LOCAL HISTORY STORAGE
// ============================================================

// ---------------------------
// DECLARATION DATA
// ---------------------------

class DeclarationData {
  String productName;
  String manufacturer;
  String address;
  String netQuantity;
  String mrp;
  String manufactureDate;
  String consumerCare;

  DeclarationData({
    this.productName = '',
    this.manufacturer = '',
    this.address = '',
    this.netQuantity = '',
    this.mrp = '',
    this.manufactureDate = '',
    this.consumerCare = '',
  });

  Map<String, String> toMap() {
    return {
      'Product Name': productName,
      'Manufacturer / Packer / Importer': manufacturer,
      'Address': address,
      'Net Quantity': netQuantity,
      'MRP': mrp,
      'Manufacture / Packing Date': manufactureDate,
      'Consumer Care': consumerCare,
    };
  }

  factory DeclarationData.fromMap(Map<String, dynamic> map) {
    return DeclarationData(
      productName: map['Product Name']?.toString() ?? '',
      manufacturer: map['Manufacturer / Packer / Importer']?.toString() ?? '',
      address: map['Address']?.toString() ?? '',
      netQuantity: map['Net Quantity']?.toString() ?? '',
      mrp: map['MRP']?.toString() ?? '',
      manufactureDate: map['Manufacture / Packing Date']?.toString() ?? '',
      consumerCare: map['Consumer Care']?.toString() ?? '',
    );
  }
}

// ---------------------------
// COMPLIANCE RESULT
// ---------------------------

class ComplianceResult {
  final int passed;
  final int missing;
  final List<String> missingItems;

  const ComplianceResult({
    required this.passed,
    required this.missing,
    required this.missingItems,
  });

  int get total => passed + missing;

  double get percentage {
    if (total == 0) {
      return 0;
    }

    return (passed / total) * 100;
  }

  String get status {
    if (total == 0) {
      return 'NO DATA';
    }

    if (missing == 0) {
      return 'PASS';
    }

    if (passed >= 3) {
      return 'PARTIAL';
    }

    return 'VIOLATION';
  }
}

// ---------------------------
// INSPECTION RECORD
// ---------------------------

class InspectionRecord {
  final String id;
  final DateTime dateTime;
  final String productName;
  final String packageType;
  final String category;
  final String status;
  final double percentage;
  final int detected;
  final int missing;
  final String imagePath;
  final String notes;
  final Map<String, String> declarations;
  final List<String> missingItems;

  const InspectionRecord({
    required this.id,
    required this.dateTime,
    required this.productName,
    required this.packageType,
    required this.category,
    required this.status,
    required this.percentage,
    required this.detected,
    required this.missing,
    required this.imagePath,
    required this.notes,
    required this.declarations,
    required this.missingItems,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'productName': productName,
      'packageType': packageType,
      'category': category,
      'status': status,
      'percentage': percentage,
      'detected': detected,
      'missing': missing,
      'imagePath': imagePath,
      'notes': notes,
      'declarations': declarations,
      'missingItems': missingItems,
    };
  }

  factory InspectionRecord.fromJson(Map<String, dynamic> json) {
    final rawDeclarations = json['declarations'];

    final Map<String, String> declarations = rawDeclarations is Map
        ? rawDeclarations.map(
            (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
          )
        : <String, String>{};

    final rawMissing = json['missingItems'];

    final List<String> missingItems = rawMissing is List
        ? rawMissing.map((item) => item.toString()).toList()
        : <String>[];

    return InspectionRecord(
      id: json['id']?.toString() ?? '',
      dateTime:
          DateTime.tryParse(json['dateTime']?.toString() ?? '') ??
          DateTime.now(),
      productName: json['productName']?.toString() ?? 'Unknown Product',
      packageType: json['packageType']?.toString() ?? 'Not specified',
      category: json['category']?.toString() ?? 'General',
      status: json['status']?.toString() ?? 'NO DATA',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      detected: (json['detected'] as num?)?.toInt() ?? 0,
      missing: (json['missing'] as num?)?.toInt() ?? 0,
      imagePath: json['imagePath']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      declarations: declarations,
      missingItems: missingItems,
    );
  }
}

// ---------------------------
// LOCAL INSPECTION STORE
// ---------------------------
//
// Saves inspection history on the phone so that records remain
// available after closing and reopening the application.
// ---------------------------

class InspectionStore {
  static const String _storageKey = 'nirikshan_inspection_history_v1';

  static List<InspectionRecord> records = [];

  static Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final savedRecords = preferences.getStringList(_storageKey);

      if (savedRecords == null) {
        records = [];
        return;
      }

      final List<InspectionRecord> loaded = [];

      for (final item in savedRecords) {
        try {
          final decoded = jsonDecode(item);

          if (decoded is Map<String, dynamic>) {
            loaded.add(InspectionRecord.fromJson(decoded));
          }
        } catch (_) {
          // Ignore one corrupted record and continue loading
          // the remaining valid records.
        }
      }

      records = loaded;
    } catch (_) {
      records = [];
    }
  }

  static Future<void> add(InspectionRecord record) async {
    records.insert(0, record);
    await _save();
  }

  static Future<void> remove(String id) async {
    records.removeWhere((record) => record.id == id);

    await _save();
  }

  static Future<void> clear() async {
    records.clear();
    await _save();
  }

  static Future<void> _save() async {
    try {
      final preferences = await SharedPreferences.getInstance();

      final data = records
          .map((record) => jsonEncode(record.toJson()))
          .toList();

      await preferences.setStringList(_storageKey, data);
    } catch (_) {
      // The app continues working even if local storage fails.
    }
  }
}
// ============================================================
// PART 3/8
// APP + SPLASH SCREEN + LOGIN SCREEN
// ============================================================

// ---------------------------
// NIRIKSHAN APP
// ---------------------------

class NirikshanApp extends StatelessWidget {
  const NirikshanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nirikshan',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,

        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: false,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}

// ---------------------------
// SPLASH SCREEN
// ---------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();

    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 105,
                  height: 105,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    size: 58,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'NIRIKSHAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Smart Packaged Commodity Inspection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 40),

                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------
// LOGIN SCREEN
// ---------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 35, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Center(
                child: Text(
                  'Welcome to Nirikshan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  'Smart inspection for packaged commodities',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 38),

              const Text(
                'Inspector Login',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email / Inspector ID',
                  hintText: 'Enter your ID',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              PrimaryButton(
                text: 'Login',
                icon: Icons.login_rounded,
                loading: _loading,
                onPressed: _login,
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Prototype login for the SIH demonstration. '
                        'Authentication can be connected to the backend later.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Center(
                child: Text(
                  'NIRIKSHAN • SIH 2026',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ============================================================
// PART 4/8
// PHASE 3H - DASHBOARD
// ============================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<void> _openScreen(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    if (mounted) {
      setState(() {});
    }
  }

  int get totalInspections {
    return InspectionStore.records.length;
  }

  int get passedInspections {
    return InspectionStore.records
        .where((record) => record.status == 'PASS')
        .length;
  }

  int get partialInspections {
    return InspectionStore.records
        .where((record) => record.status == 'PARTIAL')
        .length;
  }

  int get violationInspections {
    return InspectionStore.records
        .where((record) => record.status == 'VIOLATION')
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final recentRecords = InspectionStore.records.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Nirikshan',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
        actions: [
          IconButton(
            tooltip: 'Inspection History',
            onPressed: () {
              _openScreen(const HistoryScreen());
            },
            icon: const Icon(Icons.history_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          await InspectionStore.load();

          if (mounted) {
            setState(() {});
          }
        },

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // WELCOME CARD
              // ------------------------------------------------

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),

                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),

                  borderRadius: BorderRadius.circular(24),

                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Smart Inspection',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            'Inspect with confidence.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          SizedBox(height: 8),

                          Text(
                            'Scan packaged commodity labels '
                            'and review detected declarations.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    Container(
                      width: 62,
                      height: 62,

                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ------------------------------------------------
              // STATISTICS
              // ------------------------------------------------
              const SectionTitle(
                title: 'Inspection Overview',
                subtitle: 'Your inspection activity at a glance',
              ),

              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),

                mainAxisSpacing: 12,
                crossAxisSpacing: 12,

                childAspectRatio: 1.65,

                children: [
                  _statCard(
                    title: 'Total',
                    value: totalInspections.toString(),
                    icon: Icons.fact_check_rounded,
                    color: AppColors.primary,
                  ),

                  _statCard(
                    title: 'Passed',
                    value: passedInspections.toString(),
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                  ),

                  _statCard(
                    title: 'Partial',
                    value: partialInspections.toString(),
                    icon: Icons.warning_rounded,
                    color: AppColors.warning,
                  ),

                  _statCard(
                    title: 'Potential Issues',
                    value: violationInspections.toString(),
                    icon: Icons.error_rounded,
                    color: AppColors.danger,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // QUICK ACTIONS
              // ------------------------------------------------
              const SectionTitle(
                title: 'Quick Actions',
                subtitle: 'Start a new inspection or review previous results',
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      title: 'Start Inspection',
                      subtitle: 'Scan a package',
                      icon: Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      onTap: () {
                        _openScreen(const InspectionScreen());
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _actionCard(
                      title: 'History',
                      subtitle: 'View reports',
                      icon: Icons.history_rounded,
                      color: AppColors.secondary,
                      onTap: () {
                        _openScreen(const HistoryScreen());
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // RECENT INSPECTIONS
              // ------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  const SectionTitle(
                    title: 'Recent Inspections',
                    subtitle: 'Latest saved inspection reports',
                  ),

                  if (recentRecords.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        _openScreen(const HistoryScreen());
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              if (recentRecords.isEmpty)
                const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No inspections yet',
                  message:
                      'Start your first inspection to see '
                      'results and reports here.',
                )
              else
                Column(
                  children: recentRecords
                      .map((record) => _recentInspectionCard(record))
                      .toList(),
                ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // IMPORTANT NOTE
              // ------------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),

                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Nirikshan currently performs automated '
                        'declaration screening based on detected '
                        'label text. Inspector verification is '
                        'required for final legal determination.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // STAT CARD
  // ----------------------------------------------------------

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),

            child: Icon(icon, color: color, size: 23),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // ACTION CARD
  // ----------------------------------------------------------

  Widget _actionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                width: 45,
                height: 45,

                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),

                child: Icon(icon, color: color, size: 24),
              ),

              const SizedBox(height: 13),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // RECENT INSPECTION CARD
  // ----------------------------------------------------------

  Widget _recentInspectionCard(InspectionRecord record) {
    final color = statusColor(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),

        leading: Container(
          width: 45,
          height: 45,

          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
          ),

          child: Icon(statusIcon(record.status), color: color, size: 24),
        ),

        title: Text(
          record.productName.isEmpty ? 'Unknown Product' : record.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,

          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            formatDateTime(record.dateTime),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          crossAxisAlignment: CrossAxisAlignment.end,

          children: [
            StatusBadge(status: record.status),

            const SizedBox(height: 4),

            Text(
              '${record.percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),

        onTap: () {
          _openScreen(ReportScreen(record: record));
        },
      ),
    );
  }
}
// ============================================================
// PART 5/8
// INSPECTION SETUP + CAMERA / GALLERY SCANNING
// ============================================================

// ---------------------------
// INSPECTION SETUP SCREEN
// ---------------------------

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  String packageType = 'Pouch';
  String category = 'Food';

  final List<String> packageTypes = [
    'Pouch',
    'Bottle',
    'Box',
    'Can',
    'Jar',
    'Packet',
    'Other',
  ];

  final List<String> categories = [
    'Food',
    'Beverage',
    'Personal Care',
    'Household',
    'Electronics',
    'Other',
  ];

  void _continueToScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ScanScreen(packageType: packageType, category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Inspection',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Inspection',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Select basic package information '
                          'before capturing the label.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const SectionTitle(
              title: 'Package Information',
              subtitle: 'These details help organize the inspection',
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // PACKAGE TYPE
            // --------------------------------------------------
            const Text(
              'Package Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: packageType,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.inventory_2_outlined),
                hintText: 'Select package type',
              ),
              items: packageTypes
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  packageType = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // CATEGORY
            // --------------------------------------------------
            const Text(
              'Product Category',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
                hintText: 'Select category',
              ),
              items: categories
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  category = value;
                });
              },
            ),

            const SizedBox(height: 30),

            // --------------------------------------------------
            // INSPECTION CHECKLIST
            // --------------------------------------------------
            const SectionTitle(
              title: 'Automated Screening',
              subtitle: 'Nirikshan will look for key declarations',
            ),

            const SizedBox(height: 14),

            _checkItem(Icons.inventory_2_outlined, 'Product name'),

            _checkItem(
              Icons.business_outlined,
              'Manufacturer / packer / importer',
            ),

            _checkItem(Icons.location_on_outlined, 'Address'),

            _checkItem(Icons.scale_outlined, 'Net quantity'),

            _checkItem(
              Icons.currency_rupee_rounded,
              'Maximum Retail Price (MRP)',
            ),

            _checkItem(
              Icons.calendar_month_outlined,
              'Manufacture / packing date',
            ),

            _checkItem(
              Icons.support_agent_outlined,
              'Consumer care information',
            ),

            const SizedBox(height: 30),

            PrimaryButton(
              text: 'Continue to Scan',
              icon: Icons.arrow_forward_rounded,
              onPressed: _continueToScan,
            ),
          ],
        ),
      ),
    );
  }

  Widget _checkItem(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.check, size: 18, color: AppColors.success),
        ],
      ),
    );
  }
}

// ============================================================
// SCAN SCREEN
// ============================================================

class ScanScreen extends StatefulWidget {
  final String packageType;
  final String category;

  const ScanScreen({
    super.key,
    required this.packageType,
    required this.category,
  });

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();

  XFile? selectedImage;

  bool _loading = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _loading = true;
    });

    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2200,
        maxHeight: 2200,
      );

      if (!mounted) {
        return;
      }

      if (image != null) {
        setState(() {
          selectedImage = image;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to select image: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _analyzeImage() {
    if (selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture or select a package image first.'),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalysisScreen(
          imageFile: File(selectedImage!.path),
          packageType: widget.packageType,
          category: widget.category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Package',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // --------------------------------------------------
            // SCAN HEADER
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),

                borderRadius: BorderRadius.circular(20),
              ),

              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Icon(
                    Icons.document_scanner_rounded,
                    color: Colors.white,
                    size: 38,
                  ),

                  SizedBox(height: 13),

                  Text(
                    'Capture the label clearly',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Make sure the declarations are visible '
                    'and the image is well lit.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // IMAGE PREVIEW
            // --------------------------------------------------
            Container(
              width: double.infinity,
              height: 290,

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),

                border: Border.all(color: Colors.grey.shade200),
              ),

              child: selectedImage == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_search_rounded,
                          size: 55,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 13),
                        Text(
                          'No image selected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Capture or choose a package image',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.file(
                        File(selectedImage!.path),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------
            // CAMERA / GALLERY BUTTONS
            // --------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () {
                            _pickImage(ImageSource.camera);
                          },

                    icon: const Icon(Icons.camera_alt_rounded),

                    label: const Text(
                      'Camera',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),

                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () {
                            _pickImage(ImageSource.gallery);
                          },

                    icon: const Icon(Icons.photo_library_rounded),

                    label: const Text(
                      'Gallery',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),

                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // --------------------------------------------------
            // SELECTED PACKAGE INFORMATION
            // --------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),

                border: Border.all(color: Colors.grey.shade200),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primary,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          widget.packageType,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          widget.category,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --------------------------------------------------
            // ANALYZE BUTTON
            // --------------------------------------------------
            PrimaryButton(
              text: 'Analyze Label',
              icon: Icons.auto_awesome_rounded,
              loading: _loading,
              onPressed: selectedImage == null ? null : _analyzeImage,
            ),

            const SizedBox(height: 14),

            const Center(
              child: Text(
                'OCR will extract visible label declarations '
                'for automated screening.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ============================================================
// PART 6/8
// OCR + DECLARATION PARSER + COMPLIANCE ENGINE
// ============================================================

// ---------------------------
// DECLARATION PARSER
// ---------------------------
//
// This parser extracts the important declarations from the
// text returned by Google ML Kit OCR.
//
// It is intentionally conservative:
// detected text = "DETECTED"
// empty field = "NOT DETECTED"
//
// This is a declaration screening system, not a final legal
// determination.
// ---------------------------

DeclarationData parseDeclarations(String rawText) {
  final data = DeclarationData();

  if (rawText.trim().isEmpty) {
    return data;
  }

  final normalizedText = rawText.replaceAll('\r', '\n').replaceAll('\t', ' ');

  final lines = normalizedText
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  final lowerText = normalizedText.toLowerCase();

  // ----------------------------------------------------------
  // MRP
  // ----------------------------------------------------------

  final mrpMatch = RegExp(
    r'(?:m\.?\s*r\.?\s*p\.?|maximum\s+retail\s+price)'
    r'\s*[:\-]?\s*(?:rs\.?|inr)?\s*'
    r'([0-9]+(?:[.,][0-9]{1,2})?)',
    caseSensitive: false,
  ).firstMatch(normalizedText);

  if (mrpMatch != null) {
    data.mrp = 'INR ${mrpMatch.group(1)}';
  } else {
    final simpleMrp = RegExp(
      r'\b(?:mrp|m\.r\.p)\b[^\d]{0,15}'
      r'(?:rs\.?|inr|₹)?\s*'
      r'([0-9]+(?:[.,][0-9]{1,2})?)',
      caseSensitive: false,
    ).firstMatch(normalizedText);

    if (simpleMrp != null) {
      data.mrp = 'INR ${simpleMrp.group(1)}';
    }
  }

  // ----------------------------------------------------------
  // NET QUANTITY
  // ----------------------------------------------------------

  final quantityMatch = RegExp(
    r'(?:net\s*(?:qty|quantity|wt|weight|volume)|'
    r'net\s*(?:content|contents))'
    r'\s*[:\-]?\s*'
    r'([0-9]+(?:[.,][0-9]+)?)\s*'
    r'(kg|g|gm|gram|grams|mg|l|ltr|litre|litres|ml|'
    r'millilitre|millilitres|pcs|pieces|piece)',
    caseSensitive: false,
  ).firstMatch(normalizedText);

  if (quantityMatch != null) {
    data.netQuantity = '${quantityMatch.group(1)} ${quantityMatch.group(2)}';
  } else {
    final simpleQuantity = RegExp(
      r'\bnet\b[^\n]{0,30}'
      r'([0-9]+(?:[.,][0-9]+)?)\s*'
      r'(kg|g|gm|mg|l|ltr|ml|pcs|pieces)',
      caseSensitive: false,
    ).firstMatch(normalizedText);

    if (simpleQuantity != null) {
      data.netQuantity =
          '${simpleQuantity.group(1)} '
          '${simpleQuantity.group(2)}';
    }
  }

  // ----------------------------------------------------------
  // MANUFACTURER / PACKER / IMPORTER
  // ----------------------------------------------------------

  final manufacturerMatch = RegExp(
    r'((?:manufactured|manufacture|packed|imported|'
    r'marketed)\s*(?:by|for)?'
    r'[\s:,\-]*[^\n]{2,120})',
    caseSensitive: false,
  ).firstMatch(normalizedText);

  if (manufacturerMatch != null) {
    data.manufacturer = cleanExtractedValue(manufacturerMatch.group(1)!);
  }

  // ----------------------------------------------------------
  // ADDRESS
  // ----------------------------------------------------------

  final addressMatch = RegExp(
    r'(?:address|addr\.?)'
    r'\s*[:\-]?\s*([^\n]{5,180})',
    caseSensitive: false,
  ).firstMatch(normalizedText);

  if (addressMatch != null) {
    data.address = cleanExtractedValue(addressMatch.group(1)!);
  } else {
    final addressLine = lines.cast<String?>().firstWhere((line) {
      if (line == null) {
        return false;
      }

      final lower = line.toLowerCase();

      return lower.contains('road') ||
          lower.contains('street') ||
          lower.contains('nagar') ||
          lower.contains('industrial area') ||
          lower.contains('estate') ||
          lower.contains('india') ||
          lower.contains('sector');
    }, orElse: () => null);

    if (addressLine != null) {
      data.address = cleanExtractedValue(addressLine);
    }
  }

  // ----------------------------------------------------------
  // MANUFACTURE / PACKING DATE
  // ----------------------------------------------------------

  final dateMatch = RegExp(
    r'(?:mfg|mfd|manufactured|manufacturing|'
    r'date\s+of\s+manufacture|'
    r'packed\s+on|packing\s+date|'
    r'month\s*(?:and|&)\s*year)'
    r'\s*[:\-]?\s*([^\n]{2,50})',
    caseSensitive: false,
  ).firstMatch(normalizedText);

  if (dateMatch != null) {
    data.manufactureDate = cleanExtractedValue(dateMatch.group(1)!);
  }

  // ----------------------------------------------------------
  // CONSUMER CARE
  // ----------------------------------------------------------

  final consumerCareMatch = RegExp(
    r'(?:consumer\s*care|customer\s*care|'
    r'helpline|toll\s*free|contact\s*us)'
    r'\s*[:\-]?\s*([^\n]{3,150})',
    caseSensitive: false,
  ).firstMatch(normalizedText);

  if (consumerCareMatch != null) {
    data.consumerCare = cleanExtractedValue(consumerCareMatch.group(1)!);
  } else {
    final emailMatch = RegExp(
      r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
      caseSensitive: false,
    ).firstMatch(normalizedText);

    if (emailMatch != null) {
      data.consumerCare = emailMatch.group(0)!;
    }
  }

  // ----------------------------------------------------------
  // PRODUCT NAME
  // ----------------------------------------------------------
  //
  // Product name is usually not introduced by a fixed label.
  // Therefore we choose the first meaningful OCR line that
  // doesn't look like another declaration.
  // ----------------------------------------------------------

  final ignoredWords = [
    'mrp',
    'maximum retail price',
    'net qty',
    'net quantity',
    'net wt',
    'net weight',
    'net volume',
    'manufactured',
    'manufacture',
    'manufacturing',
    'packed',
    'packing',
    'imported',
    'marketed',
    'consumer care',
    'customer care',
    'helpline',
    'toll free',
    'contact us',
    'address',
    'ingredients',
    'barcode',
    'batch',
    'lot no',
    'expiry',
    'best before',
  ];

  for (final line in lines) {
    final cleanLine = line.trim();

    if (cleanLine.length < 3) {
      continue;
    }

    final lowerLine = cleanLine.toLowerCase();

    final looksLikeDeclaration = ignoredWords.any(
      (word) => lowerLine.contains(word),
    );

    final mostlyNumbers = RegExp(r'^[0-9\s./:-]+$').hasMatch(cleanLine);

    if (looksLikeDeclaration || mostlyNumbers) {
      continue;
    }

    data.productName = cleanExtractedValue(cleanLine);

    break;
  }

  // ----------------------------------------------------------
  // EXTRA FALLBACKS
  // ----------------------------------------------------------

  if (data.manufacturer.isEmpty) {
    final hasManufacturerKeyword =
        lowerText.contains('manufactured by') ||
        lowerText.contains('packed by') ||
        lowerText.contains('imported by') ||
        lowerText.contains('marketed by');

    if (hasManufacturerKeyword) {
      final line = lines.firstWhere((item) {
        final lower = item.toLowerCase();

        return lower.contains('manufactured by') ||
            lower.contains('packed by') ||
            lower.contains('imported by') ||
            lower.contains('marketed by');
      }, orElse: () => '');

      if (line.isNotEmpty) {
        data.manufacturer = cleanExtractedValue(line);
      }
    }
  }

  return data;
}

// ---------------------------
// CLEAN OCR VALUE
// ---------------------------

String cleanExtractedValue(String value) {
  var result = value.trim();

  result = result.replaceAll(RegExp(r'\s+'), ' ');

  result = result.replaceFirst(RegExp(r'^[\s:,\-]+'), '');

  result = result.replaceFirst(RegExp(r'[\s:,\-]+$'), '');

  return result;
}

// ============================================================
// COMPLIANCE CHECKER
// ============================================================

class ComplianceChecker {
  static ComplianceResult check(DeclarationData data) {
    final declarations = data.toMap();

    int passed = 0;
    int missing = 0;

    final missingItems = <String>[];

    for (final entry in declarations.entries) {
      if (entry.value.trim().isNotEmpty) {
        passed++;
      } else {
        missing++;
        missingItems.add(entry.key);
      }
    }

    return ComplianceResult(
      passed: passed,
      missing: missing,
      missingItems: missingItems,
    );
  }
}

// ============================================================
// ANALYSIS SCREEN
// ============================================================

class AnalysisScreen extends StatefulWidget {
  final File imageFile;
  final String packageType;
  final String category;

  const AnalysisScreen({
    super.key,
    required this.imageFile,
    required this.packageType,
    required this.category,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late final TextRecognizer _textRecognizer;

  final TextEditingController _notesController = TextEditingController();

  String rawOcrText = '';

  DeclarationData declarationData = DeclarationData();

  ComplianceResult? complianceResult;

  bool _analyzing = true;
  bool _ocrError = false;
  bool _isSaved = false;

  InspectionRecord? savedRecord;

  @override
  void initState() {
    super.initState();

    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    _performOCR();
  }

  // ----------------------------------------------------------
  // REAL GOOGLE ML KIT OCR
  // ----------------------------------------------------------

  Future<void> _performOCR() async {
    setState(() {
      _analyzing = true;
      _ocrError = false;
    });

    try {
      if (!await widget.imageFile.exists()) {
        throw Exception('Image file no longer exists.');
      }

      final inputImage = InputImage.fromFilePath(widget.imageFile.path);

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      rawOcrText = recognizedText.text;

      declarationData = parseDeclarations(rawOcrText);

      complianceResult = ComplianceChecker.check(declarationData);
    } catch (error) {
      rawOcrText = '';

      declarationData = DeclarationData();

      complianceResult = ComplianceChecker.check(declarationData);

      _ocrError = true;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _analyzing = false;
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  // ----------------------------------------------------------
  // SAVE INSPECTION
  // ----------------------------------------------------------

  Future<void> _saveInspection() async {
    if (_isSaved || complianceResult == null) {
      return;
    }

    final result = complianceResult!;

    final record = InspectionRecord(
      id: 'INS-${DateTime.now().millisecondsSinceEpoch}',
      dateTime: DateTime.now(),
      productName: declarationData.productName.isEmpty
          ? 'Unknown Product'
          : declarationData.productName,
      packageType: widget.packageType,
      category: widget.category,
      status: result.status,
      percentage: result.percentage,
      detected: result.passed,
      missing: result.missing,
      imagePath: widget.imageFile.path,
      notes: _notesController.text.trim(),
      declarations: declarationData.toMap(),
      missingItems: result.missingItems,
    );

    await InspectionStore.add(record);

    if (!mounted) {
      return;
    }

    setState(() {
      savedRecord = record;
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inspection saved successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ----------------------------------------------------------
  // OPEN REPORT
  // ----------------------------------------------------------

  void _openReport() {
    if (savedRecord == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReportScreen(record: savedRecord!)),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inspection Analysis',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: _analyzing ? _buildLoadingView() : _buildResultView(),
    );
  }

  // ----------------------------------------------------------
  // LOADING VIEW
  // ----------------------------------------------------------

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(25),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Analyzing Package',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Reading visible declarations using OCR...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'Google ML Kit Text Recognition',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // RESULT VIEW
  // ----------------------------------------------------------

  Widget _buildResultView() {
    final result = complianceResult!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // EVIDENCE IMAGE
          // --------------------------------------------------

          const SectionTitle(
            title: 'Evidence',
            subtitle: 'Image used for this inspection',
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            height: 230,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.file(widget.imageFile, fit: BoxFit.contain),
            ),
          ),

          const SizedBox(height: 24),

          // --------------------------------------------------
          // RESULT SUMMARY
          // --------------------------------------------------
          _buildComplianceSummary(result),

          const SizedBox(height: 24),

          // --------------------------------------------------
          // DECLARATIONS
          // --------------------------------------------------
          const SectionTitle(
            title: 'Detected Declarations',
            subtitle: 'Information extracted from the label',
          ),

          const SizedBox(height: 12),

          _buildDeclarationList(),

          const SizedBox(height: 24),

          // --------------------------------------------------
          // POTENTIAL ISSUES
          // --------------------------------------------------
          if (result.missingItems.isNotEmpty) _buildPotentialIssues(result),

          if (result.missingItems.isNotEmpty) const SizedBox(height: 24),

          // --------------------------------------------------
          // NOTES
          // --------------------------------------------------
          const SectionTitle(
            title: 'Inspector Notes',
            subtitle: 'Add observations before saving',
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter inspection observations...',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 58),
                child: Icon(Icons.notes_rounded),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // --------------------------------------------------
          // OCR WARNING
          // --------------------------------------------------
          if (_ocrError)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.18),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline, color: AppColors.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'OCR could not read the image. '
                      'Try another clear, well-lit image.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // --------------------------------------------------
          // RAW OCR
          // --------------------------------------------------
          if (rawOcrText.isNotEmpty) _buildRawOcrSection(),

          if (rawOcrText.isNotEmpty) const SizedBox(height: 20),

          // --------------------------------------------------
          // SAVE / REPORT
          // --------------------------------------------------
          if (!_isSaved)
            PrimaryButton(
              text: 'Save Inspection',
              icon: Icons.save_rounded,
              onPressed: _saveInspection,
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.18),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Inspection saved to local history.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            PrimaryButton(
              text: 'View Inspection Report',
              icon: Icons.description_rounded,
              onPressed: _openReport,
            ),
          ],

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text(
              'Back to Scan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ============================================================
  // PART 7/8
  // ANALYSIS RESULT COMPONENTS
  // ============================================================

  // ----------------------------------------------------------
  // COMPLIANCE SUMMARY
  // ----------------------------------------------------------

  Widget _buildComplianceSummary(ComplianceResult result) {
    final color = statusColor(result.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon(result.status), color: color, size: 30),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Screening Result',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      result.status,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${result.percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: result.percentage / 100,
              minHeight: 9,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _resultCount(
                  icon: Icons.check_circle_outline,
                  title: 'Detected',
                  value: result.passed.toString(),
                  color: AppColors.success,
                ),
              ),

              Container(width: 1, height: 35, color: Colors.grey.shade200),

              Expanded(
                child: _resultCount(
                  icon: Icons.error_outline,
                  title: 'Missing',
                  value: result.missing.toString(),
                  color: AppColors.danger,
                ),
              ),

              Container(width: 1, height: 35, color: Colors.grey.shade200),

              Expanded(
                child: _resultCount(
                  icon: Icons.list_alt_rounded,
                  title: 'Total',
                  value: result.total.toString(),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _resultMessage(result.status),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // RESULT COUNT
  // ----------------------------------------------------------

  Widget _resultCount({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 19, color: color),

        const SizedBox(height: 4),

        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------
  // RESULT MESSAGE
  // ----------------------------------------------------------

  String _resultMessage(String status) {
    switch (status) {
      case 'PASS':
        return 'All configured key declarations were detected '
            'in the OCR text. Inspector verification is still required.';

      case 'PARTIAL':
        return 'Most key declarations were detected, but some '
            'information requires attention or verification.';

      case 'VIOLATION':
        return 'Several key declarations were not detected. '
            'Treat these as potential issues requiring inspection.';

      default:
        return 'No usable declaration information was detected '
            'from the selected image.';
    }
  }

  // ----------------------------------------------------------
  // DECLARATION LIST
  // ----------------------------------------------------------

  Widget _buildDeclarationList() {
    final declarations = declarationData.toMap();

    return Column(
      children: declarations.entries
          .map(
            (entry) => _declarationCard(title: entry.key, value: entry.value),
          )
          .toList(),
    );
  }

  // ----------------------------------------------------------
  // DECLARATION CARD
  // ----------------------------------------------------------

  Widget _declarationCard({required String title, required String value}) {
    final detected = value.trim().isNotEmpty;

    final color = detected ? AppColors.success : AppColors.danger;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: detected
              ? AppColors.success.withValues(alpha: 0.18)
              : AppColors.danger.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              detected ? Icons.check_rounded : Icons.close_rounded,
              size: 21,
              color: color,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  detected ? value : 'Not detected',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: detected
                        ? AppColors.textSecondary
                        : AppColors.danger,
                    fontWeight: detected ? FontWeight.w400 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            detected ? 'DETECTED' : 'MISSING',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // POTENTIAL ISSUES
  // ----------------------------------------------------------

  Widget _buildPotentialIssues(ComplianceResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 23,
              ),
              SizedBox(width: 9),
              Text(
                'Potential Issues',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'The following declarations were not detected '
            'in the OCR text:',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 12),

          ...result.missingItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: AppColors.warning,
                    ),
                  ),

                  const SizedBox(width: 9),

                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'These are screening indicators, not final legal '
            'violation findings.',
            style: TextStyle(
              fontSize: 10.5,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // RAW OCR SECTION
  // ----------------------------------------------------------

  Widget _buildRawOcrSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: const Icon(
          Icons.text_snippet_outlined,
          color: AppColors.primary,
        ),
        title: const Text(
          'Raw OCR Text',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        subtitle: const Text(
          'View text detected from the image',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              rawOcrText,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// END OF ANALYSIS SCREEN
// ============================================================
// ============================================================
// PART 8A
// HISTORY + POTENTIAL ISSUES SCREEN
// ============================================================

// ============================================================
// HISTORY SCREEN
// ============================================================

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String searchQuery = '';

  List<InspectionRecord> get filteredRecords {
    if (searchQuery.trim().isEmpty) {
      return InspectionStore.records;
    }

    final query = searchQuery.trim().toLowerCase();

    return InspectionStore.records.where((record) {
      return record.productName.toLowerCase().contains(query) ||
          record.id.toLowerCase().contains(query) ||
          record.status.toLowerCase().contains(query) ||
          record.category.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _deleteRecord(InspectionRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Inspection?'),
          content: const Text(
            'This inspection will be removed '
            'from local history.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await InspectionStore.remove(record.id);

    if (!mounted) {
      return;
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Inspection deleted.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inspection History',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: Column(
        children: [
          // --------------------------------------------------
          // SEARCH
          // --------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search product, ID or status',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),

          // --------------------------------------------------
          // RECORD COUNT
          // --------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 7),
                Text(
                  '${records.length} inspection'
                  '${records.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          // --------------------------------------------------
          // LIST
          // --------------------------------------------------
          Expanded(
            child: records.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: EmptyState(
                      icon: searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.history_rounded,
                      title: searchQuery.isNotEmpty
                          ? 'No matching inspections'
                          : 'No inspection history',
                      message: searchQuery.isNotEmpty
                          ? 'Try a different product name, '
                                'inspection ID or status.'
                          : 'Saved inspections will appear '
                                'here automatically.',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 25),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];

                      return _historyCard(record);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // HISTORY CARD
  // ----------------------------------------------------------

  Widget _historyCard(InspectionRecord record) {
    final color = statusColor(record.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReportScreen(record: record)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(statusIcon(record.status), color: color, size: 25),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      record.category,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      formatDateTime(record.dateTime),
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      record.id,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(status: record.status),

                  const SizedBox(height: 7),

                  Text(
                    '${record.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),

                  const SizedBox(height: 5),

                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteRecord(record);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: AppColors.danger),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// POTENTIAL ISSUES SCREEN
// ============================================================

class ViolationScreen extends StatelessWidget {
  final InspectionRecord record;

  const ViolationScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final issues = record.missingItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Potential Issues',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------
            // HEADER
            // ------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 32,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inspection Attention',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          record.productName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ------------------------------------------------
            // ISSUE COUNT
            // ------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.09),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.danger,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${issues.length} potential issue'
                          '${issues.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Declarations not detected by OCR',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (issues.isEmpty)
              const EmptyState(
                icon: Icons.check_circle_outline,
                title: 'No missing declarations detected',
                message:
                    'All configured declarations were detected '
                    'in the OCR text for this inspection.',
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    title: 'Declarations to Verify',
                    subtitle: 'Review these items manually',
                  ),

                  const SizedBox(height: 12),

                  ...issues.map(
                    (issue) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.danger,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              issue,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 15),

            // ------------------------------------------------
            // DISCLAIMER
            // ------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'These are automated screening indicators. '
                      'Absence from OCR does not by itself establish '
                      'a legal violation. The inspector should verify '
                      'the physical package and applicable requirements.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------
            // REPORT BUTTON
            // ------------------------------------------------
            PrimaryButton(
              text: 'View Full Report',
              icon: Icons.description_rounded,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportScreen(record: record),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
// ============================================================
// PART 8B
// PHASE 3I - PROFESSIONAL REPORT + PDF
// PHASE 3J - FINAL POLISH
// ============================================================

// ============================================================
// REPORT SCREEN
// ============================================================

class ReportScreen extends StatelessWidget {
  final InspectionRecord record;

  const ReportScreen({super.key, required this.record});

  Color get _statusColor {
    return statusColor(record.status);
  }

  // ----------------------------------------------------------
  // BUILD PDF
  // ----------------------------------------------------------

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final pdf = pw.Document();

    pw.MemoryImage? evidenceImage;

    try {
      final file = File(record.imagePath);

      if (await file.exists()) {
        final bytes = await file.readAsBytes();

        if (bytes.isNotEmpty) {
          evidenceImage = pw.MemoryImage(bytes);
        }
      }
    } catch (_) {
      evidenceImage = null;
    }

    final declarationRows = record.declarations.entries
        .map(
          (entry) => [
            pdfSafe(entry.key),
            entry.value.trim().isEmpty ? 'Not detected' : pdfSafe(entry.value),
            entry.value.trim().isEmpty ? 'MISSING' : 'DETECTED',
          ],
        )
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(30),

        header: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.7),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'NIRIKSHAN',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.Text(
                  'Inspection Report',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },

        footer: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Nirikshan - SIH 2026',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Page ${context.pageNumber}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },

        build: (context) {
          return [
            pw.SizedBox(height: 15),

            pw.Text(
              'PACKAGED COMMODITY INSPECTION REPORT',
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 5),

            pw.Text(
              'Automated declaration screening report',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),

            pw.SizedBox(height: 18),

            // ----------------------------------------------
            // INSPECTION INFORMATION
            // ----------------------------------------------
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                children: [
                  _pdfInfoRow('Inspection ID', record.id),
                  _pdfInfoRow('Date & Time', formatDateTime(record.dateTime)),
                  _pdfInfoRow('Product', record.productName),
                  _pdfInfoRow('Package Type', record.packageType),
                  _pdfInfoRow('Category', record.category),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            // ----------------------------------------------
            // RESULT
            // ----------------------------------------------
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _pdfStatusBackground(record.status),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SCREENING RESULT',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        pdfSafe(record.status),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: _pdfStatusColor(record.status),
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    '${record.percentage.toStringAsFixed(0)}%',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: _pdfStatusColor(record.status),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            // ----------------------------------------------
            // COUNTS
            // ----------------------------------------------
            pw.Row(
              children: [
                _pdfCountBox(
                  'Detected',
                  record.detected.toString(),
                  PdfColors.green,
                ),
                pw.SizedBox(width: 8),
                _pdfCountBox(
                  'Missing',
                  record.missing.toString(),
                  PdfColors.red,
                ),
                pw.SizedBox(width: 8),
                _pdfCountBox(
                  'Total',
                  (record.detected + record.missing).toString(),
                  PdfColors.blue,
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // ----------------------------------------------
            // EVIDENCE IMAGE
            // ----------------------------------------------
            if (evidenceImage != null) ...[
              pw.Text(
                'EVIDENCE IMAGE',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Container(
                width: double.infinity,
                height: 230,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Image(evidenceImage, fit: pw.BoxFit.contain),
              ),

              pw.SizedBox(height: 20),
            ],

            // ----------------------------------------------
            // DECLARATIONS TABLE
            // ----------------------------------------------
            pw.Text(
              'DECLARATION SCREENING',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              headers: ['Declaration', 'Detected Value', 'Status'],
              data: declarationRows,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.all(6),
            ),

            // ----------------------------------------------
            // POTENTIAL ISSUES
            // ----------------------------------------------
            if (record.missingItems.isNotEmpty) ...[
              pw.SizedBox(height: 20),

              pw.Text(
                'POTENTIAL ISSUES TO VERIFY',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
              ),

              pw.SizedBox(height: 7),

              ...record.missingItems.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    '- ${pdfSafe(item)}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ),
            ],

            // ----------------------------------------------
            // NOTES
            // ----------------------------------------------
            if (record.notes.trim().isNotEmpty) ...[
              pw.SizedBox(height: 20),

              pw.Text(
                'INSPECTOR NOTES',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height: 7),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  pdfSafe(record.notes),
                  style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
                ),
              ),
            ],

            pw.SizedBox(height: 22),

            // ----------------------------------------------
            // DISCLAIMER
            // ----------------------------------------------
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              color: PdfColors.grey100,
              child: pw.Text(
                'Important: This report represents automated '
                'declaration screening based on text detected '
                'from the supplied image. Missing or detected '
                'information should be physically verified by '
                'the inspector. This report is not, by itself, '
                'a final legal determination.',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                  lineSpacing: 2,
                ),
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ----------------------------------------------------------
  // PDF INFO ROW
  // ----------------------------------------------------------

  pw.Widget _pdfInfoRow(String title, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 105,
            child: pw.Text(
              pdfSafe(title),
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              pdfSafe(value),
              style: const pw.TextStyle(fontSize: 8),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // PDF COUNT BOX
  // ----------------------------------------------------------

  pw.Widget _pdfCountBox(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // PDF STATUS COLORS
  // ----------------------------------------------------------

  PdfColor _pdfStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PASS':
        return PdfColors.green800;

      case 'PARTIAL':
        return PdfColors.orange800;

      case 'VIOLATION':
        return PdfColors.red800;

      default:
        return PdfColors.grey700;
    }
  }

  PdfColor _pdfStatusBackground(String status) {
    switch (status.toUpperCase()) {
      case 'PASS':
        return PdfColors.green50;

      case 'PARTIAL':
        return PdfColors.orange50;

      case 'VIOLATION':
        return PdfColors.red50;

      default:
        return PdfColors.grey100;
    }
  }

  // ----------------------------------------------------------
  // PRINT / PREVIEW
  // ----------------------------------------------------------

  Future<void> _printReport(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) {
          return _buildPdf(format);
        },
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open PDF preview: $error')),
      );
    }
  }

  // ----------------------------------------------------------
  // SHARE / SAVE PDF
  // ----------------------------------------------------------

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final bytes = await _buildPdf(PdfPageFormat.a4);

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Nirikshan_${record.id}.pdf',
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to share PDF: $error')));
    }
  }

  // ----------------------------------------------------------
  // SCREEN UI
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inspection Report',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Potential Issues',
            onPressed: record.missingItems.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViolationScreen(record: record),
                      ),
                    );
                  },
            icon: const Icon(Icons.warning_amber_rounded),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------
            // REPORT HEADER
            // ------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inspection Report',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          record.id,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------
            // RESULT CARD
            // ------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusIcon(record.status),
                      color: _statusColor,
                      size: 34,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Screening Result',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.status,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    '${record.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _statusColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------
            // BASIC INFORMATION
            // ------------------------------------------------
            const SectionTitle(title: 'Inspection Details'),

            const SizedBox(height: 12),

            _infoCard(
              Icons.inventory_2_outlined,
              'Product',
              record.productName,
            ),

            _infoCard(Icons.category_outlined, 'Category', record.category),

            _infoCard(
              Icons.all_inbox_outlined,
              'Package Type',
              record.packageType,
            ),

            _infoCard(
              Icons.schedule_rounded,
              'Inspection Time',
              formatDateTime(record.dateTime),
            ),

            const SizedBox(height: 20),

            // ------------------------------------------------
            // EVIDENCE
            // ------------------------------------------------
            const SectionTitle(
              title: 'Evidence Photo',
              subtitle: 'Image used for automated screening',
            ),

            const SizedBox(height: 12),

            _buildEvidenceImage(),

            const SizedBox(height: 22),

            // ------------------------------------------------
            // DECLARATIONS
            // ------------------------------------------------
            const SectionTitle(
              title: 'Declaration Results',
              subtitle: 'Detected and missing label information',
            ),

            const SizedBox(height: 12),

            ...record.declarations.entries.map(
              (entry) => _reportDeclaration(entry.key, entry.value),
            ),

            // ------------------------------------------------
            // POTENTIAL ISSUES
            // ------------------------------------------------
            if (record.missingItems.isNotEmpty) ...[
              const SizedBox(height: 22),

              const SectionTitle(
                title: 'Potential Issues',
                subtitle: 'Items requiring inspector verification',
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...record.missingItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Icon(
                                Icons.circle,
                                size: 6,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
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

            // ------------------------------------------------
            // NOTES
            // ------------------------------------------------
            if (record.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 22),

              const SectionTitle(title: 'Inspector Notes'),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(
                  record.notes,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 22),

            // ------------------------------------------------
            // DISCLAIMER
            // ------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This report is an automated declaration '
                      'screening aid. The inspector must verify '
                      'the physical package and applicable '
                      'requirements before making a final '
                      'legal determination.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ------------------------------------------------
            // PDF BUTTONS
            // ------------------------------------------------
            PrimaryButton(
              text: 'Preview / Print PDF',
              icon: Icons.picture_as_pdf_rounded,
              onPressed: () {
                _printReport(context);
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  _sharePdf(context);
                },
                icon: const Icon(Icons.share_rounded),
                label: const Text(
                  'Share / Save PDF',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text(
                  'Back',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // INFO CARD
  // ----------------------------------------------------------

  Widget _infoCard(IconData icon, String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 11),
          Text(
            '$title:',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // EVIDENCE IMAGE
  // ----------------------------------------------------------

  Widget _buildEvidenceImage() {
    final file = File(record.imagePath);

    if (!file.existsSync()) {
      return Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 40,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 8),
            Text(
              'Evidence image unavailable',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 270,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.file(file, fit: BoxFit.contain),
      ),
    );
  }

  // ----------------------------------------------------------
  // REPORT DECLARATION
  // ----------------------------------------------------------

  Widget _reportDeclaration(String title, String value) {
    final detected = value.trim().isNotEmpty;

    final color = detected ? AppColors.success : AppColors.danger;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            detected ? Icons.check_circle : Icons.cancel,
            color: color,
            size: 21,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  detected ? value : 'Not detected',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: detected
                        ? AppColors.textSecondary
                        : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            detected ? 'FOUND' : 'MISSING',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// END OF NIRIKSHAN main.dart
// ============================================================
