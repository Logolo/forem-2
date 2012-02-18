class CustomizationType
  include Mongoid::Document
  include Mongoid::Token
  
  def self.customization_types
    ['Standard', 'Custom']
  end

  token :length => 3, :contains => :alphanumeric

  field :name, :type => String
  embedded_in :scoring_system
  embedded_in :roster_requirement

  validates :name, :presence => true
  validates_inclusion_of :name, in: self.customization_types

end

