require 'rmagick'

# create user avatar as base64 encoded image from Gravatr, from login names first two letters or upload
# - service is implemented with class (static) methods
# - used by generate avatar job and users controller
#
class AvatarService
  #
  # generate user avatar image and save in public/images/{pa|ta|da}/#{id}.png
  # - try to find Gravatar image or generate random color image with login name first two letters
  # - used by app/jobs/generate_avatars_job.rb on server start is the directory doesn't exist
  # - returns nothing
  #
  def self.generate_avatar_for(user, avatars_dir)
    Rails.logger.debug { "AvatarService generate_avatar_for(#{user.id}, #{user.login}, #{avatars_dir})" }
    if user.email.present?
      return if download_and_save_gravatar(gravatar_url(user.email), avatars_dir, user.id)
    end
    # plan B - create and save random color two-letter avatar
    avatar_data_base64 = generate_base64_encoded_image(user.login)
    avatar_data_binary = Base64.decode64(avatar_data_base64)
    File.open(File.join(avatars_dir, "#{user.id}.png"), 'wb') do |file|
      file.write(avatar_data_binary)
    end
  end

  # generate avatar image with first two letters from login name and color background from login name hash
  #
  def self.generate_base64_avatar_from_login(login_name)
    Rails.logger.debug { "AvatarService generate_base64_avatar_from_login(#{login_name})" }
    base64_encoded_image = generate_base64_encoded_image(login_name.to_s)
    "data:image/png;base64,#{base64_encoded_image}"
  end

  # generate avatar image with first two letters from login name and random color background
  #
  def self.generate_base64_random_color_avatar(login_name)
    Rails.logger.debug { "AvatarService generate_base64_random_color_avatar(#{login_name})" }
    base64_encoded_image = generate_base64_encoded_image(login_name.to_s, self.random_rgb_color())
    "data:image/png;base64,#{base64_encoded_image}"
  end

  # generate avatar image from Gravatar for email
  #
  # return nil if no Gravatar is found
  #
  def self.generate_base64_avatar_from_email(email)
    Rails.logger.debug { "AvatarService generate_base64_avatar_from_email(#{email})" }
    if email.present?
      blob = download_gravatar(gravatar_url(email))
      if blob.present?
        base64_encoded_image = Base64.encode64(blob).gsub("\n", '')
        return "data:image/png;base64,#{base64_encoded_image}"
      end
    end

    Rails.logger.debug { "AvatarService no Gravatar is found" }
    return nil
  end

  # generate default avatar and save in 'public/images/0.png'
  # can be used to start creating new users
  #
  def self.generate_default_avatar(avatars_dir)
    Rails.logger.debug { "AvatarService generate_default_avatar(#{avatars_dir})" }
    avatar_data_base64 = generate_base64_encoded_image("?", "lightgray")
    avatar_data_binary = Base64.decode64(avatar_data_base64)
    File.open(File.join(avatars_dir, "0.png"), 'wb') do |file|
      file.write(avatar_data_binary)
    end
  end

  # store avatar image for user id
  # image comes from hidden field and contains data:image or image path
  #
  def self.store_avatar(user_id, avatar_image)
    Rails.logger.debug { "AvatarService store_avatar(#{user_id}, #{avatar_image.to_s.slice(0, 16)}...)" }
    if avatar_image.to_s.start_with?('data:image/png;base64,')
      # remove starting "data:image/png;base64,"
      avatar_image = avatar_image.split(',')[1]
      avatar_data_binary = Base64.decode64(avatar_image)
      File.open(File.join(AVATARS_DIR, "#{user_id}.png"), 'wb') do |file|
        file.write(avatar_data_binary)
      end
    else
      # ignore e.g. "/images/da/0.png"
      Rails.logger.debug { "AvatarService store_avatar ignored as not starting with \"data:image/png;base64,\"" }
    end
  end

  # return session avatar Base64 encoded image with inline image prefix
  # if session avatar file (e.g. "22535162c6b007d971290802e13e3244.png") exists
  #
  # else return nil
  #
  def self.session_avatar_image(session_id)
    session_avatar = "#{session_id}.png"
    avatar_path = File.join(AVATARS_DIR, session_avatar)
    if !File.exist?(avatar_path)
      Rails.logger.debug { "AvatarService no session_avatar_image found" }
      return nil
    end

    blob = File.binread(avatar_path)
    Rails.logger.debug { "AvatarService session_avatar_image #{session_avatar} found" }
    'data:image/png;base64,' + Base64.encode64(blob).gsub("\n", '')
  end

  def self.delete_session_avatar_image_file(session_id)
    session_avatar = "#{session_id}.png"
    avatar_path = File.join(AVATARS_DIR, session_avatar)
    File.delete(avatar_path) if File.exist?(avatar_path)
  end

  private

  # generate an avatar image with first two letters from login name and background color from login name hash
  # if no login_name is given "?" is used, if login_name has only one letter, this one letter is used
  #
  def self.generate_base64_encoded_image(login_name, individual_color = nil)
    letters = login_name.present? ? login_name.slice(0, 2) : "?" # '?', one or two letters
    individual_color = hash_to_color(login_name) unless individual_color.present?
    Rails.logger.debug { "AvatarService generate_base64_encoded_image #{individual_color} \"#{letters}\"" }
    canvas = Magick::Image.new(AVATAR_SIZE, AVATAR_SIZE) { |i| i.background_color = individual_color }
    draw = Magick::Draw.new
    if is_latin(letters)
      # draw.font_family = 'DejaVu-Sans' # see convert -list font for available fonts
      draw.font = 'app/assets/fonts/Gondoliere.ttf'
      draw.pointsize = 50 # downsized from 60 to 50 so that "Ál" is fully visible with capital letters
    else
      # for japanese and ukrainian letters
      draw.font = 'app/assets/fonts/NotoSansJP-Regular.ttf'
      draw.pointsize = 40
    end

    draw.gravity = Magick::CenterGravity
    draw.fill = contrast_color(individual_color)
    draw.annotate(canvas, 0, 0, 0, 0, letters)
    canvas.format = 'PNG'
    blob = canvas.to_blob
    Base64.encode64(blob).gsub("\n", '')
  end

  # random RGB color as hexadecimal string, e.g. '#FF4300'
  #
  def self.random_rgb_color
    red   = rand(0..255).to_s(16).rjust(2, '0')
    green = rand(0..255).to_s(16).rjust(2, '0')
    blue  = rand(0..255).to_s(16).rjust(2, '0')
    "##{red}#{green}#{blue}"
  end

  # calculate a individual color from login name
  #
  def self.hash_to_color(str)
    hash = Digest::MD5.hexdigest(str).hex
    "##{hash.to_s(16).slice(0, 6)}"
  end

  # calculate background color luminance to decide to use blacl or white as font color
  #
  def self.contrast_color(hex_color)
    # strip the leading '#' if present
    hex_color = hex_color.gsub('#', '')

    # convert hex to RGB values
    r, g, b = hex_color.scan(/../).map { |color| color.to_i(16) }

    # calculate luminance
    luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255

    # if the luminance is less than 0.5, white is a good opposite; otherwise, use black
    luminance < 0.5 ? '#FFFFFF' : '#000000'
  end

  # verifying that characters are in the Latin script and not Cyrillic or Japanese
  #
  def self.is_latin(text)
    # simplified unicode ranges covering latin characters, including extended latin characters
    latin_ranges = [
      (0x0041..0x007A), # Basic Latin (A-Z, a-z)
      (0x00C0..0x00FF), # Latin-1 Supplement (À-ÿ)
      (0x0100..0x017F), # Latin Extended-A
      (0x0180..0x024F)  # Latin Extended-B
    ]

    text.each_codepoint do |char_code|
      # Check if char_code is not in any of the latin_ranges
      unless latin_ranges.any? { |range| range.include?(char_code) }
        return false
      end
    end

    true
  end

  # return Gravatar URI for given email address or nil
  #
  def self.gravatar_url(email)
    # note: email may not exist as in development database copy the emails are cleaned
    return nil unless email.present?

    gravatar_id = Digest::MD5.hexdigest((email || "").downcase)
    uri = "https://gravatar.com/avatar/#{gravatar_id}?s=#{AVATAR_SIZE}&d=404"
    Rails.logger.debug { "AvatarService Gravatar URI \"#{uri}\"" }
    URI(uri)
  end

  # download and save Gravatar image
  # return true for success and false if no Gravatar is found
  #
  def self.download_and_save_gravatar(url, avatars_dir, user_id)
    file = File.join(avatars_dir, "#{user_id}.png")
    blob = download_gravatar(url)
    if (blob.present?)
      File.open(file, 'wb') do |file|
        file.write(blob)
      end
      if File.exist?(file) && !File.zero?(file)
        Rails.logger.debug { "AvatarService found Gravatar for users email" }
        return true
      end
    end

    return false
  end

  # download Gravatar image and return the image as binary
  # returns empty string in case of any problem, e.g. no Gravatar exist
  #
  # this is a time consuming network request to the Gravatar server, typically 500 ms
  #
  def self.download_gravatar(url)
    blob = ''
    Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(url)
      response = Net::HTTP.get_response(url)
      http.request(request) do |response|
        if response.is_a?(Net::HTTPSuccess)
          response.read_body do |chunk|
            blob += chunk
          end
        end
      end
    end
    blob
  end

  # return Gravatar URL for email or nil
  #
  def self.gravataer_url(email)
    # note: email may not exist as in the development database copy the emails are cleaned
    return nil unless email.present?

    gravatar_id = Digest::MD5.hexdigest(email.downcase)
    URI("https://gravatar.com/avatar/#{gravatar_id}?s=#{AVATAR_SIZE}&d=404")
  end
end
