require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  driven_by :selenium_chrome_headless, screen_size: [1400, 1400] 

  def check_page page, path, selector, content, size
    visit path
    # assert page.status_code, '200'
    if selector.nil?
      assert page.text.include?(content), "page \"#{path}\" is missing text \"#{content}\""
    else
      assert_selector selector, text: content
    end
    assert page.text.length >= size, "page \"#{path}\" is with #{page.text.length.to_s} smaller than #{size.to_s}"
  end

end
