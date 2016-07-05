require "open-uri"
require "json"
require "nokogiri"

class SchoolScraper
  attr_reader :html, :type

  def initialize(school_info = {})
    raise ArgumentError.new("You need to pass an url and a type to SchoolScraper #new") if school_info.empty?
    @type = school_info[:type]
    @html = Nokogiri::HTML(open(school_info[:url]))
  end

  def show_loading(message)
  end

  def read_file
  end

  def filter_schools
  end

  def add_school(school, school_hash)
  end
end
