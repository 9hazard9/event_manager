require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'
require 'date'
require 'time'

DOW = {'0'=>'Sunday','1'=>'Monday','2'=>'Tuesday','3'=>'Wednesday"','4'=>'Thursday','5'=>'Friday','6'=>'Saturday'}

def clean_zipcode(zipcode)
    zipcode.to_s.rjust(5,'0')[0..4]
end

def clean_phonenumber(phonenumber)
    clean_number = phonenumber.gsub(/[^\d]/,'')

    if clean_number.length == 11 && clean_number[0] == '1'
        clean_number[1..10]
    elsif clean_number.length == 10
        clean_number
    else
        "Invalid Phone Number"
    end
end

def target_time(dates)
    #Map hours to number of registrants
    hours = dates.map { |date| date[/\d+(?=:)/] }.tally
    #Determine the maximum number of registrants by hour
    peak_nbr = hours.max_by(&:last).last

    #Determine the hours having peak_nbr registrants
    hours.select {|_hr,nbr| nbr == peak_nbr}.keys.join(', ')
end

def target_day(dates)
    days = dates.map {|date| Date.strptime(date, "%m/%d/%y").wday}.tally

    peak_days = days.max_by(&:last).last
  
    days.select{|_day,tally| tally == peak_days}.keys.join(", ")
end

def target_

def legislators_by_zipcode(zip) 
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.represenative_info_by_address(
            address: zipcode, 
            levels: 'country', 
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
        'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def save_thank_you_letter(id,form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')
  
    filename = "output/thanks_#{id}.html"
  
    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
    'event_attendees.csv',
    headers: true,
    header_converters: :symbol
    )

template_letter = File.read('form_letter.html')
erb_template = ERB.new template_letter

dates = Array.new

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    phonenumber = clean_phonenumber(row[:homephone])
    legislators = legislators_by_zipcode(zipcode)

    dates << row[:regdate]

    form_letter = erb_template.result(binding)

    Dir.mkdir('output') unless Dir.exist?('output')

    save_thank_you_letter(id, form_letter)
end

puts "Most Active Hour(s) is : #{target_time(dates)}"
puts "Most Active Day is: #{DOW[target_day(dates)]}"