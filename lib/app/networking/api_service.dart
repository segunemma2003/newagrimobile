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
          baseOptions: (BaseOptions baseOptions) {
            return baseOptions
              ..headers['Accept'] = 'application/json'
              ..headers['Content-Type'] = 'application/json';
          },
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
    required String passwordConfirmation,
    String? phone,
  }) async {
    final data = {
      "name": name,
      "email": email,
      "password": password,
      "password_confirmation": passwordConfirmation,
    };

    if (phone != null && phone.isNotEmpty) {
      data["phone"] = phone;
    }

    return await network(
      request: (request) => request.post(
        "/register",
        data: data,
      ),
    );
  }

  /// Get current user with stats - GET /user
  /// Returns user profile with course statistics
  Future getCurrentUser() async {
    return await network(
      request: (request) => request.get("/user"),
      cacheKey: "current_user",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Update profile - PUT /user/profile
  Future updateProfile(Map<String, dynamic> data) async {
    return await network(
      request: (request) => request.put("/user/profile", data: data),
    );
  }

  /// Change password - PUT /user/password
  Future changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await network(
      request: (request) => request.put(
        "/user/password",
        data: {
          "current_password": currentPassword,
          "password": password,
          "password_confirmation": passwordConfirmation,
        },
      ),
    );
  }

  /// Delete account - DELETE /user/account
  Future deleteAccount({required String password}) async {
    return await network(
      request: (request) => request.delete(
        "/user/account",
        data: {"password": password},
      ),
    );
  }

  /// Get user certificates - GET /user/certificates
  Future fetchUserCertificates() async {
    return await network(
      request: (request) => request.get("/user/certificates"),
      cacheKey: "user_certificates",
      cacheDuration: const Duration(minutes: 10),
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
  /// Search parameter: search (searches name and description)
  Future fetchCategories({String? search}) async {
    return await network(
      request: (request) {
        var queryParams = <String, dynamic>{};
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
        }
        return request.get("/categories", queryParameters: queryParams);
      },
      cacheKey: "categories_${search ?? 'all'}",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  /// Get category details - GET /categories/{category_id}
  Future fetchCategory(String categoryId) async {
    return await network(
      request: (request) => request.get("/categories/$categoryId"),
      cacheKey: "category_$categoryId",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  /// Get courses by category - GET /categories/{category_id}/courses
  /// Supports search, level, min_rating, min_duration, max_duration, per_page filters
  Future fetchCategoryCourses(
    String categoryId, {
    String? search,
    String? level,
    double? minRating,
    int? minDuration,
    int? maxDuration,
    int? perPage,
  }) async {
    return await network(
      request: (request) {
        var queryParams = <String, dynamic>{};
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
        }
        if (level != null) queryParams['level'] = level;
        if (minRating != null) queryParams['min_rating'] = minRating;
        if (minDuration != null) queryParams['min_duration'] = minDuration;
        if (maxDuration != null) queryParams['max_duration'] = maxDuration;
        if (perPage != null) queryParams['per_page'] = perPage;
        return request.get(
          "/categories/$categoryId/courses",
          queryParameters: queryParams,
        );
      },
      cacheKey: "category_courses_$categoryId",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  /// Get categories with courses - GET /categories-with-courses
  Future fetchCategoriesWithCourses() async {
    return await network(
      request: (request) => request.get("/categories-with-courses"),
      cacheKey: "categories_with_courses",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  /// Get featured courses (public) - GET /featured-courses-public
  Future fetchFeaturedCoursesPublic() async {
    return await network(
      request: (request) => request.get("/featured-courses-public"),
      cacheKey: "featured_courses_public",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  // ==================== Courses Endpoints ====================

  /// Search and filter courses - GET /courses
  /// Supports: search, category_id, level, min_rating, min_duration, max_duration, per_page
  Future fetchCourses({
    String? search,
    int? categoryId,
    String? level,
    double? minRating,
    int? minDuration,
    int? maxDuration,
    int? perPage,
  }) async {
    return await network(
      request: (request) {
        var queryParams = <String, dynamic>{};
        if (search != null && search.isNotEmpty) {
          queryParams['search'] = search;
        }
        if (categoryId != null) queryParams['category_id'] = categoryId;
        if (level != null) queryParams['level'] = level;
        if (minRating != null) queryParams['min_rating'] = minRating;
        if (minDuration != null) queryParams['min_duration'] = minDuration;
        if (maxDuration != null) queryParams['max_duration'] = maxDuration;
        if (perPage != null) queryParams['per_page'] = perPage;
        return request.get("/courses", queryParameters: queryParams);
      },
      cacheKey: "courses_${categoryId ?? 'all'}_${search ?? ''}",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Daily recommended courses - GET /daily-recommended-courses
  /// Authentication: Required
  Future fetchDailyRecommendedCourses() async {
    return await network(
      request: (request) => request.get("/daily-recommended-courses"),
      cacheKey: "daily_recommended_courses",
      cacheDuration: const Duration(hours: 24),
    );
  }

  /// Latest courses - GET /latest-courses
  /// Authentication: Required
  Future fetchLatestCourses() async {
    return await network(
      request: (request) => request.get("/latest-courses"),
      cacheKey: "latest_courses",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  /// Featured courses - GET /featured-courses
  /// Authentication: Required
  Future fetchFeaturedCourses() async {
    return await network(
      request: (request) => request.get("/featured-courses"),
      cacheKey: "featured_courses",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  /// Get course details - GET /courses/{course_id}
  Future fetchCourse(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId"),
      cacheKey: "course_$courseId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Get course curriculum - GET /courses/{course_id}/curriculum
  /// Authentication: Required (must be enrolled)
  Future fetchCourseCurriculum(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/curriculum"),
      cacheKey: "course_curriculum_$courseId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Get course completion percentage - GET /courses/{course_id}/completion
  /// Authentication: Required (must be enrolled)
  Future fetchCourseCompletion(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/completion"),
      cacheKey: "course_completion_$courseId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Get course reviews - GET /courses/{course_id}/reviews
  /// Query parameters: per_page (default: 10), page
  Future fetchCourseReviews(String courseId, {int? perPage, int? page}) async {
    return await network(
      request: (request) {
        var queryParams = <String, dynamic>{};
        if (perPage != null) queryParams['per_page'] = perPage;
        if (page != null) queryParams['page'] = page;
        return request.get(
          "/courses/$courseId/reviews",
          queryParameters: queryParams,
        );
      },
      cacheKey: "course_reviews_$courseId",
      cacheDuration: const Duration(minutes: 10),
    );
  }

  /// Add course review - POST /courses/{course_id}/reviews
  /// Authentication: Required
  /// Request body: {"rating": 5, "review": "Great course!"}
  Future addCourseReview(
    String courseId, {
    required int rating,
    String? review,
  }) async {
    return await network(
      request: (request) => request.post(
        "/courses/$courseId/reviews",
        data: {
          "rating": rating,
          if (review != null && review.isNotEmpty) "review": review,
        },
      ),
    );
  }

  /// Get recommended courses - GET /recommended-courses
  /// Authentication: Required
  Future fetchRecommendedCourses() async {
    return await network(
      request: (request) => request.get("/recommended-courses"),
      cacheKey: "recommended_courses",
      cacheDuration: const Duration(minutes: 10),
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
  /// Authentication: Required
  Future fetchMyEnrollments() async {
    return await network(
      request: (request) => request.get("/my-enrollments"),
      cacheKey: "my_enrollments",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Get enrollment details - GET /enrollments/{enrollment_id}
  /// Authentication: Required
  Future fetchEnrollmentDetails(String enrollmentId) async {
    return await network(
      request: (request) => request.get("/enrollments/$enrollmentId"),
      cacheKey: "enrollment_$enrollmentId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Get my courses - GET /my-courses
  /// Authentication: Required
  Future fetchMyCourses() async {
    return await network(
      request: (request) => request.get("/my-courses"),
      cacheKey: "my_courses",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// My ongoing courses - GET /my-ongoing-courses
  /// Authentication: Required
  Future fetchMyOngoingCourses() async {
    return await network(
      request: (request) => request.get("/my-ongoing-courses"),
      cacheKey: "my_ongoing_courses",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Get completed courses - GET /completed-courses
  /// Authentication: Required
  Future fetchCompletedCourses() async {
    return await network(
      request: (request) => request.get("/completed-courses"),
      cacheKey: "completed_courses",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Saved courses list - GET /saved-courses-list
  /// Authentication: Required
  Future fetchSavedCoursesList() async {
    return await network(
      request: (request) => request.get("/saved-courses-list"),
      cacheKey: "saved_courses_list",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Certified courses - GET /certified-courses
  /// Authentication: Required
  Future fetchCertifiedCourses() async {
    return await network(
      request: (request) => request.get("/certified-courses"),
      cacheKey: "certified_courses",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Get saved courses - GET /saved-courses
  /// Authentication: Required
  Future fetchSavedCourses() async {
    return await network(
      request: (request) => request.get("/saved-courses"),
      cacheKey: "saved_courses",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Save course - POST /courses/{course_id}/save
  /// Authentication: Required
  Future saveCourse(String courseId) async {
    return await network(
      request: (request) => request.post("/courses/$courseId/save"),
    );
  }

  /// Unsave course - DELETE /courses/{course_id}/unsave
  /// Authentication: Required
  Future unsaveCourse(String courseId) async {
    return await network(
      request: (request) => request.delete("/courses/$courseId/unsave"),
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

  /// Mark topic/lesson as complete - POST /topics/{topic_id}/complete
  /// Authentication: Required
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

  /// Complete quiz - POST /courses/{course_id}/modules/{module_id}/tests/{test_id}/complete-quiz
  /// Authentication: Required
  Future completeQuiz({
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

  // ==================== Tests/Quizzes Endpoints ====================

  /// Get module test - GET /courses/{course_id}/modules/{module_id}/test
  /// Authentication: Required (must be enrolled)
  Future fetchModuleTest(String courseId, String moduleId) async {
    return await network(
      request: (request) =>
          request.get("/courses/$courseId/modules/$moduleId/test"),
      cacheKey: "module_test_${courseId}_$moduleId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Get lesson/topic test - GET /courses/{course_id}/modules/{module_id}/topics/{topic_id}/test
  /// Authentication: Required (must be enrolled)
  Future fetchLessonTest(
    String courseId,
    String moduleId,
    String topicId,
  ) async {
    return await network(
      request: (request) => request.get(
        "/courses/$courseId/modules/$moduleId/topics/$topicId/test",
      ),
      cacheKey: "lesson_test_${courseId}_${moduleId}_$topicId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Submit test - POST /courses/{course_id}/modules/{module_id}/tests/{test_id}/submit
  /// Authentication: Required
  /// Request body: {"answers": {"1": "B", "2": "A", "3": "true"}}
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

  /// Submit topic test - POST /courses/{course_id}/modules/{module_id}/topics/{topic_id}/tests/{test_id}/submit
  /// Authentication: Required
  /// Request body: {"answers": {"1": "option_a", "2": "option_b"}}
  Future submitTopicTest({
    required String courseId,
    required String moduleId,
    required String topicId,
    required String testId,
    required Map<String, dynamic> answers,
  }) async {
    return await network(
      request: (request) => request.post(
        "/courses/$courseId/modules/$moduleId/topics/$topicId/tests/$testId/submit",
        data: {"answers": answers},
      ),
    );
  }

  // ==================== Notes Endpoints ====================

  /// Get course notes - GET /courses/{course_id}/notes
  /// Authentication: Required (must be enrolled)
  Future fetchCourseNotes(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/notes"),
      cacheKey: "course_notes_$courseId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Get module notes - GET /courses/{course_id}/modules/{module_id}/notes
  /// Authentication: Required (must be enrolled)
  Future fetchModuleNotes(String courseId, String moduleId) async {
    return await network(
      request: (request) =>
          request.get("/courses/$courseId/modules/$moduleId/notes"),
      cacheKey: "module_notes_${courseId}_$moduleId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Get lesson/topic notes - GET /courses/{course_id}/modules/{module_id}/topics/{topic_id}/notes
  /// Authentication: Required (must be enrolled)
  Future fetchLessonNotes(
    String courseId,
    String moduleId,
    String topicId,
  ) async {
    return await network(
      request: (request) => request.get(
        "/courses/$courseId/modules/$moduleId/topics/$topicId/notes",
      ),
      cacheKey: "lesson_notes_${courseId}_${moduleId}_$topicId",
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

  // ==================== Comments Endpoints ====================

  /// Get lesson/topic comments - GET /courses/{course_id}/topics/{topic_id}/comments
  /// Authentication: Required
  Future fetchLessonComments(String courseId, String topicId) async {
    return await network(
      request: (request) =>
          request.get("/courses/$courseId/topics/$topicId/comments"),
      cacheKey: "lesson_comments_${courseId}_$topicId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Add lesson/topic comment - POST /courses/{course_id}/topics/{topic_id}/comments
  /// Authentication: Required
  /// Request body: {"comment": "Great lesson!", "parent_id": null}
  Future addLessonComment(
    String courseId,
    String topicId, {
    required String comment,
    int? parentId,
  }) async {
    return await network(
      request: (request) => request.post(
        "/courses/$courseId/topics/$topicId/comments",
        data: {
          "comment": comment,
          if (parentId != null) "parent_id": parentId,
        },
      ),
    );
  }

  /// Get course comments - GET /courses/{course_id}/comments
  /// Authentication: Required
  Future fetchCourseComments(String courseId) async {
    return await network(
      request: (request) => request.get("/courses/$courseId/comments"),
      cacheKey: "course_comments_$courseId",
      cacheDuration: const Duration(minutes: 5),
    );
  }

  /// Add course comment - POST /courses/{course_id}/comments
  /// Authentication: Required
  /// Request body: {"comment": "Great course!", "parent_id": null}
  Future addCourseComment(
    String courseId, {
    required String comment,
    int? parentId,
  }) async {
    return await network(
      request: (request) => request.post(
        "/courses/$courseId/comments",
        data: {
          "comment": comment,
          if (parentId != null) "parent_id": parentId,
        },
      ),
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
