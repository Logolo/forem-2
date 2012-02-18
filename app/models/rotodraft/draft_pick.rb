class DraftPick
  include Mongoid::Document
  include Mongoid::Timestamps

  # References
  embedded_in :team_roster
  
  field :round, type: Integer
  field :player_id, type: BSON::ObjectId

  # Indices
  index :player_id
  
  validates :player, :presence => true, :allow_nil => false
  validates :round, :presence => true, :allow_nil => false

  validates_numericality_of :round, greater_than: 0

  def player
    Player.find(self.player_id)
  end  
  
  def player= (player)
    self.player_id = player
  end

  def player_position
    player.position
  end
end