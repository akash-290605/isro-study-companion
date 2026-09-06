/// Global constants for the ISRO Study Companion application.
class AppConstants {
  static const String appName = 'ISRO Study Companion';
  static const String tagline = 'Study → Practice → Analyze → Revise → Improve';

  // Starter notice
  static const String syllabusDisclaimer =
      'Starter ECE Syllabus provided for reference. Not an official ISRO syllabus.';

  // Default Test Settings
  static const int defaultEasyTimeSeconds = 60;
  static const int defaultMediumTimeSeconds = 90;
  static const int defaultHardTimeSeconds = 120;

  static const double defaultCorrectMarks = 1.0;
  static const double defaultNegativeMarks = -0.25;
  static const double defaultUnattemptedMarks = 0.0;
  static const bool defaultNegativeMarkingEnabled = true;

  // Mixed Difficulty distribution defaults
  static const int defaultMixedEasyPercent = 30;
  static const int defaultMixedMediumPercent = 50;
  static const int defaultMixedHardPercent = 20;

  // Daily Goals defaults
  static const int defaultDailyStudyGoalMinutes = 240; // 4 hours
  static const int defaultDailyQuestionsGoal = 30;
  static const int defaultDailyTestsGoal = 1;

  // Pomodoro Defaults
  static const int defaultPomodoroStudyMinutes = 25;
  static const int defaultPomodoroShortBreakMinutes = 5;
  static const int defaultPomodoroLongBreakMinutes = 15;
  static const int defaultPomodoroCycles = 4;

  // Performance thresholds
  static const double strongThresholdPercent = 75.0;
  static const double averageThresholdPercent = 55.0;

  // Source grounding fallback
  static const String insufficientSourceMessage =
      'Not enough information in the selected study materials.';
}

