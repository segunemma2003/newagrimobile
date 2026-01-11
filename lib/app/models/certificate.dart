import 'package:nylo_framework/nylo_framework.dart';

class Certificate extends Model {
  String? id;
  String? courseId;
  String? courseName;
  String? certificateImageUrl;
  DateTime? completedDate;
  String? certificateUrl; // For download

  static StorageKey key = 'certificates';

  Certificate() : super(key: key);

  Certificate.fromJson(dynamic data) {
    id = data['id']?.toString();
    courseId = data['course_id']?.toString() ?? data['courseId']?.toString();
    courseName = data['course_name'] ?? data['courseName'];
    certificateImageUrl = data['certificate_image_url'] ?? data['certificateImageUrl'];
    certificateUrl = data['certificate_url'] ?? data['certificateUrl'];
    if (data['completed_date'] != null || data['completedDate'] != null) {
      completedDate = DateTime.tryParse(
          data['completed_date']?.toString() ?? data['completedDate']?.toString() ?? '');
    }
  }

  @override
  toJson() => {
        "id": id,
        "course_id": courseId,
        "course_name": courseName,
        "certificate_image_url": certificateImageUrl,
        "certificate_url": certificateUrl,
        "completed_date": completedDate?.toIso8601String(),
      };
}
