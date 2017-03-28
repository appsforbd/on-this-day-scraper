require 'open-uri'
require 'nokogiri'
require 'date'
require 'json'

def scrap
  result = {}
  (1..1).each do |month_index|
    (1..1).each do |day_index|
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
  html = Nokogiri::HTML open("https://bn.wikipedia.org/wiki/#{month}_#{day}")

  description = html.css('#mw-content-text p')
                    .map(&:text)
                    .find { |text| text.include?("#{month} #{day}") }

  events = parse_ul html.css('#.E0.A6.98.E0.A6.9F.E0.A6.A8.E0.A6.BE.E0.A6.AC.E0.A6.B2.E0.A7.80')[0].parent.next_element
  births = parse_ul html.css('#.E0.A6.9C.E0.A6.A8.E0.A7.8D.E0.A6.AE.E0.A6.A6.E0.A6.BF.E0.A6.A8')[0].parent.next_element
  deaths = parse_ul html.css('#.E0.A6.AE.E0.A7.83.E0.A6.A4.E0.A7.8D.E0.A6.AF.E0.A7.81.E0.A6.A6.E0.A6.BF.E0.A6.A8')[0].parent.next_element

  [description, events, births, deaths]
end

def parse_ul(ul)
  ul.css('li').map do |li|
    year, *text = li.text.split(' – ')
    { year: year, data: text.join(' – ') }
  end
end

def export_to_file(hash_data)
  File.write('episodes_bn.json', hash_data.to_json)
  puts 'Results stored in episodes_bn.json'
end

scrap
