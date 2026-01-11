import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/app/models/certificate.dart';
import '/config/keys.dart';

class CertificatesPage extends NyStatefulWidget {
  static RouteView path = ("/certificates", (_) => CertificatesPage());

  CertificatesPage({super.key}) : super(child: () => _CertificatesPageState());
}

class _CertificatesPageState extends NyPage<CertificatesPage> {
  List<Certificate> _certificates = [];
  String _searchQuery = "";
  TextEditingController? _searchController;

  // Color scheme - maintain from other pages
  static const Color primary = Color(0xFF3F6967);
  static const Color secondary = Color(0xFF50C1AE);
  static const Color backgroundLight = Color(0xFFF6F7F7);
  static const Color backgroundDark = Color(0xFF161C1B);
  static const Color secondaryTextColor = Color(0xFF6F7B7B);

  @override
  get init => () async {
        _searchController = TextEditingController();
        await _loadCertificates();
      };

  Future<void> _loadCertificates() async {
    try {
      final certificatesJson = await Keys.certificates.read<List>();
      if (certificatesJson != null) {
        _certificates = certificatesJson
            .map((c) => Certificate.fromJson(c))
            .toList();
        setState(() {});
      } else {
        // Load dummy data
        _loadDummyCertificates();
      }
    } catch (e) {
      print('Error loading certificates: $e');
      _loadDummyCertificates();
    }
  }

  void _loadDummyCertificates() {
    _certificates = [
      Certificate()
        ..id = "1"
        ..courseName = "Sustainable Urban Farming"
        ..certificateImageUrl = "https://lh3.googleusercontent.com/aida-public/AB6AXuALC_hKO4kNq8I2Cj5EfUeThP3ZRrnK-Cksqkml7egbZPQIB--M69mJ_mJXozuh0GlJX62X3ZsoQQGdZ_eZeGVb9AUJBVbSjerRR0h9DhtDF5wwQ0Suo1iQoYmmHgexLy52XeUNUxX1YKvjDY2gmQwXdv3AcZmuwdO3NE6Z1FQ3swX0qXR9B9DZAdCbOZmLr5U_mXOUN_yCtHuwO16sZWRPR8VYirCGXhFoJ6GbH3mzjRao7MmMsywCUfvwuURPN3Ul1ji1EgXBRpk"
        ..completedDate = DateTime(2023, 10, 12),
      Certificate()
        ..id = "2"
        ..courseName = "Agribusiness Management"
        ..certificateImageUrl = "https://lh3.googleusercontent.com/aida-public/AB6AXuBBdsXGTzEMXq2lxVYSdlvbuB0MOdwYy9DV_IGc5Z4Mi8EL36QfUnKry2hEQbUPrVKnwSWYYd_R8TR9cegJ5v6MSMk1oBz5eDm7oW6cGgDM15yvoD7jqPRhyu7cMSxi1VAw4f7p93FGVGV6qMnWZXfe2WQb3fgazcseRgTaE8YPLf0RwLpuquAPlW0HarQSMDnwtaMiez15vLlmgs-jz-4lr8UkeEhW2w5mNsKMCL72BNnwHupr5kUwSNqkWfyoZWAmm5aJyj_KmNs"
        ..completedDate = DateTime(2023, 9, 5),
    ];
    setState(() {});
  }

  List<Certificate> get _filteredCertificates {
    if (_searchQuery.isEmpty) {
      return _certificates;
    }
    return _certificates.where((cert) {
      return cert.courseName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
    }).toList();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return 'Completed on ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _downloadCertificate(Certificate certificate) async {
    // In a real app, you would download the certificate PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Downloading certificate for ${certificate.courseName}..."),
        backgroundColor: secondary,
      ),
    );
  }

  Future<void> _shareCertificate(Certificate certificate) async {
    // In a real app, you would share the certificate
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Sharing certificate for ${certificate.courseName}..."),
        backgroundColor: secondary,
      ),
    );
  }

  @override
  void dispose() {
    _searchController?.dispose();
    super.dispose();
  }

  @override
  LoadingStyle get loadingStyle => LoadingStyle.normal();

  @override
  Widget view(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? backgroundDark : backgroundLight;
    final Color surfaceColor = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF131515);
    final secondaryTextColor = isDark ? Colors.grey[400]! : const Color(0xFF6F7B7B);
    final Color borderColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100]!;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "My Certificates",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primary,
                        letterSpacing: -0.015,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // TODO: Open search
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.search,
                          color: primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Earned Certificates Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Text(
                        "Earned Certificates",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primary,
                          letterSpacing: -0.015,
                        ),
                      ),
                    ),
                    // Certificate Cards
                    ..._filteredCertificates.map((cert) => _buildCertificateCard(
                      cert,
                      surfaceColor,
                      textColor,
                      secondaryTextColor,
                      borderColor,
                      isDark,
                    )),
                    const SizedBox(height: 24),
                    // Badges & Milestones Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Badges & Milestones",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primary,
                              letterSpacing: -0.015,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // TODO: View all badges
                            },
                            child: Text(
                              "View All",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Badges Scroll
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildBadge(
                            icon: Icons.bolt,
                            label: "Fast Learner",
                            level: "Lvl 3",
                            isActive: true,
                            isDark: isDark,
                            primary: primary,
                            secondary: secondary,
                          ),
                          const SizedBox(width: 16),
                          _buildBadge(
                            icon: Icons.calendar_today,
                            label: "7-Day Streak",
                            isActive: true,
                            isDark: isDark,
                            primary: primary,
                            secondary: secondary,
                          ),
                          const SizedBox(width: 16),
                          _buildBadge(
                            icon: Icons.workspace_premium,
                            label: "Top 1%",
                            isActive: false,
                            isDark: isDark,
                            primary: primary,
                            secondary: secondary,
                          ),
                          const SizedBox(width: 16),
                          _buildBadge(
                            icon: Icons.groups,
                            label: "Community",
                            isActive: true,
                            isDark: isDark,
                            primary: primary,
                            secondary: secondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateCard(
    Certificate certificate,
    Color surfaceColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        certificate.courseName ?? 'Unknown Course',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? secondary : primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(certificate.completedDate),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 128,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[100]!,
                    ),
                    image: certificate.certificateImageUrl != null &&
                            certificate.certificateImageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(certificate.certificateImageUrl!),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
                    color: certificate.certificateImageUrl == null ||
                            certificate.certificateImageUrl!.isEmpty
                        ? Colors.grey[200]
                        : null,
                  ),
                  child: certificate.certificateImageUrl == null ||
                          certificate.certificateImageUrl!.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.card_membership,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              height: 1,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadCertificate(certificate),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text("Download"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _shareCertificate(certificate),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.share,
                        color: isDark ? secondary : primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    String? level,
    required bool isActive,
    required bool isDark,
    required Color primary,
    required Color secondary,
  }) {
    return Container(
      width: 80,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? (icon == Icons.bolt || icon == Icons.groups
                          ? secondary.withOpacity(0.1)
                          : primary.withOpacity(0.1))
                      : (isDark ? Colors.grey[800] : Colors.grey[200]),
                  border: Border.all(
                    color: isActive
                        ? (icon == Icons.bolt || icon == Icons.groups
                            ? secondary.withOpacity(0.3)
                            : primary.withOpacity(0.3))
                        : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isActive
                      ? (icon == Icons.bolt || icon == Icons.groups ? secondary : primary)
                      : Colors.grey[400],
                ),
              ),
              if (level != null && isActive)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      level,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? (isDark ? Colors.white : primary)
                  : secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
