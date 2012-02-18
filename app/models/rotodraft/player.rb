class Player
  include Mongoid::Document

  # Fields
  field :player_id, :type => String, :index => true
  field :first_name, :type => String, :index => true
  field :last_name, :type => String, :index => true
  field :player_salary, :type => Integer
  field :sport, :type => String

  field :player_tier, :type => Integer, :default => 999
  field :position_rank, :type => Integer, :default => 999
  field :overall_rank, :type => Integer, :default => 999

  # References
  belongs_to :league_team
#  belongs_to :team_roster
  belongs_to :draft_queue_entry
#  has_many :draft_picks
  
  # Embeds
  embeds_one :position

  validates :player_id, :league_team, :sport, :position, :presence => true
#  validates_uniqueness_of :overall_rank, :scope => :sport, :unless => nil
  
  validate :has_name
  
  def has_name
    if first_name.blank? && last_name.blank?
      false
    end
  end
  
  def full_name(last_name_first = true)
    return last_name + ", " + first_name if last_name_first
    return first_name + " " + last_name
  end

end
