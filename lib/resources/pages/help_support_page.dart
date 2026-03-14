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
                    color: Colors.black.withValues(alpha: 0.05),
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
                    "Need Help?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Contact our support team for additional assistance",
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
                        "Contact Admin",
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
              "Frequently Asked Questions (FAQ)",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              question: "How do I start a lesson?",
              answer: "You can start a lesson by tapping on the lesson you want from the course list. Then, tap the 'Start' button to begin.",
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: "How do I take a quiz?",
              answer: "The quiz will appear after you complete a lesson. Tap the 'Start Quiz' button to begin.",
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: "Can I use the app without internet?",
              answer: "Yes, you can use downloaded courses offline without internet. However, internet is required to download new courses.",
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              question: "How do I update downloaded content?",
              answer: "Tap the 'Sync' button on the courses page to update downloaded content.",
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
                    "Contact Information",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactItem(
                    icon: Icons.email_outlined,
                    title: "Email",
                    value: "info@agrisiti.com",
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.phone_outlined,
                    title: "Phone",
                    value: "+447907853788",
                  ),
                  const SizedBox(height: 12),
                  _buildContactItem(
                    icon: Icons.access_time_outlined,
                    title: "Working Hours",
                    value: "Monday - Friday, 9AM - 5PM",
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
