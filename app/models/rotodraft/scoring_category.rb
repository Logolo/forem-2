
class ScoringCategory
  include Mongoid::Document
  include Mongoid::Token

  # Fields
  field :name, :type => String
  field :operation, :type => String, :index => true  #offense or defense. Think it's a strange word? YOU try to think of a better taxonomy! See http://bit.ly/qKda2J
  field :point_range, :type => String  #range of selectable points by a user who is creating a custom draft. Stored as a string, we convert to/from an array further down
  field :default_value, :type => Float
  field :sport, :type => String, :index => true
  
  # References
#  belongs_to :scoring_requirement
  
  # Embeds

  # Validations
  validates :name, :presence => true
  validates :operation, :presence => true
  validates :point_range, :presence => true
  validates :default_value, :presence => true
  validates :sport, :presence => true, :sport => true     
  validates_uniqueness_of :name,  :scope => [:sport]

  # Functions
  def range=(*intervals)
    self.point_range = intervals.join(',')
  end

  def range
    self.point_range.split(',')
  end

  token :length => 4
end
