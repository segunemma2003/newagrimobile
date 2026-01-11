import '/app/controllers/home_controller.dart';
import '/app/controllers/login_controller.dart';
import '/app/controllers/register_controller.dart';
import '/app/controllers/courses_controller.dart';
import '/app/controllers/course_detail_controller.dart';
import '/app/controllers/lesson_controller.dart';
import '/app/models/user.dart';
import '/app/models/category.dart';
import '/app/models/course.dart';
import '/app/models/lesson.dart';
import '/app/models/quiz.dart';
import '/app/models/course_progress.dart';
import '/app/networking/api_service.dart';

/* Model Decoders
|--------------------------------------------------------------------------
| Model decoders are used in 'app/networking/' for morphing json payloads
| into Models.
|
| Learn more https://nylo.dev/docs/6.x/decoders#model-decoders
|-------------------------------------------------------------------------- */

final Map<Type, dynamic> modelDecoders = {
  Map<String, dynamic>: (data) => Map<String, dynamic>.from(data),

  List<User>: (data) =>
      List.from(data).map((json) => User.fromJson(json)).toList(),
  User: (data) => User.fromJson(data),

  List<Category>: (data) =>
      List.from(data).map((json) => Category.fromJson(json)).toList(),
  Category: (data) => Category.fromJson(data),

  List<Course>: (data) =>
      List.from(data).map((json) => Course.fromJson(json)).toList(),
  Course: (data) => Course.fromJson(data),

  List<Lesson>: (data) =>
      List.from(data).map((json) => Lesson.fromJson(json)).toList(),
  Lesson: (data) => Lesson.fromJson(data),

  List<Quiz>: (data) =>
      List.from(data).map((json) => Quiz.fromJson(json)).toList(),
  Quiz: (data) => Quiz.fromJson(data),

  List<CourseProgress>: (data) =>
      List.from(data).map((json) => CourseProgress.fromJson(json)).toList(),
  CourseProgress: (data) => CourseProgress.fromJson(data),
};

/* API Decoders
| -------------------------------------------------------------------------
| API decoders are used when you need to access an API service using the
| 'api' helper. E.g. api<MyApiService>((request) => request.fetchData());
|
| Learn more https://nylo.dev/docs/6.x/decoders#api-decoders
|-------------------------------------------------------------------------- */

final Map<Type, dynamic> apiDecoders = {
  ApiService: () => ApiService(),

  // ...
};

/* Controller Decoders
| -------------------------------------------------------------------------
| Controller are used in pages.
|
| Learn more https://nylo.dev/docs/6.x/controllers
|-------------------------------------------------------------------------- */
final Map<Type, dynamic> controllers = {
  HomeController: () => HomeController(),
  LoginController: () => LoginController(),
  RegisterController: () => RegisterController(),
  CoursesController: () => CoursesController(),
  CourseDetailController: () => CourseDetailController(),
  LessonController: () => LessonController(),

  // ...
};
