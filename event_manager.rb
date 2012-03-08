require "csv"
require 'sunlight'

class EventManager
	INVALID_ZIPCODE = "00000"
	Sunlight::Base.api_key = "e179a6973728c4dd3fb1204283aaccb5"

  def initialize(filename)
	puts "EventManager Initialized."
	@file = CSV.open(filename, {:headers => true, :header_converters => :symbol})
  end

  def print_names
	@file.each do |line|
	  puts "#{line[:first_name]} #{line[:last_name]}"
	end
  end

  def print_numbers
	@file.each do |line|
	  number = clean_number(line[:homephone])
	  puts number
	end
  end

  def print_zipcodes
	@file.each do |line|
	  zipcode = clean_zip(line[:zipcode])
	  puts zipcode
	end
  end

  def output_data(filename)
  	output = CSV.open(filename, "w")
  	@file.each do |line|
  		if @file.lineno == 2 ## For some reason I had to use 2...
  			output << line.headers
  		end
  		line[:homephone] = clean_number(line[:homephone])
  		line[:zipcode] = clean_zip(line[:zipcode])
  		output << line
  	end
  end

  def rep_lookup
  	20.times do
  		line = @file.readline
  		represantive = "unknown"

		legislators = Sunlight::Legislator.all_in_zipcode(clean_zip(line[:zipcode]))

		names = legislators.collect do |leg|
			leg.title + " " + leg.firstname[0] + ". " + leg.lastname + " (" + leg.party + ")"
		end

  		#API LOOK UP
  		puts "#{line[:last_name]}, #{line[:first_name]}, #{line[:zipcode]}, #{names.join(", ")}"
  	end
  end 

  def create_form_letters
    letter = File.open("form_letter.html", "r").read
    20.times do
      line = @file.readline
		custom_letter = letter.gsub("#first_name",line[:first_name]).gsub("#last_name",line[:last_name]).gsub("#street",line[:street]).gsub("#city",line[:city]).gsub("#state",line[:state]).gsub("#zipcode",clean_zip(line[:zipcode]))
    	filename = "output/thanks_#{line[:last_name]}_#{line[:first_name]}.html"
		output = File.new(filename, "w")
		output.write(custom_letter)
    end
  end
  def rank_times
  	hours = Array.new(24){ 0 }
  	@file.each do |line|
  		time = line[:regdate].split(" ")
  		hour = time[1].split(":")
  		#puts "it is " + hour[0]
  		hours[hour[0].to_i] = hours[hour[0].to_i] + 1
  	end

  	hours.each_with_index { |counter, hour| puts "#{hour}\t#{counter}"}
  end

  def day_stats ## Monday & Saturday are most common
   	days = Array.new(7){ 0 }
  	@file.each do |line|
  		time = line[:regdate].split(" ")
  		date = Date.strptime(time[0], "%m/%d/%Y")
  		days[date.wday] = days[date.wday] + 1
  	end

  	days.each_with_index { |counter, day| puts "#{day}\t#{counter}"} 	
  end

  def state_stats
    state_data = {}
    @file.each do |line|
      state = line[:state] unless line[:state].nil? # Find the State
      if state_data[state].nil? # Does the state's bucket exist in state_data?
        state_data[state] = 1 # If that bucket was nil then start it with this one person
      else
        state_data[state] = state_data[state] + 1  # If the bucket exists, add one
      end
    end

    state_data = state_data.sort_by{|state, counter| state unless state.nil?}

    state_data.each do |state,counter|
    	puts "#{state}: #{counter}"
    end
  end

  private

  def clean_zip(number)
  	if number.nil?
  		fixed_numb = INVALID_ZIPCODE
	elsif number.length < 5
		fixed_numb = sprintf '%05d', number
 	else
	  ## number is correct
	  fixed_numb = number
	end
	return fixed_numb
  end
  
  def clean_number(number)
	number.delete! "-. ()"
	if number.length == 10
	  ## all good
	elsif number.length == 11
	  number = number[1..-1]
	else
	  number = "0000000000"
	end
	return number
  end

end

manager = EventManager.new("event_attendees.csv")
manager.state_stats
