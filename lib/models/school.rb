class School
  attr_reader :name
  attr_accessor :address, :campusview, :website, :phone_number
  def initialize(name)
    @name = name
  end
end
