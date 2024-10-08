require "test_helper"
require 'capybara/rails'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # w/o Docker
  # driven_by :selenium_chrome_headless, screen_size: [1400, 1400]

  # see https://nicolasiensen.github.io/2022-03-11-running-rails-system-tests-with-docker/
  driven_by :selenium, using: :chrome, screen_size: [1200, 1800], options: {
    browser: :remote, url: "http://chrome:4444"
  }

  def setup
    Capybara.app_host = "http://rails:3100"
    Capybara.default_max_wait_time = 10 # default 2 seconds are not long enough for translations
    Capybara.server_port = 3100 # puma listening port 3100 on TEST
    Capybara.server_host = "0.0.0.0"
    Capybara.default_driver = :selenium # not using default :rack_test w/o JavaScript
    super
  end

  DEFAULT_MIN_PAGE_SIZE = 200 # bytes
  MAX_EXECUTION_TIME = 1000 # milliseconds

  # visiting page with given path, finding content for selector, verifying minimum page size and loading speed
  #   - if running longer than one second first time, after a short breath, making a second attempt to be successfull
  #     in Docker env as well
  #   - finally checking for broken images
  def check_page page, path, selector, content = nil, size = DEFAULT_MIN_PAGE_SIZE, first_time = true,
                 max_execution_time = MAX_EXECUTION_TIME
    Rails.logger.debug "check_page path=#{path} selector=#{selector} " +
                       content.class.name +
                       "-content=\"#{content}\" size=#{size} first_time=#{first_time} " +
                       "max_execution_time=#{max_execution_time}"
    start_millisecond = (Time.now.to_f * 1000).to_i
    visit path unless path.nil?
    run_time = (Time.now.to_f * 1000).to_i - start_millisecond
    if selector.nil?
      assert false,
             "page \"#{page.current_url}\" is missing " +
             content.class.name + " \"#{content}\"" unless page.has_text?(content)
    elsif content.nil?
      assert_selector selector, visible: true
    else
      assert_selector selector, text: content, visible: true
    end
    assert page.text.length >= size,
           "page \"#{page.current_url}\" is with #{page.text.length.to_s} smaller than #{size.to_s}"
    if run_time > max_execution_time
      if first_time
        Rails.logger.debug "execution time was too slow with #{run_time} ms, trying second time"
        # just take a breath and then try it a second time, maybe the Docker environment was too slow at first
        sleep 1
        check_page page, path, selector, content, size, false
      else
        assert false, "page \"#{path}\" took #{run_time} milliseconds (second time)"
      end
    end
    # final check for missing images
    detect_broken_images
  end

  # do check_page w/o visiting new path
  def check_this_page page, selector, content = nil, size = DEFAULT_MIN_PAGE_SIZE, first_time = true,
                      max_execution_time = MAX_EXECUTION_TIME
    check_page page, nil, selector, content, size, first_time, max_execution_time
  end

  def check_page_source page, pattern
    assert false, "page \"#{page.current_url}\" is missing pattern \"#{pattern}\"" unless page.source =~ /#{pattern}/m
  end

  def do_login user = :first_user, password = :first_user_password,
               pattern = /Welcome to the quote service zitat-service.de/
    visit login_url
    fill_in 'user_session_login', with: user
    fill_in 'user_session_password', with: password
    click_on 'Log In'
    check_this_page page, "h1", pattern # wait for turbo to be completed
  end

  # detecting broken images (which results in a 404 error when accessed)
  def detect_broken_images
    # execute JavaScript to check for broken images
    # have it more stable and handle potential race conditions where images might not have finished loading
    # - image loading check is wrapped in a promise that resolves when all images have either loaded or failed to load,
    #   by attaching load and error event listeners to each image
    # - waits for all images to either load or fail to load
    # - check for image width 0
    broken_images = page.execute_script(<<~JS)
      function waitForImagesToLoad() {
        return new Promise((resolve, reject) => {
          let images = Array.from(document.querySelectorAll('img'));
          let loaded = 0;

          images.forEach(img => {
            // if the image is already loaded or failed, count it
            if (img.complete) {
              loaded++;
              if (loaded === images.length) resolve(checkForBrokenImages());
            } else {
              // otherwise, attach load and error listeners
              img.addEventListener('load', () => {
                loaded++;
                if (loaded === images.length) resolve(checkForBrokenImages());
              });
              img.addEventListener('error', () => {
                loaded++;
                if (loaded === images.length) resolve(checkForBrokenImages());
              });
            }
          });

          // immediate resolve if there are no images
          if (images.length === 0) resolve([]);
        });
      }

      function checkForBrokenImages() {
        var brokenImages = [];
        document.querySelectorAll('img').forEach(function(img) {
          if (!img.complete || img.naturalWidth == 0) {
            brokenImages.push(img.src);
          }
        });
        return brokenImages;
      }

      return waitForImagesToLoad();
    JS

    assert false, "Broken images detected: #{broken_images.join(', ')}." if broken_images.any?
  end
end
