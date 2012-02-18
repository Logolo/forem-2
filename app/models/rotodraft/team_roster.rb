class TeamRoster
  include Mongoid::Document
  include Mongoid::Timestamps

  # References
  belongs_to :draft
  belongs_to :team
  
  embeds_many :draft_picks

  validates :draft, :presence => true, :allow_nil => false
  validates :team, :presence => true, :allow_nil => false
  validates_associated :draft, :team
  
  accepts_nested_attributes_for :draft_picks
  
  def players
    self.draft_picks.order_by([:round, :asc]).map {|dp| dp.player}
  end
  
  def add_player(player, round = self.draft.current_round)
    if (self.draft_picks.nil? || self.draft_picks.size < self.draft.roster_requirement.total_players_required.to_i) then
      pick = DraftPick.new({:round => round, :player_id => player.id})
      self.draft_picks << pick
      self.save!
    else
      errors[:players] << "Trying to add " + (self.draft_picks.size.to_i + 1).to_s + " players to roster with cap of " + self.draft.roster_requirement.total_players_required.to_s + "."
      return false
    end
  end
  
  def get_player_ids
    @ids = Array.new
    self.players.each { |p| @ids << p.player_id }
    return @ids
  end
  
  def has_how_many(position)
    position = Position.get_position(position, draft.sport)
    return draft_picks.inject(0) {|result, draft_pick| draft_pick.player_position.id == position.id ? result += 1 : result } unless position.nil?
    return 0
  end
    
  def needs_how_many(position)
    draft.needs_how_many(position)    
  end  
    
  def needs_more?(position)
    has_how_many(position) < needs_how_many(position) 
  end

  def has_enough?(position)
    has_how_many(position) >= needs_how_many(position) 
  end
  
  def positions_filled
    result = []
    position_requirements = draft.roster_requirement.position_requirements
    position_requirements.map do |requirement| 
      if has_how_many(requirement.position) == needs_how_many(requirement.position)
        result << requirement.position.abbrev unless result.include? requirement.position.abbrev
      end
    end
    result
  end

  def positions_unfilled
    result = []
    position_requirements = draft.roster_requirement.position_requirements
    position_requirements.map do |requirement| 
      if has_how_many(requirement.position) < needs_how_many(requirement.position)
        result << requirement.position.abbrev unless result.include? requirement.position.abbrev
      end
    end
    result
  end
  
  def compare_roster
    position_requirements = draft.roster_requirement.position_requirements
    roster =  position_requirements.inject(Hash.new) do |result, requirement| 
                result[requirement.position.abbrev] = { :has => has_how_many(requirement.position), 
                                                              :needs => needs_how_many(requirement.position) } 
                result
              end
    roster =  draft_picks.inject(roster) do |result, draft_pick| 
                result[draft_pick.player_position.abbrev] = { :has => has_how_many(draft_pick.player_position), 
                                                              :needs => needs_how_many(draft_pick.player_position) } 
                result
              end                
  end

end
