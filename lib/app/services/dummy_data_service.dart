import '/app/models/course.dart';
import '/app/models/category.dart';
import '/app/models/user.dart';

/// Dummy data service for offline testing
/// Provides mock data when API is unavailable
class DummyDataService {
  // Dummy user credentials for testing
  static const String dummyEmail = "student@agrisiti.com";
  static const String dummyPassword = "password123";
  static const String dummyToken = "1|dummy_token_for_testing";

  /// Get dummy user
  static User getDummyUser() {
    return User.fromJson({
      "id": 1,
      "name": "John Doe",
      "email": dummyEmail,
      "phone": "+1234567890",
      "role": "student",
      "avatar": "https://example.com/avatar.jpg",
      "bio": "Student bio",
      "is_active": true,
    });
  }

  /// Get dummy categories
  static List<Category> getDummyCategories() {
    return [
      Category.fromJson({
        "id": 1,
        "name": "Agriculture",
        "slug": "agriculture",
        "description": "Agricultural courses",
        "image": "https://example.com/image.jpg",
        "is_active": true,
        "sort_order": 1,
      }),
      Category.fromJson({
        "id": 2,
        "name": "Hydroponics",
        "slug": "hydroponics",
        "description": "Hydroponic farming courses",
        "image": "https://example.com/image2.jpg",
        "is_active": true,
        "sort_order": 2,
      }),
      Category.fromJson({
        "id": 3,
        "name": "Urban Farming",
        "slug": "urban-farming",
        "description": "Urban farming techniques",
        "image": "https://example.com/image3.jpg",
        "is_active": true,
        "sort_order": 3,
      }),
    ];
  }

  /// Get dummy courses
  static List<Course> getDummyCourses() {
    return [
      Course.fromJson({
        "id": 1,
        "title": "Introduction to Modern Farming",
        "slug": "introduction-to-modern-farming",
        "short_description": "Learn the basics of modern farming techniques",
        "description": "A comprehensive course covering modern farming techniques, sustainable practices, and innovative agricultural methods. Perfect for beginners who want to start their farming journey.",
        "image": "https://example.com/course1.jpg",
        "level": "beginner",
        "duration_minutes": 120,
        "rating": 4.5,
        "rating_count": 100,
        "enrollment_count": 500,
        "category": {
          "id": 1,
          "name": "Agriculture",
        },
        "tutor": {
          "id": 2,
          "name": "Dr. Jane Smith",
          "avatar": "https://example.com/tutor1.jpg",
        },
        "lessons": getDummyLessons(1),
      }),
      Course.fromJson({
        "id": 2,
        "title": "Advanced Hydroponics Systems",
        "slug": "advanced-hydroponics-systems",
        "short_description": "Master advanced hydroponic farming systems",
        "description": "Deep dive into advanced hydroponic systems, nutrient management, and system optimization. Designed for intermediate to advanced learners.",
        "image": "https://example.com/course2.jpg",
        "level": "intermediate",
        "duration_minutes": 180,
        "rating": 4.8,
        "rating_count": 75,
        "enrollment_count": 300,
        "category": {
          "id": 2,
          "name": "Hydroponics",
        },
        "tutor": {
          "id": 3,
          "name": "Prof. Michael Brown",
          "avatar": "https://example.com/tutor2.jpg",
        },
        "lessons": getDummyLessons(2),
      }),
      Course.fromJson({
        "id": 3,
        "title": "Urban Farming Essentials",
        "slug": "urban-farming-essentials",
        "short_description": "Essential skills for urban farming success",
        "description": "Learn how to grow fresh produce in urban environments. Covering container gardening, vertical farming, and space optimization techniques.",
        "image": "https://example.com/course3.jpg",
        "level": "beginner",
        "duration_minutes": 90,
        "rating": 4.6,
        "rating_count": 120,
        "enrollment_count": 450,
        "category": {
          "id": 3,
          "name": "Urban Farming",
        },
        "tutor": {
          "id": 4,
          "name": "Sarah Johnson",
          "avatar": "https://example.com/tutor3.jpg",
        },
        "lessons": getDummyLessons(3),
      }),
    ];
  }

  /// Get dummy lessons for a course
  static List<dynamic> getDummyLessons(int courseId) {
    return [
      {
        "id": courseId * 10 + 1,
        "course_id": courseId,
        "title": "Introduction to the Course",
        "description": "Welcome to the course! Learn what you'll be covering.",
        "content": "This is the introduction lesson. Here you'll learn about the course structure and what to expect.",
        "type": "writeup",
        "order": 1,
        "duration": 600,
      },
      {
        "id": courseId * 10 + 2,
        "course_id": courseId,
        "title": "Getting Started with Basics",
        "description": "Learn the fundamental concepts",
        "content": "In this lesson, we'll cover the basic concepts and terminology you need to know.",
        "type": "writeup",
        "order": 2,
        "duration": 900,
      },
      {
        "id": courseId * 10 + 3,
        "course_id": courseId,
        "title": "Video Tutorial: Practical Demonstration",
        "description": "Watch a practical demonstration",
        "video_url": "https://example.com/video1.mp4",
        "type": "video",
        "order": 3,
        "duration": 1200,
        "transcript": "Welcome to this practical demonstration. In this video, we'll be showing you step-by-step how to set up your first farming project. First, you'll need to prepare your growing area. Make sure you have adequate space and lighting. Next, we'll cover the essential tools and materials you'll need. Then, we'll walk through the actual setup process, showing you each step in detail. Finally, we'll discuss maintenance and care tips to ensure your project succeeds. Remember, patience and consistency are key to successful farming.",
      },
      {
        "id": courseId * 10 + 4,
        "course_id": courseId,
        "title": "DIY Activity: Hands-on Practice",
        "description": "Practice what you've learned",
        "content": "Complete this hands-on activity to reinforce your learning. Follow the step-by-step instructions provided.",
        "type": "diy",
        "order": 4,
        "duration": 1800,
      },
      {
        "id": courseId * 10 + 5,
        "course_id": courseId,
        "title": "Knowledge Check Quiz",
        "description": "Test your understanding",
        "type": "quiz",
        "order": 5,
        "duration": 600,
        "quizzes": [
          {
            "id": courseId * 10 + 50,
            "question": "What is the main topic of this course?",
            "options": [
              {"id": "opt1", "text": "Option A", "is_correct": false},
              {"id": "opt2", "text": "Option B (Correct)", "is_correct": true},
              {"id": "opt3", "text": "Option C", "is_correct": false},
              {"id": "opt4", "text": "Option D", "is_correct": false},
            ],
            "explanation": "Option B is correct because...",
          },
          {
            "id": courseId * 10 + 51,
            "question": "Which statement is true?",
            "options": [
              {"id": "opt1", "text": "True Statement", "is_correct": true},
              {"id": "opt2", "text": "False Statement", "is_correct": false},
            ],
            "explanation": "The first statement is correct.",
          },
        ],
      },
    ];
  }

  /// Get dummy course details
  static Map<String, dynamic> getDummyCourseDetails(int courseId) {
    final courses = getDummyCourses();
    final course = courses.firstWhere(
      (c) => c.id == courseId.toString(),
      orElse: () => courses.first,
    );

    return {
      "id": course.id,
      "title": course.title,
      "slug": "introduction-to-modern-farming",
      "description": course.description,
      "short_description": course.description?.substring(0, 100),
      "image": course.thumbnail,
      "level": "beginner",
      "duration_minutes": 120,
      "rating": 4.5,
      "rating_count": 100,
      "enrollment_count": 500,
      "category": course.category?.toJson(),
      "tutor": {
        "id": 2,
        "name": "Dr. Jane Smith",
        "avatar": "https://example.com/tutor1.jpg",
      },
      "modules": [
        {
          "id": 1,
          "course_id": courseId,
          "title": "Module 1: Fundamentals",
          "description": "Learn the fundamentals of modern farming",
          "order": 1,
          "is_completed": false,
          "is_locked": false,
          "topics": [
            {
              "id": courseId * 10 + 1,
              "course_id": courseId,
              "module_id": 1,
              "title": "Introduction to the Course",
              "description": "Welcome to the course! Learn what you'll be covering.",
              "content": "This is the introduction lesson. Here you'll learn about the course structure and what to expect.",
              "type": "writeup",
              "order": 1,
              "duration": 600,
              "is_completed": false,
              "is_locked": false,
            },
            {
              "id": courseId * 10 + 2,
              "course_id": courseId,
              "module_id": 1,
              "title": "Getting Started with Basics",
              "description": "Learn the fundamental concepts",
              "content": "In this lesson, we'll cover the basic concepts and terminology you need to know.",
              "type": "writeup",
              "order": 2,
              "duration": 900,
              "is_completed": false,
              "is_locked": false,
            },
            {
              "id": courseId * 10 + 3,
              "course_id": courseId,
              "module_id": 1,
              "title": "Video Tutorial: Practical Demonstration",
              "description": "Watch a practical demonstration",
              "video_url": "https://example.com/video1.mp4",
              "type": "video",
              "order": 3,
              "duration": 1200,
              "transcript": "Welcome to this practical demonstration. In this video, we'll be showing you step-by-step how to set up your first farming project.",
              "is_completed": false,
              "is_locked": false,
            },
            {
              "id": courseId * 10 + 4,
              "course_id": courseId,
              "module_id": 1,
              "title": "DIY Activity: Hands-on Practice",
              "description": "Practice what you've learned",
              "content": "Complete this hands-on activity to reinforce your learning.",
              "type": "diy",
              "order": 4,
              "duration": 1800,
              "is_completed": false,
              "is_locked": false,
            },
            {
              "id": courseId * 10 + 5,
              "course_id": courseId,
              "module_id": 1,
              "title": "Module 1 Test",
              "description": "Test your understanding of Module 1",
              "type": "quiz",
              "order": 5,
              "duration": 600,
              "is_completed": false,
              "is_locked": false,
              "quizzes": [
                {
                  "id": courseId * 10 + 50,
                  "question": "What is the main topic of this module?",
                  "options": [
                    {"id": "opt1", "text": "Option A", "is_correct": false},
                    {"id": "opt2", "text": "Option B (Correct)", "is_correct": true},
                    {"id": "opt3", "text": "Option C", "is_correct": false},
                    {"id": "opt4", "text": "Option D", "is_correct": false},
                  ],
                  "explanation": "Option B is correct because...",
                },
              ],
            },
          ],
          "completed_lessons": 0,
          "total_lessons": 5,
        },
        {
          "id": 2,
          "course_id": courseId,
          "title": "Module 2: Advanced Techniques",
          "description": "Learn advanced farming techniques",
          "order": 2,
          "is_completed": false,
          "is_locked": true, // Locked until Module 1 is completed
          "topics": [
            {
              "id": courseId * 10 + 6,
              "course_id": courseId,
              "module_id": 2,
              "title": "Advanced Concepts",
              "description": "Learn advanced concepts",
              "content": "This lesson covers advanced concepts.",
              "type": "writeup",
              "order": 1,
              "duration": 900,
              "is_completed": false,
              "is_locked": true,
            },
            {
              "id": courseId * 10 + 7,
              "course_id": courseId,
              "module_id": 2,
              "title": "Advanced Video Tutorial",
              "description": "Watch advanced techniques",
              "video_url": "https://example.com/video2.mp4",
              "type": "video",
              "order": 2,
              "duration": 1500,
              "is_completed": false,
              "is_locked": true,
            },
            {
              "id": courseId * 10 + 8,
              "course_id": courseId,
              "module_id": 2,
              "title": "Module 2 Test",
              "description": "Test your understanding of Module 2",
              "type": "quiz",
              "order": 3,
              "duration": 600,
              "is_completed": false,
              "is_locked": true,
              "quizzes": [
                {
                  "id": courseId * 10 + 51,
                  "question": "What is an advanced technique?",
                  "options": [
                    {"id": "opt1", "text": "Correct Answer", "is_correct": true},
                    {"id": "opt2", "text": "Wrong Answer", "is_correct": false},
                  ],
                },
              ],
            },
          ],
          "completed_lessons": 0,
          "total_lessons": 3,
        },
      ],
    };
  }

  /// Simulate login response
  static Map<String, dynamic> getDummyLoginResponse() {
    return {
      "success": true,
      "message": "Login successful",
      "data": {
        "user": getDummyUser().toJson(),
        "token": dummyToken,
        "token_type": "Bearer",
      },
    };
  }

  /// Check if credentials match dummy account
  static bool isValidDummyCredentials(String email, String password) {
    return email == dummyEmail && password == dummyPassword;
  }
}

