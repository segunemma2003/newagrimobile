import 'package:html/parser.dart' show parse;

/// Strips HTML tags from a string and returns plain text
String stripHtmlTags(String? htmlString) {
  if (htmlString == null || htmlString.isEmpty) {
    return '';
  }
  
  // Parse HTML and extract text content
  final document = parse(htmlString);
  final String plainText = document.body?.text ?? '';
  
  // Clean up extra whitespace
  return plainText
      .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
      .trim(); // Remove leading/trailing whitespace
}
