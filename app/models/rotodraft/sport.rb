class Sport
  include Mongoid::Document
  
  # Fields
  field :name, type: String

  # References
  has_many :positions
  has_many :scoring_requirements
  has_many :position_requirements
  has_many :roster_requirements
  
  # Embeds
  embedded_in :scoring_systems
  embedded_in :scoring_categories
#  embedded_in :roster_requirements

  # Validations  
  validates_uniqueness_of :name
  validates :name, :presence => true  
  
  def self.sports
     ["Football", "Hockey", "Basketball"]
#    ["Football", "Basketball", "Baseball", "Ice Hockey", "NASCAR", "Golf"]
  end                 
end