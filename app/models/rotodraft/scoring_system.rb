class ScoringSystem
  include Mongoid::Document
  
  # Fields
  field :name, :type => String, :index => true
  field :favorite_name, :type => String, :index => true
  field :sport, :type => String, :index => true
  
  # References
  belongs_to :creator, class_name: "User"

  # Embeds
  embeds_one :customization_type
  embeds_many :scoring_requirements  
  # embedded_in :draft

  accepts_nested_attributes_for :customization_type, :scoring_requirements
  
  # Validations
  validates :sport, :presence => true, :sport => true     
end