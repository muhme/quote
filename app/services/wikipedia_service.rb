require 'net/http'
require 'json'
require 'uri'
require 'rest-client'
require 'nokogiri'
require 'addressable/uri'

# collection of all Wikipedia API requests and helper methods
#
class WikipediaService
  # The call method is the main method for the WikiService and does the following:
  #   1. Parses the last part of the author's current link to get the title of the Wikipedia page.
  #   2. Constructs a URL to request the Wikipedia API for 'langlinks' property of the page with
  #      this title in the language specified by current_locale.
  #   3. Sends an HTTP GET request to this URL.
  #   4. If the response status is 200 (OK), it processes the response.
  #      - It parses the JSON response body to get the "pages" field.
  #      - For each page in the response, it checks if the page has "langlinks".
  #      - For each language link in "langlinks", it checks if the language is one of the desired ones
  #        (English, Spanish, Ukrainian, Japanese or German).
  #      - If it is, it sets the author's link for this language to the URL provided in the response.
  def call(locale, link)
    return if link.blank?

    # parse the author's current link and take the last part of the path URL encoded as the title to ...
    title = CGI.escape(link.split("/").last) # URI.parse(@author.link).path.split('/').last
    # ... generate the URL for the Wikipedia API request based on the current locale and title
    url = URI.parse("https://#{locale}.wikipedia.org/w/api.php?action=query&format=json&prop=langlinks&titles=#{title}&lllimit=500&llprop=url")
    Rails.logger.debug { "WikiService requesting #{url}" }

    # create an HTTP GET request
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(url.request_uri)

    # send the HTTP request and store the response
    response = http.request(request)

    links = {}
    names = {}

    # if the response status is 200 (OK), process the response
    if response.code == "200"
      # parse the JSON response body and get the "pages" field
      result = JSON.parse(response.body)
      pages = result["query"]["pages"]

      # for each page in the response
      pages.each do |_pageid, page|
        # the page has "langlinks"?
        if page["langlinks"]
          # for each language link in "langlinks"
          page["langlinks"].each do |langlink|
            # get language, URL of the link and name (*)
            lang = langlink["lang"]
            name = langlink["*"]
            # "Мадонна (співачка)" ->  "Мадонна"
            name = name.gsub(/ \(.*\)/, "")
            wiki_url = langlink["url"]
            # set the link attribute in the different locales
            if ['de', 'en', 'es', 'ja', 'uk'].include?(lang)
              Mobility.with_locale(lang) do
                wiki_url = CGI.unescape(wiki_url)
                Rails.logger.debug { "WikiService #{lang}: #{name} #{wiki_url}" }
                links[lang] = wiki_url
                names[lang] = name
              end
            end
          end
        end
      end
    end

    { links: links, names: names }
  end

  # if we have wikipedia link, then find links in other locales and use author name from wikipedia
  def ask_wikipedia(actual_locale, author)
    if author.link =~ /http.*wikipedia.org\//
      # change http to https, delete mobile version, follow redirection
      author.link = WikipediaService.new.clean_link(author.link)
      result = WikipediaService.new.call(actual_locale, author.link)
      links = result[:links]
      names = result[:names]
      I18n.available_locales.each do |locale|
        if locale != actual_locale
          author.send("link_#{locale}=", links[locale.to_s])
          if names[locale.to_s].present?
            result = split_name(names[locale.to_s], locale)
            author.send("firstname_#{locale}=", result[:firstname])
            author.send("name_#{locale}=", result[:lastname])
          else
            author.send("firstname_#{locale}=", nil)
            author.send("name_#{locale}=", nil)
          end
        end
      end
    end
  end

  # clean the authors link in the analogy of washing clothes
  # changes by sample are:
  #   1. http to https
  #        http://de.wikipedia.org/wiki/Friedrich_Schiller
  #        https://de.wikipedia.org/wiki/Friedrich_Schiller
  #   2. delete mobile version
  #        https://de.m.wikipedia.org/wiki/Olena_Selenska
  #        https://de.wikipedia.org/wiki/Olena_Selenska
  #   3. follow wikipedia redirection
  #        http://de.wikipedia.org/wiki/Schiller
  #        http://de.wikipedia.org/wiki/Friedrich_Schiller
  #   4. URL encode
  #        https://de.wikipedia.org/wiki/Ry%C5%ABichi_Sakamoto
  #        https://de.wikipedia.org/wiki/Ryūichi_Sakamoto
  #
  # for #3 we have to find the redirection in HTML/CSS by sample:
  # <div id="mw-content-text" class="mw-body-content mw-content-ltr" lang="de" dir="ltr">
  #   <div class="mw-parser-output">
  #     <div class="redirectMsg">
  #       <p>Weiterleitung nach:</p>
  #       <ul class="redirectText">
  #         <li><a href="/wiki/Friedrich_Schiller" title="Friedrich Schiller">Friedrich Schiller</a></li>
  #
  def clean_link(link)
    return nil if link.blank?

    uri = Addressable::URI.parse(link)
    uri.scheme = 'https' # 1
    uri.host = uri.host.sub(/\.m\./, '.') # 2

    # HTTP Requests and HTML Parsing to check redirect in wikipedia
    if uri.host.include?('wikipedia.org')
      begin
        # doing unencode before encode to ensure not to encode twice
        uri_encoded = Addressable::URI.encode(Addressable::URI.unencode(uri))
        response = RestClient.get("#{uri_encoded}?redirect=no")
        if response.code != 200
          Rails.logger.warn { "Failed to follow redirects for #{uri_encoded}. Response code: #{response.code}." }
        else
          doc = Nokogiri::HTML(response.body)
          redirect_link = doc.at_css('.redirectText a')
          if redirect_link && redirect_link_href = redirect_link['href']
            uri.path = redirect_link_href # 3
          end
        end
      rescue Exception => exc
        # note problem
        problem = "#{exc.class} #{exc.message}"
        Rails.logger.error "RestClient.get(#{uri_encoded}) exception #{problem}"
        # no flash[:error]
      end
    end

    washed = Addressable::URI.unencode(uri) # 4
    Rails.logger.debug { "WikipediaService.clean_link cleaned=#{washed}" if washed != link }
    washed
  end

  private

  # split in firstname on last space or japanese ・
  # if not special case with
  #   en: ' the ' e.g. Seneca the Younger
  def split_name(fullname, locale)
    if locale == :en and fullname =~ / the /
      return { firstname: '', lastname: fullname }
    end

    delimiter = locale == :ja ? '・' : ' '
    parts = fullname.rpartition(delimiter)
    Rails.logger.debug("split_name #{parts.inspect}")
    { firstname: parts[0], lastname: parts[2] }
  end
end
