require 'test_helper'

class UrlCheckerServiceTest < ActiveSupport::TestCase
  test 'returns true for 200 response' do
    assert_equal 'https://www.zitat-service.de', UrlCheckerService.check('https://www.zitat-service.de')
  end

  test 'https URL for http' do
    assert_equal 'https://www.zitat-service.de/en/authors', UrlCheckerService.check('http://www.zitat-service.de/en/authors')
  end

  test 'redir' do
    assert_equal 'https://www.zitat-service.de/en/quotations', UrlCheckerService.check('https://www.zitat-service.de/en/quotations/')
  end

  test 'redir and https' do
    assert_equal 'https://www.zitat-service.de/en/quotations', UrlCheckerService.check('http://www.zitat-service.de/en/quotations/')
  end

  test '404' do
    assert_nil UrlCheckerService.check('https://www.zitat-service.de/cheesecake')
  end

  test 'http only website' do
    assert_equal 'http://http_only.heikol.de', UrlCheckerService.check('http://http_only.heikol.de')
  end

  test 'http only website and redirection' do
    assert_equal 'http://http_only.heikol.de/redirected.html', UrlCheckerService.check('http://http_only.heikol.de/redir.html')
  end

  test "nil, empty string and bullshit" do
    assert_nil UrlCheckerService.check(nil)
    assert_nil UrlCheckerService.check("")
    assert_nil UrlCheckerService.check("bullshit")
  end

  test "URL unencode" do
    assert_equal "https://de.wikipedia.org/wiki/Antoine_de_Saint-Exupéry",
                 UrlCheckerService.check("http://de.wikipedia.org/wiki/Antoine_de_Saint-Exup%C3%A9ry")
  end
end
