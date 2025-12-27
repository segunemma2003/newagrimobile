import 'package:nylo_framework/nylo_framework.dart';

class Category extends Model {
  String? id;
  String? name;
  String? slug;
  String? description;
  String? image;
  String? icon;
  bool? isActive;
  int? sortOrder;

  static StorageKey key = 'categories';

  Category() : super(key: key);

  Category.fromJson(dynamic data) {
    id = data['id']?.toString();
    name = data['name'];
    slug = data['slug'];
    description = data['description'];
    image = data['image'];
    icon = data['icon'];
    isActive = data['is_active'] ?? data['isActive'];
    sortOrder = data['sort_order'] ?? data['sortOrder'];
  }

  @override
  toJson() => {
        "id": id,
        "name": name,
        "slug": slug,
        "description": description,
        "image": image,
        "icon": icon,
        "is_active": isActive,
        "sort_order": sortOrder,
      };
}




