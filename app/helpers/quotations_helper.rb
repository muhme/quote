module QuotationsHelper

  # returns - with links if exist - authors name and quotations source name or blank
  # returns "", "authors name", "source" or "authors name, source"
  # ignore author.id == 0 "unknown"
  #
  def get_linked_author_and_source(quote)
    my_source = quote.source
    my_source = "<a href=\"#{quote.source_link}\" target=\"quote_extern\">#{quote.source}</a>" unless quote.source.blank? or quote.source_link.blank?
    ret = quote.author && quote.author.id != 0 ? quote.author.get_linked_author_name_or_blank : ""
    ret += ", " unless ret.blank? or my_source.blank?
    ret += my_source unless my_source.blank?
    ret
  end

  # returns quote with link
  def get_linked_quotation(quote)
    link_to quote.quotation, controller: :quotations, action: :show, id: quote.id
  end
end
