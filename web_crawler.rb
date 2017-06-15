require 'nokogiri'
require 'open-uri'

class Crawler

  def initialize(head)
    @links = [head]
  end

  def fetch_url_data(url)
    uri = URI.parse(url)
    tries = 3

    begin
      uri.open(redirect: false) do |f|
        doc = Nokogiri.parse(f)
        phone_numbers = doc.text.scan(/^\s*(?:\+?(\d{1,3}))?[-. (]*(\d{3})[-. )]*(\d{3})[-. ]*(\d{4})(?: *x(\d+))?\s*$/)

        found_links = doc.css('a').map { |link| link.attribute('href').to_s }
        .uniq.sort.delete_if(&:empty?)

        # Dump phone numbers into text file
        File.open('phone_numbers.txt', 'a') do |file|
          file << phone_numbers
        end

        found_links.each do |link|
          if link[0] == '/'
            @links << url.concat(link)
          elsif link[0] == 'h'
            @link << url if @link
          end
        end

      end
    rescue OpenURI::HTTPRedirect => redirect
      uri = redirect.uri
      retry if (tries -= 1) > 0
      raise
    end
  end

  def crawl_links
    return if @links.empty?
    fetch_url_data(@links.shift)
    crawl_links
  end
end


# Takes a list of links separated by newlines
File.readlines('links.txt').each do |link|
  crawler = Crawler.new(link.chomp)
  crawler.crawl_links
end
