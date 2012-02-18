class Position
  include Mongoid::Document
  include Mongoid::Token

  # Fields
  field :sport, :type => String, :index => true
  field :name, :type => String, :index => true
  field :abbrev, :type => String, :index => true
  field :default_requirement, :type => Integer
  field :is_flex, :type => Boolean, :default => false

  # Indices
  index(
    [
      [ :name, Mongo::ASCENDING ],
      [ :abbrev, Mongo::ASCENDING ],
      [ :sport, Mongo::ASCENDING ]
    ],
    unique: true
  )

#  validates :name, :abbrev, :sport, :presence => true
  validates :name, :abbrev, :sport, :presence => true
  validates_inclusion_of :sport, :in => Sport.sports

  validates_uniqueness_of :name, :abbrev, :scope => :sport

  token :length => 4

  def self.get_position(position, sport)
    if position.kind_of? String
      position = self.any_of({:abbrev => position}, {:name => position}).where(:sport => sport).first
    else
      position
    end
  end

end
