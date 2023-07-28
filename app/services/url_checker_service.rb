require 'net/http'

class UrlCheckerService
  MAX_ITERATIONS = 3

  # Is given URL valid, reachable or could be improved?
  # returns url (which may be changed) on success or nil on error
  # - does URL unencode
  # - can follow redir
  # - tries to find https available if http is used
  # - can handle multiple redirs, e.g. first redir to https and second redir w/o trailing '/'
  def self.check(url, iteration = 1, http_working_url = nil)
    Rails.logger.debug {
      "UrlCheckerService.check(url=#{url}, iteration ##{iteration}, http_working_url=#{http_working_url})"
    }
    url_unencoded = Addressable::URI.unencode(url)

    if url != url_unencoded
      Rails.logger.debug { "URL unencoded #{url_unencoded}" }
    end

    uri = URI.parse(Addressable::URI.encode(url_unencoded))
    return nil if !uri or !uri.host or !uri.scheme or !uri.request_uri

    response = send_head_request(uri)

    process_response(response, uri, iteration, http_working_url, url_unencoded)
  rescue => e
    Rails.logger.info { "Exception while checking URL #{url_unencoded}: #{e.message}" }
    http_working_url if http_working_url.present?
  end

  def self.send_head_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    request = Net::HTTP::Head.new(uri.request_uri)
    http.request(request)
  end

  def self.process_response(response, uri, iteration, http_working_url, url_unencoded)
    case response
    when Net::HTTPSuccess
      process_success(uri, iteration, url_unencoded)
    when Net::HTTPRedirection
      process_redirection(uri, url_unencoded, iteration, response['location'])
    else
      Rails.logger.info { "#{url_unencoded} is not valid" }
      nil
    end
  end

  def self.process_success(uri, iteration, url_unencoded)
    if uri.scheme == 'http' && iteration <= MAX_ITERATIONS
      uri.scheme = 'https'
      check(uri.to_s, iteration + 1, url_unencoded)
    else
      url_unencoded
    end
  end

  def self.process_redirection(uri, url_unencoded, iteration, location)
    new_url = URI.join(Addressable::URI.encode(url_unencoded), location).to_s
    Rails.logger.info { "Link is changed after redirection from #{url_unencoded} to #{new_url}" }
    return new_url if new_url == url_unencoded || iteration > MAX_ITERATIONS

    check(new_url, iteration + 1)
  end
end
