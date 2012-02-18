
class DraftStyle
  include Mongoid::Document
  include Mongoid::Token

  field :is_live, type: Boolean
  field :name, type: String

  # References
  has_many :drafts

  # Embeds
  
  # Validations
  validates_uniqueness_of :name
  validates :name, :presence => true, :draft_style => true       
  validates_inclusion_of :is_live, :in => [true, false]     
  
  token :length => 3   
  
  def self.styles
    ["Standard", "Tag Team", "Custom", "Tournament", "Salary Cap", "Survivor", "No Cap", "Busted", "Mock"]
  end    
end

