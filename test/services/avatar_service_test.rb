# test/services/avatar_service_test.rb
# Integration test, works with real Gravatar service and in file system.
#
require "test_helper"
require 'base64'
require 'digest'
require 'minitest/hooks/default'

class AvatarServiceTest < ActiveSupport::TestCase
  # clean and recreate the avatars directory
  def before_all
    FileUtils.rm_rf(AVATARS_DIR) if Dir.exist?(AVATARS_DIR)
    GenerateAvatarsJob.perform_now
  end
  test "generate Base64 avatar from login name" do
    img = AvatarService::generate_base64_avatar_from_login('test')
    # avatar image created with letters 'te' and color from hash 'test'
    assert_equal 3478, img.size
    assert_equal "890baec520b34422e8707c41e7fb2635", Digest::MD5.hexdigest(img)
  end

  test "generate Base64 avatar from email with existing Gravatar" do
    img = AvatarService::generate_base64_avatar_from_email(users(:test_gravatar).email)
    assert_equal 4394, img.size
    assert_equal "aa4034f06719904e40b0c745e8686139", Digest::MD5.hexdigest(img)
  end

  test "generate Base64 avatar returns nil for non-existing Gravatar" do
    assert_nil AvatarService::generate_base64_avatar_from_email('user.bla@non-existing.xyz')
  end

  test "store Bas64 encoded avatar image as file" do
    orignal_avatar_filepath = AVATARS_DIR.join("#{users(:first_user).id}.png")
    original_avatar_data = File.read(orignal_avatar_filepath, mode: 'rb')

    new_id = 4711
    new_avatar_filepath = AVATARS_DIR.join("#{new_id}.png")
    FileUtils.rm_f(new_avatar_filepath)
    refute File.exist?(new_avatar_filepath), "Oops avatar image file already exists"
    new_img = "data:image/png;base64," + Base64.strict_encode64(original_avatar_data)

    AvatarService::store_avatar(new_id, new_img)

    assert File.exist?(new_avatar_filepath)
    assert_equal File.size(orignal_avatar_filepath), File.size(new_avatar_filepath)
    assert_equal Digest::MD5.file(orignal_avatar_filepath), Digest::MD5.file(new_avatar_filepath)
    FileUtils.rm(new_avatar_filepath)
    refute File.exist?(new_avatar_filepath), "OOPS avatar files hould have been removed"
  end

  test "ignore storing avatar image links as file" do
    new_id = 4711
    new_avatar_filepath = AVATARS_DIR.join("#{new_id}.png")
    FileUtils.rm_f(new_avatar_filepath)
    refute File.exist?(new_avatar_filepath), "Oops avatar image file already exists"

    AvatarService::store_avatar(new_id, AVATARS_DIR.join("0.png"))
    refute File.exist?(new_avatar_filepath), "avatar file #{new_avatar_filepath} exists"
  end

  test "generate base64 random color avatar" do
    img1 = AvatarService::generate_base64_random_color_avatar("test")
    img2 = AvatarService::generate_base64_random_color_avatar("test")
    assert img1.size > 2000
    assert img2.size > 2000
    refute_equal img1, img2, "generate_base64_random_color_avatar() created two times the same color"
  end

  test "session avatar image file" do
    # 1. create with using 1.png as image source
    session_id = "22535162c6b007d971290802e13e3244"
    orignal_avatar_filepath = AVATARS_DIR.join("#{users(:first_user).id}.png")
    original_avatar_data = File.read(orignal_avatar_filepath, mode: 'rb')

    session_avatar_filepath = AVATARS_DIR.join("#{session_id}.png")
    FileUtils.rm_f(session_avatar_filepath)
    refute File.exist?(session_avatar_filepath), "Oops avatar image file already exists"
    new_img = "data:image/png;base64," + Base64.strict_encode64(original_avatar_data)

    AvatarService::store_avatar(session_id, new_img)

    assert File.exist?(session_avatar_filepath)
    assert_equal File.size(orignal_avatar_filepath), File.size(session_avatar_filepath)
    assert_equal Digest::MD5.file(orignal_avatar_filepath), Digest::MD5.file(session_avatar_filepath)

    # 2. check exists
    session_img = AvatarService::session_avatar_image(session_id)
    assert new_img, session_img

    # 3. delete
    assert File.exist?(session_avatar_filepath)
    AvatarService::delete_session_avatar_image_file(session_id)
    refute File.exist?(session_avatar_filepath)

    # 4. check for non-existing session avatar image file
    assert_nil AvatarService::session_avatar_image(session_id)
  end

  test "create Gravatar URL" do
    url = AvatarService::gravataer_url("james.tester@home.com")
    assert_equal "https://gravatar.com/avatar/0ba99e8756c51634a4922cf90e82f4a5?s=80&d=404", url.to_s
  end
end
