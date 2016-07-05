require_relative '../crawler/school_scraper'
require_relative '../helpers/school_constants'

class AllAboutSchools
  include SchoolConstants

  def self.run
    new.call
  end

  def call
    display_header('Welcome to Campus Viewer')
    display_help
    run
  end

  def display_header(header, filler='*~', amount=3)
    puts "\n#{filler*amount} #{header} #{filler*amount}"
  end

  def display(schools)
    schools.each.with_index { |school, index| puts "#{index.next}. #{school.name}\n    #{school.address}\n    #{school.phone_number}\n    #{school.website}" }
  end

  def get_user_input
    gets.chomp.strip
  end

  def invalid
    puts "Error: That command is Invalid."
  end

  def run
    print "What would you like to do? "
    case get_user_input.downcase
    when /c|cuny/ then process_cuny_schools
    when /s|suny/ then process_suny_schools
    when /h|help/ then display_help
    when /e|q|exit|quit/ then terminate_program
    else puts 'Error! That command is invalid! Please try again.'
    end
    run
  end

  def process_cuny_schools
    cuny_saved = File.exist? 'lib/parsed_datas/cuny_school_info.json'
    url = "#{CUNY_BASE_URL}/about/colleges-schools/"
    school_scraper = SchoolScraper.new url: url, type: 'cuny'
    schools = parse_schools school_scraper, cuny_saved
    puts 'Found your cuny schools!'
    display schools
    view_map_selector schools
  end

  def parse_schools(scraper, saved)
    saved ? scraper.read_file : scraper.filter_schools
  end

  def process_suny_schools
    suny_saved = File.exist? 'lib/parsed_datas/suny_school_info.json'
    url = "#{SUNY_BASE_URL}/attend/visit-us/complete-campus-list/"
    school_scraper = SchoolScraper.new url: url, type: 'suny'
    schools = parse_schools school_scraper, suny_saved
    puts 'Found your suny schools!'
    display schools
    view_map_selector schools
  end

  def view_map_selector(schools)
    print 'Would you like to see a school? (Y)es or (N)o: '
    case get_user_input.downcase
    when /y|yes/ then select_campus(schools)
    when /n|no/ then puts 'Aww man. The campus viewer is pretty cool! Maybe next time.'
    else invalid
    end
  end

  def select_campus(schools)
    print 'Select a number: '
    number = get_user_input.to_i
    open_campus_view schools[number.pred]
  end

  def open_campus_view(school)
    `open "#{school.campusview}"`
  end

  def display_help
    puts "\nType 'c' or 'cuny' to search through cuny schools"
    puts "Type 's' or 'suny' to search through suny schools"
    puts "Type 'h' or 'help' to view this menu again"
    puts "Type 'q', 'e' 'quit', or 'exit' to exit\n\n"
  end

  def terminate_program
    puts "Hope you liked Campus Viewer. Hope to see you soon!"
    exit
  end
end
