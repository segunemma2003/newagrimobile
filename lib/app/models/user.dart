import 'package:nylo_framework/nylo_framework.dart';

class User extends Model {
  String? id;
  String? name;
  String? email;
  String? phone;
  String? role;
  String? avatar;
  String? bio;
  bool? isActive;
  String? createdAt;
  String? updatedAt;

  static StorageKey key = 'user';

  User() : super(key: key);

  User.fromJson(dynamic data) {
    id = data['id']?.toString();
    name = data['name'];
    email = data['email'];
    phone = data['phone'];
    role = data['role'];
    avatar = data['avatar'];
    bio = data['bio'];
    isActive = data['is_active'] ?? data['isActive'];
    createdAt = data['created_at'] ?? data['createdAt'];
    updatedAt = data['updated_at'] ?? data['updatedAt'];
  }

  @override
  toJson() => {
        "id": id,
        "name": name,
        "email": email,
        "phone": phone,
        "role": role,
        "avatar": avatar,
        "bio": bio,
        "is_active": isActive,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
