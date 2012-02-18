
class RosterRequirement
  include Mongoid::Document

  # Fields
  field :name, :type => String
  field :favorite_name, :type => String
  field :sport, :type => String
  field :total_players_required, :type => Integer, :default => 0
  
  # References
  belongs_to :creator, class_name: "User"

  # Embeds
  embeds_one :customization_type
  embeds_many :position_requirements # PositionRequirement

  # Validations
  validates :sport, :presence => true, :sport => true     
  accepts_nested_attributes_for :customization_type, :position_requirements

=begin
  def validate
    assert_present(:name)
    assert_present(:favorite_name)
    assert_present(:type)
    assert_present(:creator)
    assert_present(:sport)
  end
=end

  def add(position_requirement)
    self.total_players_required += position_requirement.number_required
    self.position_requirements << position_requirement
  end

  def get_requirements_for(position)
    position = Position.any_of({:name => position}, {:abbrev => position}).first
    self.position_requirements.where(:position_id => position.id)
  end
  
  def positions_required
    self.position_requirements.map{|pr| {:abbrev => pr.position.abbrev, :name => pr.position.name} }
  end
  
  def abbrevs_of_positions_required
    self.positions_required.map{|pr| pr[:abbrev]}
  end

end
