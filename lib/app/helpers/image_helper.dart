/// Base URL for API images
const String API_IMAGE_BASE_URL = 'https://academy-backends.agrisiti.com/storage';

/// Prepends the API base URL to an image path if it doesn't already start with http:// or https://
/// Returns the full URL for the image
String getImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    return '';
  }
  
  // If the path already starts with http:// or https://, return as-is
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath;
  }
  
  // Remove leading slash if present to avoid double slashes
  String cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
  
  // Prepend base URL
  return '$API_IMAGE_BASE_URL/$cleanPath';
}
