import '../models/job_model.dart';
import '../saved_job_manager.dart';

class SavedJobsService {
  /// Get all saved jobs for current user
  static Future<List<Job>> getSavedJobs() async {
    await SavedJobManager.instance.initialize();
    return SavedJobManager.instance.getSavedItems();
  }

  /// Toggle save status of a job
  static Future<bool> toggleSaveJob(Job job) async {
    return await SavedJobManager.instance.toggle(job);
  }

  /// Save a job
  static Future<void> saveJob(Job job) async {
    final isSaved = SavedJobManager.instance.isSaved(job.id);
    if (!isSaved) {
      await SavedJobManager.instance.toggle(job);
    }
  }

  /// Unsave/remove a job
  static Future<void> unsaveJob(Job job) async {
    final isSaved = SavedJobManager.instance.isSaved(job.id);
    if (isSaved) {
      await SavedJobManager.instance.toggle(job);
    }
  }

  /// Check if a job is saved
  static Future<bool> isJobSaved(String jobId) async {
    await SavedJobManager.instance.initialize();
    return SavedJobManager.instance.isSaved(jobId);
  }

  /// Remove a job from saved list
  static Future<void> removeSavedJob(Job job) async {
    await SavedJobManager.instance.toggle(job);
  }
}
