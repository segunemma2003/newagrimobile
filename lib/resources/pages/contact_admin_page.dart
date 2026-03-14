import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:url_launcher/url_launcher.dart';
import '/resources/widgets/safearea_widget.dart';

class ContactAdminPage extends NyStatefulWidget {
  static RouteView path = ("/contact-admin", (_) => ContactAdminPage());

  ContactAdminPage({super.key}) : super(child: () => _ContactAdminPageState());
}

class _ContactAdminPageState extends NyPage<ContactAdminPage> {
  @override
  Widget view(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Contact Admin",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeAreaWidget(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2D8659).withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF2D8659), size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Kana da tambaya ko buƙatar taimako? Tuntuɓi mu ta WhatsApp kuma zamu amsa muku nan ba da jimawa ba.",
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2D8659),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Contact via WhatsApp Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Open WhatsApp with the phone number
                    final phoneNumber = '447907853788'; // Remove + for WhatsApp URL
                    final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
                    
                    try {
                      if (await canLaunchUrl(whatsappUri)) {
                        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                      } else {
                        // Fallback: try alternative WhatsApp URL format
                        final Uri altWhatsappUri = Uri.parse('whatsapp://send?phone=$phoneNumber');
                        if (await canLaunchUrl(altWhatsappUri)) {
                          await launchUrl(altWhatsappUri, mode: LaunchMode.externalApplication);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "WhatsApp is not installed. Please install WhatsApp to contact admin.",
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Could not open WhatsApp: $e",
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text(
                    "Tuntuɓi Admin ta WhatsApp",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp green
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Contact Information
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Wasu Hanyoyin Tuntuɓar Mu",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildContactItem(
                      icon: Icons.email_outlined,
                      title: "Imel",
                      value: "info@agrisiti.com",
                      onTap: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'info@agrisiti.com',
                        );
                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not open email client"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      icon: Icons.phone_outlined,
                      title: "Wayar",
                      value: "+447907853788",
                      onTap: () async {
                        final Uri phoneUri = Uri(
                          scheme: 'tel',
                          path: '+447907853788',
                        );
                        if (await canLaunchUrl(phoneUri)) {
                          await launchUrl(phoneUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Could not open phone dialer"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(
                      icon: Icons.access_time_outlined,
                      title: "Lokacin Amsa",
                      value: "Yawanci cikin sa'o'i 24",
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

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2D8659), size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: onTap != null 
                        ? const Color(0xFF2D8659) 
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            if (onTap != null) ...[
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
