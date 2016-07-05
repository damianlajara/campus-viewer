require 'open-uri'
require 'json'
require 'nokogiri'
require 'ruby-progressbar'
require 'pry'
require_relative '../models/school'
require_relative '../helpers/school_constants'

class SchoolScraper
  attr_reader :html, :type

  def initialize(school_info = {})
    raise ArgumentError.new('You need to pass an url and a type to SchoolScraper #new') if school_info.empty?
    @type = school_info[:type]
    @html = Nokogiri::HTML(open(school_info[:url]))
    @list_of_scraped_schools = scraped_schools
    @school_hash = {}
    @schools = []
  end

  def scraped_schools
    case @type
    when 'cuny' then @html.css('div.wpb_column.vc_column_container.vc_col-sm-4 div.wpb_wrapper p')
    when 'suny' then @html.css('div.content div a.campusName')
    end
  end

  def school_count
    @list_of_scraped_schools.count
  end

  def show_loading(message)
    print "\n#{message}"
    3.times do |_|
      print '.'
      sleep(1)
    end
    print "\n"
  end

  def read_file
  end

  def filter_schools
    show_loading 'Gathering school information'
    @progress_bar = ProgressBar.create(format: '%a %bᗧ%i %p%% %t', progress_mark: ' ', remainder_mark: '･', total: school_count)
    scrape_schools
    @schools
  end

  def scrape_schools
    case @type
    when 'cuny' then scrape_cuny
    when 'suny' then scrape_suny
    else raise StandardError.new('Woah! Error scraping schools')
    end
  end

  def scrape_cuny
    cuny_school_file = File.open('lib/parsed_data/cuny_school_info.json', 'w+')
    @list_of_scraped_schools.each_with_index do |paragraph, index|
      # paragraph => "Baruch College\nOne Bernard Baruch Way\nNew York, NY 10010-5585"
      info = paragraph.text.split(/\n/)
      cuny_school = School.new(info.shift)
      link = paragraph.css('a')
      url = link.attribute('href').value
      @school_hash[cuny_school.name] = {}
      # Note (Edge-case): There is a special case where the cuny school of public health site: "http://www2.cuny.edu/about/colleges-schools/cuny-school-of-public-health/"
      # simply redirects you to the original site http://sph.cuny.edu/. Due to this, we will have to scrape the actual school page.
      # Which is why we are checking for the url: %r{http://sph.cuny.edu/}
      new_site = Nokogiri::HTML(open(url))
      # binding.pry if index == 22
      if url =~ /http:\/\/sph.cuny.edu\/ | cuny-school-of-public-health/ix
        cuny_school.address = new_site.at_css('footer li:nth-child(1)')
        cuny_school.phone_number = new_site.at_css('footer li:nth-child(2)')
        cuny_school.website = url
        cuny_school.campusview = 'https://www.google.com/maps/place/CUNY+School+of+Public+Health/@40.8074856,-73.9463553,17z/data=!3m1!4b1!4m5!3m4!1s0x89c2f608f665c73d:0x6f8434f027cbce57!8m2!3d40.8074856!4d-73.9441666?hl=en'
      else
        cuny_school.address = info.join ' '
        cuny_school.phone_number = new_site.css('.vc_col-sm-8 .vc_align_left+ .box-white p').text.scan(/Phone: (.+\b)/).join
        cuny_school.website = new_site.at_css('div.wpb_wrapper a:nth-child(3)').attribute('href').value
        cuny_school.campusview = new_site.at_css('div.wpb_wrapper p a').attribute('href').value
      end
      add_school(cuny_school)
      @progress_bar.increment
    end
    show_loading 'Creating cuny file'
    File.open(cuny_school_file, 'w+') { |f| f.write(JSON.generate(@school_hash)) }
  end

  def scrape_suny
    suny_school_file = File.open('lib/parsed_data/suny_school_info.json', 'w+')
    @list_of_scraped_schools.each do |link|
      suny_school = School.new(link.text)
      url = link.attribute('href').value
      new_site = Nokogiri::HTML(open("#{SchoolConstants::SUNY_BASE_URL}#{url}"))
      info = new_site.css('div.module.location.blue p').children.map(&:content).reject { |h| h == '' }
      suny_school.address = info.shift(2).join(' ')
      suny_school.phone_number = info.first
      suny_school.website = info.last
      suny_school.campusview = new_site.at_css('div.module.location.blue a').attribute('href').value
      add_school(suny_school)
      @progress_bar.increment
    end
    show_loading 'Creating suny file'
    File.open(suny_school_file, 'w+') { |f| f.write(JSON.generate(@school_hash)) }
  end

  def add_school(school)
    @school_hash[school.name][:website] = school.website || 'N/A'
    @school_hash[school.name][:campusview] = school.campusview || 'N/A'
    @school_hash[school.name][:phone_number] = school.phone_number || 'N/A'
    @school_hash[school.name][:address] = school.address || 'N/A'
    @schools << school
  end
end
