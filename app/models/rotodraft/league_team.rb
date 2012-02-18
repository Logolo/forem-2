class LeagueTeam
  include Mongoid::Document
  field :pro_team_id, :type => String, :index => true
  field :pro_team_name, :type => String, :index => true
  field :pro_team_abbrev, :type => String, :index => true
  field :sport, :type => String
  
  has_many :players
  
  validates :pro_team_name, :pro_team_abbrev, :sport, :presence => true
end
