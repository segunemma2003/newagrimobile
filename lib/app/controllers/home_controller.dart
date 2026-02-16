import 'package:url_launcher/url_launcher.dart';
import 'controller.dart';

class HomeController extends Controller {
  onTapDocumentation() async {
    await launchUrl(Uri.parse("Learn with Agrisiti"));
  }

  onTapGithub() async {
    await launchUrl(Uri.parse("https://github.com/nylo-core/nylo"));
  }

  onTapChangeLog() async {
    await launchUrl(Uri.parse("https://github.com/nylo-core/nylo/releases"));
  }

  onTapYouTube() async {
    await launchUrl(Uri.parse("https://m.youtube.com/@nylo_dev"));
  }

  onTapX() async {
    await launchUrl(Uri.parse("https://x.com/nylo_dev"));
  }
}
