require "test_helper"
require 'capybara/rails'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  # w/o Docker
  # driven_by :selenium_chrome_headless, screen_size: [1400, 1400] 

  # see https://medium.com/@pacuna/using-rails-5-1-system-tests-with-docker-a90c52ed0648
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400], options: {url: "http://chrome:4444/wd/hub"}
  #
  def setup
    host! "http://rails:3100"
    super
  end
  # puma listening port 3100 on TEST 
  Capybara.server_port = 3100
  Capybara.server_host = "0.0.0.0"

  # visiting page with given path, finding content for selector, verifying minimum page size and loading speed
  #
  def check_page page, path, selector, content, size
    start_millisecond = (Time.now.to_f * 1000).to_i
    visit path
    run_time = (Time.now.to_f * 1000).to_i - start_millisecond
    if selector.nil?
      assert page.text.include?(content), "page \"#{path}\" is missing text \"#{content}\""
    else
      assert_selector selector, text: content
    end
    assert page.text.length >= size, "page \"#{path}\" is with #{page.text.length.to_s} smaller than #{size.to_s}"
    assert run_time <= 500, "page \"#{path}\" took #{run_time} milliseconds"
  end

end
