require 'open-uri'
require 'nokogiri'
require 'date'
require 'json'

def scrap
  result = {}
  (1..12).each do |month_index|
    (1..31).each do |day_index|
      begin
        day, month = form_date(day_index, month_index)

        puts "Scraping #{month} #{day}..."

        description, events, births, deaths = extract_from(day, month)

        result["#{month}-#{day}".to_sym] = {
          description: description, events: events, births: births, deaths: deaths
        }
      rescue NoMethodError
        puts 'It seems this date does not have any episodes.'
      end
    end
  end

  export_to_file(result)
end

def form_date(day_index, month_index)
  date = Date._strptime("#{day_index}/#{month_index}", '%d/%m')
  [date[:mday], Date::MONTHNAMES[date[:mon]]]
end

def extract_from(day, month)
  wikilink = URI.encode("https://bn.wikipedia.org/wiki/#{month}_#{day}")
  html = Nokogiri::HTML open(wikilink)

  description = html.css('#mw-content-text p')
                    .map(&:text)
                    .find { |text| text.include?("জানুয়ারি ") || text.include?("ফেব্রুয়ারি ") || text.include?("মার্চ ") || text.include?("এপ্রিল ") || text.include?("মে ") || text.include?("জুন ") || text.include?("জুলাই ") || text.include?("আগস্ট ") || text.include?("সেপ্টেম্বর ") || text.include?("অক্টোবর ") || text.include?("নভেম্বর ") || text.include?("ডিসেম্বর ") }

  events = parse_ul html.css('#mw-content-text.mw-content-ltr ul')[1]
  births = parse_ul html.css('#mw-content-text.mw-content-ltr ul')[2]
  deaths = parse_ul html.css('#mw-content-text.mw-content-ltr ul')[3]

  [description, events, births, deaths]
end

def parse_ul(ul)
  ul.css('li').map do |li|
    year, *text = li.text.split(/[-–]/).map(&:strip)
    { year: year, data: text.join('-') }
  end
end

def export_to_file(hash_data)
  File.write('episodes_bn.json', hash_data.to_json)
  puts 'Results stored in episodes_bn.json'
end

scrap
