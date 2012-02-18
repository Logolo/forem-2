class PositionRequirement
  include Mongoid::Document

  # Fields  
  field :number_required, :type => Integer

  # References
  field :position_id, type: BSON::ObjectId

  # Embeds
  embedded_in :roster_requirement, :inverse_of => :position_requirements
  
  # Indices
  index :position_id
  
  validates :number_required, :presence => true
  accepts_nested_attributes_for :position, :roster_requirement
    
  def position
    Position.find(self.position_id)
  end  
  
  def position= (position)
    self.position_id = position
  end
    
end
