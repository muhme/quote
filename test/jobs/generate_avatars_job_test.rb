require 'test_helper'
require 'minitest/hooks/default'

# test/jobs/generate_avatars_job_test.rb
#
# Integration test, works with real Gravatar service and in file system.
#
class GenerateAvatarsJobTest < ActiveJob::TestCase
  # clean the avatars directory
  def before_all
    FileUtils.rm_rf(AVATARS_DIR) if Dir.exist?(AVATARS_DIR)
  end

  test "should create avatars directory" do
    GenerateAvatarsJob.perform_now
    assert Dir.exist?(AVATARS_DIR)
    # check for default avatar
    assert File.exist?(AVATARS_DIR.join('0.png'))
    # check all users
    User.find_each do |user|
      avatar_path = AVATARS_DIR.join("#{user.id}.png")
      assert File.exist?(avatar_path)
    end
    # check Gravatar image 'test/fixtures/files/test_gravatar.png'
    avatar_path = AVATARS_DIR.join("#{users(:test_gravatar).id}.png")
    assert File.exist?(avatar_path)
    # Gravatar return and following resize differs from upload, use values from once created 'public/images/ta/6.png'
    assert_equal 3279, File.size(avatar_path)
    assert_equal "ba6dd066a7173066b101c5edeabef53c", Digest::MD5.file(avatar_path).hexdigest

    # have it running second time with already existing avatar dir
    GenerateAvatarsJob.perform_now
  end
end
