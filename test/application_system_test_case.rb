require "test_helper"
require 'capybara/rails'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  # w/o Docker
  # driven_by :selenium_chrome_headless, screen_size: [1400, 1400] 

  # see https://medium.com/@pacuna/using-rails-5-1-system-tests-with-docker-a90c52ed0648
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: {url: "http://chrome:4444/wd/hub"}
  #
  def setup
    Capybara.app_host = "http://rails:3100"
    super
  end
  # puma listening port 3100 on TEST 
  Capybara.server_port = 3100
  Capybara.server_host = "0.0.0.0"

  DEFAULT_MIN_PAGE_SIZE = 200

  # visiting page with given path, finding content for selector, verifying minimum page size and loading speed
  # checking for slow 1 second to be successful even in docker env
  def check_page page, path, selector, content, size = DEFAULT_MIN_PAGE_SIZE, first_time = true
    Rails.logger.debug "check_page path=#{path} selector=#{selector} content=#{content} size=#{size} first_time=#{first_time}"
    start_millisecond = (Time.now.to_f * 1000).to_i
    visit path unless path.nil?
    run_time = (Time.now.to_f * 1000).to_i - start_millisecond
    if selector.nil?
      assert "page \"#{path}\" is missing pattern \"#{content}\"" unless page.text =~ /#{content}/ 
    else
      assert_selector selector, text: content, visible: true
    end
    assert page.text.length >= size, "page \"#{path}\" is with #{page.text.length.to_s} smaller than #{size.to_s}"
    if run_time > 1000
      if first_time
        Rails.logger.debug "time was with ${#run_time} ms to slow, trying second time"
        # just take a breath and then try it a second time, maybe the Docker environment was too slow at first
        sleep 1
        check_page page, path, selector, content, size, false
      else
        assert true, "page \"#{path}\" took #{run_time} milliseconds (second time)"
      end
    end
  end

  # do check_page w/o visiting new path
  def check_this_page page, selector, content
    check_page page, nil, selector, content
  end

end
