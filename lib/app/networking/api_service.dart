import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '/config/decoders.dart';
import '/config/keys.dart';
import 'package:nylo_framework/nylo_framework.dart';

/* ApiService
| -------------------------------------------------------------------------
| Define your API endpoints
| Learn more https://nylo.dev/docs/6.x/networking
|-------------------------------------------------------------------------- */

class ApiService extends NyApiService {
  ApiService({BuildContext? buildContext})
      : super(
          buildContext,
          decoders: modelDecoders,
          // baseOptions: (BaseOptions baseOptions) {
          //   return baseOptions
          //             ..connectTimeout = Duration(seconds: 5)
          //             ..sendTimeout = Duration(seconds: 5)
          //             ..receiveTimeout = Duration(seconds: 5);
          // },
        );

  @override
  String get baseUrl => getEnv('API_BASE_URL');

  @override
  get interceptors => {
        if (getEnv('APP_DEBUG') == true) PrettyDioLogger: PrettyDioLogger(),
        // MyCustomInterceptor: MyCustomInterceptor(),
      };

  Future fetchTestData() async {
    return await network(
      request: (request) => request.get("/endpoint-path"),
    );
  }

  /// Example to fetch the Nylo repository info from Github
  Future githubInfo() async {
    return await network(
      request: (request) =>
          request.get("https://api.github.com/repos/nylo-core/nylo"),
      cacheKey: "github_nylo_info", // Optional: Cache the response
      cacheDuration: const Duration(hours: 1),
    );
  }

  // ==================== Authentication Endpoints ====================

  /// Login endpoint - POST /login
  Future login({required String email, required String password}) async {
    return await network(
      request: (request) => request.post(
        "/login",
        data: {"email": email, "password": password},
      ),
    );
  }

  /// Register endpoint - POST /register
  Future register({
    required String name,
    required String email,
    required String password,
  }) async {
    return await network(
      request: (request) => request.post(
        "/register",
        data: {
          "name": name,
          "email": email,
          "password": password,
        },
      ),
    );
  }

  /// Get current user - GET /user
  Future getCurrentUser() async {
    return await network(
      request: (request) => request.get("/user"),
    );
  }

  /// Update profile - PUT /user/profile
  Future updateProfile(Map<String, dynamic> data) async {
    return await network(
      request: (request) => request.put("/user/profile", data: data),
    );
  }

  /// Logout - POST /logout
  Future logout() async {
    return await network(
      request: (request) => request.post("/logout"),
    );
  }

  /// Forgot password - POST /forgot-password
  Future forgotPassword(String email) async {
    return await network(
      request: (request) => request.post(
        "/forgot-password",
        data: {"email": email},
      ),
    );
  }

  /// Reset password - POST /reset-password
  Future resetPassword({
    required String token,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await network(
      request: (request) => request.post(
        "/reset-password",
        data: {
          "token": token,
          "email": email,
          "password": password,
          "password_confirmation": passwordConfirmation,
        },
      ),
    );
  }

  // ==================== Categories Endpoints ====================

  /// Get all categories - GET /categories
  Future fetchCategories() async {
    return await network(
      request: (request) => request.get("/categories"),
      cacheKey: "categories",
      cacheDuration: const Duration(hours: 24),
    );
  }

  /// Get category details - GET /categories/{category_id}
  Future fetchCategory(String categoryId) async {
    return await network(
      request: (request) => request.get("/categories/$categoryId"),
      cacheKey: "category_$categoryId",
      cacheDuration: const Duration(hours: 24),
    );
  }

  /// Get categories with courses - GET /categories-with-courses
  Future fetchCategoriesWithCourses() async {
    return await network(
      request: (request) => request.get("/categories-with-courses"),
      cacheKey: "categories_with_courses",
      cacheDuration: const Duration(hours: 12),
    );
  }

  /// Get featured courses - GET /featured-courses
  Future fetchFeaturedCourses() async {
    return await network(
      request: (request) => request.get("/featured-courses"),
      cacheKey: "featured_courses",
      cacheDuration: const Duration(hours: 12),
    );
  }

  // ==================== Courses Endpoints ====================

  /// Get all courses - GET /courses
  Future fetchCourses({
    String? categoryId,
    String? level,
    double? minRating,
    int? minDuration,
    int? maxDuration,
    String? search,
    int? perPage,
  }) async {
    return await network(
      request: (request) {
        var queryParams = <String, dynamic>{};
        if (categoryId != null) queryParams['category_id'] = categoryId;
        if (level != null) queryParams['level'] = level;
        if (minRating != null) queryParams['min_rating'] = minRating;
        if (minDuration != null) queryParams['min_duration'] = minDuration;
        if (maxDuration != null) queryParams['max_duration'] = maxDuration;
        if (search != null) queryParams['search'] = search;
        if (perPage != null) queryParams['per_page'] = perPage;
        return request.get("/courses", queryParameters: queryParams);
      },
      cacheKey: "courses_${categoryId ?? 'all'}",
      cacheDuration: const Duration(minutes: 30),
    );
  }

  /// Get course details - GET /courses/{course_id}
  Future fetchCourse(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId"),
      cacheKey: "course_$courseId",
      cacheDuration: const Duration(minutes: 30),
    );
  }

  /// Get recommended courses - GET /recommended-courses
  Future fetchRecommendedCourses() async {
    return await network(
      request: (request) => request.get("/recommended-courses"),
      cacheKey: "recommended_courses",
      cacheDuration: const Duration(hours: 6),
    );
  }

  /// Get course modules - GET /courses/{course_id}/modules
  Future fetchCourseModules(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/modules"),
      cacheKey: "course_modules_$courseId",
      cacheDuration: const Duration(minutes: 30),
    );
  }

  /// Get course information - GET /courses/{course_id}/information
  Future fetchCourseInformation(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/information"),
      cacheKey: "course_info_$courseId",
      cacheDuration: const Duration(minutes: 30),
    );
  }

  /// Get course DIY content - GET /courses/{course_id}/diy-content
  Future fetchCourseDIYContent(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/diy-content"),
      cacheKey: "course_diy_$courseId",
      cacheDuration: const Duration(minutes: 30),
    );
  }

  /// Get course resources - GET /courses/{course_id}/resources
  Future fetchCourseResources(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/resources"),
      cacheKey: "course_resources_$courseId",
      cacheDuration: const Duration(minutes: 30),
    );
  }

  // ==================== Enrollment Endpoints ====================

  /// Enroll in course - POST /enroll
  Future enrollInCourse({
    required String courseId,
    required String enrollmentCode,
  }) async {
    return await network(
      request: (request) => request.post(
        "/enroll",
        data: {
          "course_id": courseId,
          "enrollment_code": enrollmentCode,
        },
      ),
    );
  }

  /// Get my enrollments - GET /my-enrollments
  Future fetchMyEnrollments() async {
    return await network(
      request: (request) => request.get("/my-enrollments"),
      cacheKey: "my_enrollments",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  /// Get my courses - GET /my-courses
  Future fetchMyCourses({String? status}) async {
    return await network(
      request: (request) {
        var queryParams = <String, dynamic>{};
        if (status != null) queryParams['status'] = status;
        return request.get("/my-courses", queryParameters: queryParams);
      },
      cacheKey: "my_courses_${status ?? 'all'}",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  /// Get ongoing courses - GET /ongoing-courses
  Future fetchOngoingCourses() async {
    return await network(
      request: (request) => request.get("/ongoing-courses"),
      cacheKey: "ongoing_courses",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  /// Get completed courses - GET /completed-courses
  Future fetchCompletedCourses() async {
    return await network(
      request: (request) => request.get("/completed-courses"),
      cacheKey: "completed_courses",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  /// Get enrollment details - GET /enrollments/{enrollment_id}
  Future fetchEnrollmentDetails(String enrollmentId) async {
    return await network(
      request: (request) => request.get("/enrollments/$enrollmentId"),
      cacheKey: "enrollment_$enrollmentId",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  // ==================== Modules Endpoints ====================

  /// Get module details - GET /courses/{course_id}/modules/{module_id}
  Future fetchModuleDetails(String courseId, String moduleId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/modules/$moduleId"),
      cacheKey: "module_${courseId}_$moduleId",
      cacheDuration: const Duration(minutes: 30),
    );
  }

  // ==================== Progress Endpoints ====================

  /// Get course progress - GET /courses/{course_id}/progress
  Future fetchCourseProgress(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/progress"),
      cacheKey: "course_progress_$courseId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Mark topic as complete - POST /topics/{topic_id}/complete
  Future markTopicComplete(String topicId) async {
    return await network(
      request: (request) => request.post("/topics/$topicId/complete"),
    );
  }

  /// Update progress - PUT /progress/{progress_id}
  Future updateProgress(String progressId, Map<String, dynamic> data) async {
    return await network(
      request: (request) => request.put("/progress/$progressId", data: data),
    );
  }

  /// Sync course progress (legacy endpoint)
  Future syncProgress(Map<String, dynamic> progress) async {
    return await network(
      request: (request) => request.post(
        "/progress/sync",
        data: progress,
      ),
    );
  }

  // ==================== Tests/Quizzes Endpoints ====================

  /// Get module test - GET /courses/{course_id}/modules/{module_id}/test
  Future fetchModuleTest(String courseId, String moduleId) async {
    return await network(
      request: (request) =>
          request.get("/courses/$courseId/modules/$moduleId/test"),
      cacheKey: "module_test_${courseId}_$moduleId",
      cacheDuration: const Duration(minutes: 30),
    );
  }

  /// Submit test - POST /courses/{course_id}/modules/{module_id}/tests/{test_id}/submit
  Future submitTest({
    required String courseId,
    required String moduleId,
    required String testId,
    required Map<String, dynamic> answers,
  }) async {
    return await network(
      request: (request) => request.post(
        "/courses/$courseId/modules/$moduleId/tests/$testId/submit",
        data: {"answers": answers},
      ),
    );
  }

  /// Mark quiz as complete - POST /courses/{course_id}/modules/{module_id}/tests/{test_id}/complete-quiz
  Future markQuizComplete({
    required String courseId,
    required String moduleId,
    required String testId,
  }) async {
    return await network(
      request: (request) => request.post(
        "/courses/$courseId/modules/$moduleId/tests/$testId/complete-quiz",
      ),
    );
  }

  // ==================== Notes Endpoints ====================

  /// Get course notes - GET /courses/{course_id}/notes
  Future fetchCourseNotes(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/notes"),
      cacheKey: "course_notes_$courseId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Get module notes - GET /courses/{course_id}/modules/{module_id}/notes
  Future fetchModuleNotes(String courseId, String moduleId) async {
    return await network(
      request: (request) =>
          request.get("/courses/$courseId/modules/$moduleId/notes"),
      cacheKey: "module_notes_${courseId}_$moduleId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Create note - POST /notes
  Future createNote(Map<String, dynamic> data) async {
    return await network(
      request: (request) => request.post("/notes", data: data),
    );
  }

  /// Update note - PUT /notes/{note_id}
  Future updateNote(String noteId, Map<String, dynamic> data) async {
    return await network(
      request: (request) => request.put("/notes/$noteId", data: data),
    );
  }

  /// Delete note - DELETE /notes/{note_id}
  Future deleteNote(String noteId) async {
    return await network(
      request: (request) => request.delete("/notes/$noteId"),
    );
  }

  // ==================== Assignments Endpoints ====================

  /// Get course assignments - GET /courses/{course_id}/assignments
  Future fetchCourseAssignments(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/assignments"),
      cacheKey: "course_assignments_$courseId",
      cacheDuration: const Duration(minutes: 30),
    );
  }

  /// Get assignment details - GET /assignments/{assignment_id}
  Future fetchAssignmentDetails(String assignmentId) async {
    return await network(
      request: (request) => request.get("/assignments/$assignmentId"),
      cacheKey: "assignment_$assignmentId",
      cacheDuration: const Duration(minutes: 30),
    );
  }

  /// Submit assignment - POST /assignments/{assignment_id}/submit
  Future submitAssignment(
      String assignmentId, Map<String, dynamic> data) async {
    return await network(
      request: (request) => request.post(
        "/assignments/$assignmentId/submit",
        data: data,
      ),
    );
  }

  /// Get my submissions - GET /my-submissions
  Future fetchMySubmissions() async {
    return await network(
      request: (request) => request.get("/my-submissions"),
      cacheKey: "my_submissions",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  // ==================== Messages Endpoints ====================

  /// Get course messages - GET /courses/{course_id}/messages
  Future fetchCourseMessages(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/messages"),
      cacheKey: "course_messages_$courseId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Send message - POST /messages
  Future sendMessage(Map<String, dynamic> data) async {
    return await network(
      request: (request) => request.post("/messages", data: data),
    );
  }

  /// Get message details - GET /messages/{message_id}
  Future fetchMessageDetails(String messageId) async {
    return await network(
      request: (request) => request.get("/messages/$messageId"),
      cacheKey: "message_$messageId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Mark message as read - PUT /messages/{message_id}/read
  Future markMessageAsRead(String messageId) async {
    return await network(
      request: (request) => request.put("/messages/$messageId/read"),
    );
  }

  // ==================== Utility Methods ====================

  /// Download course video with progress tracking
  Future downloadVideo(String videoUrl, String savePath,
      {Function(int, int)? onProgress}) async {
    return await network(
      request: (request) => request.download(
        videoUrl,
        savePath,
        onReceiveProgress: onProgress ??
            (count, total) {
              // Default progress callback
              final progress = count / total;
              print(
                  "Download progress: ${(progress * 100).toStringAsFixed(0)}%");
            },
      ),
    );
  }

  /* Helpers
  |-------------------------------------------------------------------------- */

  /* Authentication Headers
  |--------------------------------------------------------------------------
  | Set your auth headers
  | Authenticate your API requests using a bearer token or any other method
  |-------------------------------------------------------------------------- */

  @override
  Future<RequestHeaders> setAuthHeaders(RequestHeaders headers) async {
    String? myAuthToken = await Keys.bearerToken.read();
    if (myAuthToken != null) {
      headers.addBearerToken(myAuthToken);
    }
    return headers;
  }

  /* Should Refresh Token
  |--------------------------------------------------------------------------
  | Check if your Token should be refreshed
  | Set `false` if your API does not require a token refresh
  |-------------------------------------------------------------------------- */

  // @override
  // Future<bool> shouldRefreshToken() async {
  //   return false;
  // }

  /* Refresh Token
  |--------------------------------------------------------------------------
  | If `shouldRefreshToken` returns true then this method
  | will be called to refresh your token. Save your new token to
  | local storage and then use the value in `setAuthHeaders`.
  |-------------------------------------------------------------------------- */

  // @override
  // refreshToken(Dio dio) async {
  //  dynamic response = (await dio.get("https://example.com/refresh-token")).data;
  //  // Save the new token
  //   await Keys.bearerToken.save(response['token']);
  // }
}
