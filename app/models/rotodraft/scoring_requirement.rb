class ScoringRequirement
  include Mongoid::Document

  # Fields
  field :points_awarded, :type => Float
  field :sport, :type => String, :index => true
  
  # References
  referenced_in :scoring_category
  
  # Embeds
  embedded_in :scoring_system, :inverse_of => :scoring_requirements

  index :scoring_category
  
  # Validations
#  validates :scoring_category, :presence => true                   
  validates :points_awarded, :presence => true
  validates :sport, :presence => true, :sport => true     
  accepts_nested_attributes_for :scoring_category, :scoring_system
end
