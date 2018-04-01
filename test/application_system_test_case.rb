require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  driven_by :selenium_chrome_headless, screen_size: [1400, 1400] 

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
