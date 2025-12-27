import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';
import '/resources/pages/contact_admin_page.dart';

class HelpSupportPage extends NyStatefulWidget {
  static RouteView path = ("/help-support", (_) => HelpSupportPage());

  HelpSupportPage({super.key}) : super(child: () => _HelpSupportPageState());
}

class _HelpSupportPageState extends NyPage<HelpSupportPage> {
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
          "Help & Support",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Support Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 48,
                    color: Color(0xFF2D8659),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ana Bukatar Taimako?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tuntuɓi ƙungiyar tallafi don ƙarin taimako",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => routeTo(ContactAdminPage.path),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D8659),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Tuntuɓi Admin",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // FAQ Section
            const Text(
              "Tambayoyi da Amsoshi (FAQ)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              question: "Yaya zan fara darasi?",
              answer: "Za ka iya fara darasi ta hanyar danna darasin da kake so daga jerin darussa. Bayan haka, danna maɓallin 'Fara' don farawa.",
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: "Yaya zan ci jarabawar?",
              answer: "Jarabawar za ta fito ne bayan ka kammala darasin. Danna maɓallin 'Fara Jarabawa' don farawa.",
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: "Zan iya amfani da app ba tare da intanet ba?",
              answer: "Ee, za ka iya amfani da darussa da aka saukar a gida ba tare da intanet ba. Amma don saukar da sababbin darussa, ana buƙatar intanet.",
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: "Yaya zan sabunta bayanan da aka saukar?",
              answer: "Danna maɓallin 'Sync' a shafin darussa don sabunta bayanan da aka saukar.",
            ),
            const SizedBox(height: 24),
            // Contact Information
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Lambar Tuntuɓi",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    title: "Imel",
                    value: "tallafi@agrisiti.com",
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.phone_outlined,
                    title: "Wayar",
                    value: "+234 123 456 7890",
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.access_time_outlined,
                    title: "Lokacin Aiki",
                    value: "Litinin - Jumma'a, 9AM - 5PM",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

