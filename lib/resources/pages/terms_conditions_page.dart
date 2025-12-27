import 'package:flutter/material.dart';
import 'package:nylo_framework/nylo_framework.dart';

class TermsConditionsPage extends NyStatefulWidget {
  static RouteView path = ("/terms-conditions", (_) => TermsConditionsPage());

  TermsConditionsPage({super.key}) : super(child: () => _TermsConditionsPageState());
}

class _TermsConditionsPageState extends NyPage<TermsConditionsPage> {
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
          "Terms & Conditions",
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bayanin Buga:",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Oktoba 2024",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "1. Gamsuwa da Amfani",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Ta hanyar yin amfani da wannan aikace-aikacen, kana amincewa da duk sharuddan da aka kwatanta a nan. Idan baka yarda da waɗannan sharuddan ba, ka daina amfani da aikace-aikacen nan da nan.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "2. Bayanai da Asiri",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Muna mutunta sirrinku. Bayanan da kuka bayar za a kiyaye su cikin aminci. Muna amfani da bayanan ku ne kawai don inganta sabis ɗinmu da samar da kwarewa mafi kyau.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "3. Amfani da Abun Ciki",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Duk abun ciki na aikace-aikacen (darussa, hotuna, rubutu, da sauransu) mallaka ne na Agrisiti Academy. Ba za ka iya rarraba, sayarwa, ko sake yin amfani da abun ciki ba tare da izini ba.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "4. Ayyukan Masu Amfani",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Kana da alhakin duk ayyukan da ka yi ta aikace-aikacen. Ba za ka yi amfani da aikace-aikacen don wani dalili ba bisa ka'ida ba, ko don yin ayyuka masu cutarwa.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "5. Dakatarwa da Soke",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Muna da 'yancin dakatar ko soke damarkar amfani da aikace-aikacen a kowane lokaci ba tare da sanarwa ba idan ana cin zarafin waɗannan sharuddan.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "6. Canje-canje ga Sharuddan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Muna iya canza waɗannan sharuddan a kowane lokaci. Canje-canje za su fara aiki nan da nan bayan buga su a aikace-aikacen. Ci gaba da amfani da aikace-aikacen bayan canje-canje yana nufin kana amincewa da sabbin sharuddan.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
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
}

