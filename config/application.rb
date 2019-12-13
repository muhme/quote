require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Quote
  class Application < Rails::Application
    # default configuration for Rails 6
    config.load_defaults "6.0"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.action_mailer.default_url_options = { host: 'zitat-service.de' }

    # # nine following new defaults from Rails 6 upgrade, file config/initializers/new_framework_defaults_6_0.rb 
    # # see https://medium.com/@dylansreile/rails-6-0-new-framework-defaults-what-they-do-and-how-to-safely-uncomment-them-586146f371e8
    # Don't force requests from old versions of IE to be UTF-8 encoded.
    Rails.application.config.action_view.default_enforce_utf8 = false
    # Embed purpose and expiry metadata inside signed and encrypted cookies for increased security.
    Rails.application.config.action_dispatch.use_cookies_with_metadata = true
    # Change the return value of `ActionDispatch::Response#content_type` to Content-Type header without modification.
    Rails.application.config.action_dispatch.return_only_media_type_on_content_type = false
    # Return false instead of self when enqueuing is aborted from a callback.
    Rails.application.config.active_job.return_false_on_aborted_enqueue = true
    # Send Active Storage analysis and purge jobs to dedicated queues.
    Rails.application.config.active_storage.queues.analysis = :active_storage_analysis
    Rails.application.config.active_storage.queues.purge    = :active_storage_purge
    # When assigning to a collection of attachments declared via `has_many_attached`, replace existing
    # attachments instead of appending. Use #attach to add new attachments without replacing existing ones.
    Rails.application.config.active_storage.replace_on_assign_to_many = true
    # Use ActionMailer::MailDeliveryJob for sending parameterized and normal mail.
    #
    # The default delivery jobs (ActionMailer::Parameterized::DeliveryJob, ActionMailer::DeliveryJob),
    # will be removed in Rails 6.1. This setting is not backwards compatible with earlier Rails versions.
    # If you send mail in the background, job workers need to have a copy of
    # MailDeliveryJob to ensure all delivery jobs are processed properly.
    # Make sure your entire app is migrated and stable on 6.0 before using this setting.
    Rails.application.config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"
    # Enable the same cache key to be reused when the object being cached of type
    # `ActiveRecord::Relation` changes by moving the volatile information (max updated at and count)
    # of the relation's cache key into the cache version to support recycling cache key.
    Rails.application.config.active_record.collection_cache_versioning = true
    # Change the return value of `ActionDispatch::Response#content_type` to Content-Type header without modification.
    Rails.application.config.action_dispatch.return_only_media_type_on_content_type = false
    # optimize $LOAD_PATH lookups (less directories to check), and save Bootsnap work and memory consumption, since it does not need to build an index for these directories.
    config.add_autoload_paths_to_load_path = false
  end
end
