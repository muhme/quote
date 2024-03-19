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
    Rails.logger.debug { "GenerateAvatarsJob - mkdir #{AVATARS_DIR}" }

    FileUtils.mkdir_p(AVATARS_DIR)

    # create 0.png as default avatar image
    AvatarService.generate_default_avatar(AVATARS_DIR)

    # create avatar image for each existing user
    User.find_each do |user|
      AvatarService.generate_avatar_for(user, AVATARS_DIR)
    end
  end
end
