# app/jobs/generate_avatars_job.rb
#
# generate avatars once
# - triggered by config/initializers/trigger_avatars_generation.rb only running once if AVATARS_DIR is not existing
# - if gravater found for mail address, this one is used
# - else create avatar with background color from login name hash and first two letters from login name
# - requires approx. 100 seconds for currently 200 users
#
class GenerateAvatarsJob < ApplicationJob
  require 'net/http'
  require 'digest/md5'
  queue_as :default

  def perform
    # wait for database to be ready as typically all docker containers are starting and
    # MariaDB needs some seconds to be up and running
    wait_for_database_ready

    Rails.logger.debug { "GenerateAvatarsJob - mkdir #{AVATARS_DIR}" }
    FileUtils.mkdir_p(AVATARS_DIR)

    # create 0.png as default avatar image
    AvatarService.generate_default_avatar(AVATARS_DIR)

    # create avatar image for each existing user
    User.find_each do |user|
      AvatarService.generate_avatar_for(user, AVATARS_DIR)
    end
  end

  def wait_for_database_ready(max_attempts: 5, initial_wait_time: 2)
    attempts = 0
    begin
      attempts += 1
      ActiveRecord::Base.connection_pool.with_connection { |con| con.active? }
    rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
      Rails.logger.warn { "Database not ready, attempt #{attempts}/#{max_attempts}: #{e.message}" }
      if attempts >= max_attempts
        Rails.logger.error { "Database not ready after #{max_attempts} attempts, giving up." }
        raise
      else
        sleep_time = initial_wait_time * (2**(attempts - 1)) # exponential backoff
        Rails.logger.info { "Waiting #{sleep_time} seconds before retry ..." }
        sleep(sleep_time)
        retry
      end
    end
    Rails.logger.info { "Database is ready." }
  end
end
