# config/initializers/trigger_avatars_generation.rb
#
# once triggering app/jobs/generate_avatars_job.rb only if AVATARS_DIR is not existing
#
Rails.application.config.after_initialize do
  # only enqueue the job if the avatars directory does not exist
  GenerateAvatarsJob.perform_later unless Dir.exist?(AVATARS_DIR)
end
