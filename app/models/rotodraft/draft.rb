

require 'active_model' # When the model is used inside Goliath, these explicit requires are needed.
require 'active_support/core_ext/hash'  # When the model is used inside Goliath, these explicit requires are needed.
require 'validates_timeliness'  # When the model is used inside Goliath, these explicit requires are needed.


TEAM_ORDER_DEFINED_NOTIFICATION_TIME_IN_MINUTES = 3
WHEN_FULL_DRAFT_STARTUP_TIME_IN_MINUTES = 2
PRE_DRAFT_NOTIFICATION_TIME_IN_MINUTES = 1
SECONDS_TEAM_HAS_TO_PICK = 60
DRAFT_POLLING_CYCLE = 5
IFS_FEE_PERCENTAGE = 0.1

DRAFT_STATES = ["CREATED", "FULL", "SCHEDULED", "TEAM_ORDER_DEFINED", "PRE_DRAFT", "HAS_STARTED", "FINISHED", "DRAFT_CANCELLED"]

class Draft
  include ActiveModel::Validations
  include Mongoid::Document
  include Mongoid::Token
  include Mongoid::Timestamps

  token  :length => 5, :contains => :alphanumeric

  field  :draft_size, :type =>  Integer, :default => 4 # {2..12}
  field  :draft_start_datetime, :type =>  DateTime
  field  :is_private, :type =>  Boolean
  field  :draft_password, :type => String
  field  :has_started_flag, :type =>  Boolean, :default => false
  field  :current_round, :type =>  Integer, :default => 0
  field  :seconds_for_pick, :type =>  Integer
  field  :draft_state, :type => String # CREATED, FULL, SCHEDULED, TEAM_ORDER_DEFINED, PRE_DRAFT, HAS_STARTED, FINISHED :type =>  DRAFT_CANCELLED
  field  :sport, :type => String

  # Embeds
  embeds_one :draft_start_type # {'when full', 'scheduled'}
  embeds_one :prize
  embeds_one :roster_requirement
  embeds_one :scoring_system

  # Relations
  belongs_to :fee, autosave: true #
  belongs_to :draft_style, autosave: true #
  belongs_to :creator, class_name: "User"
  has_and_belongs_to_many :teams
  has_one :now_picking,  class_name: "Team", as: :team_reference  #TODO refactor to be only the ID and add getter/setter methods
  has_many :teams_in_room, class_name: "Team", as: :team_room_reference #TODO refactor to be only the ID and add getter/setter methods
  has_many :teams_ready, class_name: "Team", as: :team_ready_reference #TODO refactor to be only the ID and add getter/setter methods
  has_many :teams_autodrafting , class_name: "Team", as: :team_autodraft_reference #TODO refactor to be only the ID and add getter/setter methods
  has_many :team_rosters
  has_many :draft_queues

  # Nested Attributes
  accepts_nested_attributes_for :draft_style, :draft_start_type, :fee, :prize, :roster_requirement, :scoring_system, :now_picking, :teams, :teams_ready, :team_rosters, :teams_autodrafting

  # Indices
  index :draft_start_datetime
  index :draft_state
  index :has_started_flag

  # Validations
  validates :sport, :presence => true
  validates :draft_style, :presence => true
  validates :draft_start_type, :presence => true
  validates :fee, :presence => true
  validates :prize, :presence => true
  validates :roster_requirement, :presence => true
  validates :scoring_system, :presence => true
  validates_associated :now_picking, :teams, :teams_ready

  validates :sport, :presence => true, :sport => true

  validates_datetime :draft_start_datetime, :allow_blank => true
  validates :draft_start_datetime, :presence =>true, :if => Proc.new {|a| a.draft_start_type.name == "Scheduled"}

  validates_inclusion_of :has_started_flag, :in => [true, false]

  validates :now_picking, :team_in_draft => true, :unless => 'now_picking.nil?'

  validates_numericality_of :current_round, less_than_or_equal_to: Proc.new { |draft| draft.number_of_rounds }

  before_save :log_change
  
  def log_change
    raise "Now picking is nil but draft has started." if (now_picking.nil? && draft_state == "HAS_STARTED")
  end

  after_validation :handle_post_validation

  def number_of_rounds
    self.roster_requirement.total_players_required
  end

  def handle_post_validation
    if not self.errors[:roster_requirement].nil?
      self.roster_requirement.errors.each{ |attr,msg| self.errors.add(attr, " in Roster Requirement " + msg)}
    self.roster_requirement.errors.clear
    end
    if not self.errors[:scoring_system].nil?
      self.scoring_system.errors.each{ |attr,msg| self.errors.add(attr, " in Scoring System " + msg)}
      self.scoring_system.scoring_requirements.each do |requirement|
        requirement.errors.each{ |attr,msg| self.errors.add(attr, " in Scoring System Scoring Requirements #{requirement.points_awarded}" + msg)}
      end
    self.scoring_system.errors.clear
    end
    if not self.errors[:prize].nil?
      self.prize.errors.each{ |attr,msg| self.errors.add(attr, " in Prize " + msg)}
      self.prize.prize_distributions.each do |distribution|
        distribution.errors.each{ |attr,msg| self.errors.add(attr, " in Prize Prize Distribution #{distribution.place}" + msg)}
      end
    self.prize.errors.clear
    end
  end

  def find_team(team_name)
    teams.where("team.name" == team_name).all
  end

  def set_pick_order
    #randomize order of teams in list
    #teams.replace(teams.all.shuffle)
    self.draft_state = "TEAM_ORDER_DEFINED"
    self.save
  end

  def prepare_for_pre_draft
    self.draft_state = "READY_FOR_PRE_DRAFT"
    self.save
  end

  def start_pre_draft
    self.draft_state = "PRE_DRAFT"
    self.save
  end

  def start_draft
    self.draft_state = "HAS_STARTED"
    self.has_started_flag = true
    self.current_round = 1
    self.now_picking = self.teams.first
    self.seconds_for_pick = SECONDS_TEAM_HAS_TO_PICK
    self.save
  end

  def cancel_draft
    self.draft_state = "DRAFT_CANCELLED"
    self.has_started_flag = false
    self.current_round = 0
    self.now_picking = nil
    self.seconds_for_pick = 0
    self.save
  #TODO should we delete?
  end

  def has_started?
    return true if ["HAS_STARTED"].include?(self.draft_state)    
  end
    
  def has_finished?
    return true if ["FINISHED"].include?(self.draft_state)
  end

  def schedule_when_full_draft
    self.draft_start_datetime = Time.now + WHEN_FULL_DRAFT_STARTUP_TIME_IN_MINUTES*60  #values in seconds
    self.draft_state = "SCHEDULED"
    self.save
  #TODO send out notifications to all teams
  end

  def add_team(team)
    #TODO figure out if Ruby has a better way of sending messages out of a function
    #TODO this may also be a sign of a Greedy Method. Refactor?
    action_performed = "none"
    if teams.count < draft_size.to_i && !team_in_draft?(team) then
      team.drafts << self
      teams << team
      #if this is the last team
      action_performed = "added"
      if teams.count == draft_size then
        #put teams in random draft order
        #TODO repair this randomization thing

        self.set_pick_order
        action_performed = "ordered"
        if draft_start_type.name = "When Full" then
          # this seems like a good place to schedule a When Full draft
          self.schedule_when_full_draft
          action_performed = "scheduled"
        end

        #update draft state
        self.draft_state = "FULL"
        self.save

      end
    elsif team_in_draft?(team) then
      #TODO would be nice to find a proper way to return an error message rather than just null
      action_performed = "error"
      errors.add(:join, "Team #{team.name} is already in Draft ID #{self.token}.")      
      return false
    else
      #TODO would be nice to find a proper way to return an error message rather than just null
      action_performed = "error"
      errors.add(:join, "Draft ID #{self.token} is full.")
      return false
    end
    return true
  end

  def toggle_autodraft(team)
    if self.teams_autodrafting.include? team
      self.teams_autodrafting.delete(team)
    else
      self.teams_autodrafting.push(team)
    end
    self.save!
    is_on_autodraft? team
  end

  def is_on_autodraft?(team)
    self.teams_autodrafting.include? team
  end

  def add_team_to_room(team)
    if team_in_draft?(team) then
      if !team_in_room?(team) then
        teams_in_room << team
        self.save
      else
        errors.add(:enter, "Team #{team.name} is already in Draft Room ID #{self.token}.")      
        return false
      end 
    else
      errors.add(:enter, "Team #{team.name} has not joined draft ID #{self.token} and cannot enter its draft room.")      
      return false
    end
    return true
  end

  def queue_next_team
    #TODO this code is hard to follow. Consider some more rubyesque refactoring
    now_picking_index = teams.all.find_index(now_picking)
    
    raise "Now Picking Index nil when now_picking is #{now_picking}" if now_picking_index.nil?

    if now_picking_index == 0 then                         # left end of the serpentine
      if self.current_round % 2 == 1 then                   
        # odd round, return next player to the right
        raise "1 - Now picking will be nil if using index #{now_picking_index + 1}" if teams.all[now_picking_index + 1].nil?
        self.now_picking = teams.all[now_picking_index+=1]
      else                                                  
        if self.current_round == self.roster_requirement.total_players_required
          # the draft is over. 
          self.now_picking = nil
          self.draft_state = "FINISHED"
        else          
          # even round, keep same player and increment round
          raise "2 - Now picking will be nil if using index #{now_picking_index}" if teams.all[now_picking_index].nil?
          self.current_round += 1
        end 
      end
    elsif now_picking_index < draft_size - 1 then         # midpoint of the serpentine
      if self.current_round % 2 == 1 then                   
        # odd round, return next player to the right
        raise "3 - Now picking will be nil if using index #{now_picking_index + 1}" if teams.all[now_picking_index + 1].nil?
        self.now_picking = teams.all[now_picking_index+=1]
        puts "3 Now picking is " + self.now_picking.name
      else                                                  
        # even round, return previous player to the left
        raise "4 - Now picking will be nil if using index #{now_picking_index - 1}" if teams.all[now_picking_index - 1].nil?
        self.now_picking = teams.all[now_picking_index-=1]
        puts "4 Now picking is " + self.now_picking.name
      end
    elsif now_picking_index == draft_size - 1 then        # right end of the serpentine
      if self.current_round % 2 == 1 then                   
        if self.current_round == self.roster_requirement.total_players_required
          # the draft is over. 
          self.now_picking = nil
          self.draft_state = "FINISHED"
        else
          # odd round, keep current player and increment round
          raise "5 - Now picking will be nil if using index #{now_picking_index}" if teams.all[now_picking_index].nil?
          self.current_round += 1
          puts "5B Now picking is " + self.now_picking.name
        end
      else                                                  
        # even round, return previous player to the left
        raise "6 - Now picking will be nil if using index #{now_picking_index - 1}" if teams.all[now_picking_index - 1].nil?
        self.now_picking = teams.all[now_picking_index-=1]
        puts "6 Now picking is " + self.now_picking.name
    end
    else
      return nil
    end
    self.save!
    if self.draft_state != "FINISHED"
      raise "Now_picking #{self.now_picking.name} is not valid" if !now_picking.valid?
    end
    return self.now_picking
  end

  def is_full?
    teams.count == draft_size
  end

  def team_in_draft?(team)
    !teams.find_by_token(team.token).nil?
  end

  def team_in_room?(team)
    !teams_in_room.find_by_token(team.token).nil?
  end

  def get_picked_player_ids
    @players_picked = Array.new
    team_rosters.each {|tr| @players_picked.concat tr.get_player_ids }
    @players_picked
  end

  def get_history
    #returns the following stucture
    # history[] {:team => "name", :picks => [{:player_picked => "Player", :player_position => position, :position_abbrev => abbrev}, {:player_picked => "Player", :player_position => position, :position_abbrev => abbrev}} with array order = round

    history = Array.new
    if self.has_started_flag
      draft_id = self.id
      teams.each do |team|
        unless team.roster_for_draft(self).draft_picks.count == 0
          draft_picks = team.roster_for_draft(self).draft_picks.order_by([:round, :asc])
          players = Array.new
          players = draft_picks.map do |pick|
            {
              :player_id => pick.player.player_id,
              :player_first_name => pick.player.first_name,
              :player_last_name => pick.player.last_name,
              #              :player_team_name => player.league_team.pro_team_name,
              :player_team_abbrev => pick.player.league_team.pro_team_abbrev.upcase,
              :player_position_name => pick.player.position.name,
              :player_position_abbrev => pick.player.position.abbrev
            }
          end
        end
        history << {
          :team_id => team.token,
          :team_name => team.name,
          :team_avatar => team.avatar.url,
          :autodraft => self.is_on_autodraft?(team),
          :picks => players,
          :roster_state => team.roster_for_draft(self).compare_roster
        }
      end
    end
    return history
  end

  # Returns two types of drafts:
  # - those that will enter "pre-draft" mode in the next interval
  # - those that will enter "draft" mode in the next interval
  # The type of draft is returned with an action identifier, BEGIN_DPRE_RAFT or BEGIN_DRAFT as appropriate
  def self.get_drafts_for_next_interval(interval)
    drafts = Array.new
    unstarted_drafts = Draft.where(:has_started_flag => false)
    # We use this to provide some time between updating a record and it being available for external processes.
    # This addresses the lag between sending an HTTP request that results in a schedule_when_full_draft and a subsequent
    # draftlistener request inside Goliath (1 or 2 seconds )
    update_to_listener_wait_time = Time.now - 10
    unstarted_drafts.each do |draft|
      unless draft.draft_start_datetime.nil?
        if ( draft.draft_start_datetime < (Time.now + TEAM_ORDER_DEFINED_NOTIFICATION_TIME_IN_MINUTES*60 + interval) && draft.updated_at < update_to_listener_wait_time && draft.draft_state == "FULL") then
          drafts << {:action => 'TEAM_ORDER_DEFINED', :draft => draft}
        elsif (draft.draft_start_datetime < (Time.now + PRE_DRAFT_NOTIFICATION_TIME_IN_MINUTES*60 + interval) && draft.draft_state == "READY_FOR_PRE_DRAFT") then
          drafts << {:action => 'BEGIN_PRE_DRAFT', :draft => draft}
        elsif (draft.draft_start_datetime < (Time.now + interval) && draft.draft_state == "PRE_DRAFT") then
          drafts << {:action => 'BEGIN_DRAFT', :draft => draft}
        elsif (draft.draft_start_datetime < (Time.now) && draft.draft_start_type.name == "Scheduled" && !["HAS_STARTED", "DRAFT_CANCELLED"].include?(draft.draft_state) ) then
          drafts << {:action => 'DRAFT_CANCELLED', :draft => draft}
        end
      end
    end
    return drafts
  end

  # Get the maximum number of available payouts based on the draft size.
  def get_maximum_payouts 
    # [[2,1],[5,2],[9,3],[13,4],[20,5],[30,6],[40,7],[50,8],[60,9],[70,10]]
    Draft.calculate_maximum_payouts self.draft_size 
  end
  
  # Get payout schedule for specified number of payouts based on the draft fee and draft size
  def get_payout_schedule(payouts = 1)
    Draft.calculate_payout_schedule(self.fee.entry_fee, self.draft_size, payouts)
  end

  def self.calculate_payout_schedule(fee, size, payouts)
    # You may ask why these values are hardcoded and not stored in a database
    # The answer: These values should be very difficult to change. 
    
    prize_pool = (fee - fee*IFS_FEE_PERCENTAGE).to_i * size
    case payouts
    when 1
      {:payouts => 1,  :amounts => [ (prize_pool * 1).to_i ]}
    when 2
      {:payouts => 2,  :amounts => [ (prize_pool * 0.8).to_i, ((prize_pool) * 0.2).to_i ]}
    when 3
      {:payouts => 3,  :amounts => [ ((prize_pool - fee) * 0.7).to_i, ((prize_pool - fee) * 0.3).to_i, fee ]}
    when 4
      {:payouts => 4,  :amounts => [ ((prize_pool - fee) * 0.7).to_i, ((prize_pool - fee) * 0.2).to_i, ((prize_pool - fee) * 0.1).to_i, fee ]}
    when 5
      {:payouts => 5,  :amounts => [ ((prize_pool - fee) * 0.65).to_i, ((prize_pool - fee) * 0.2).to_i, ((prize_pool - fee) * 0.1).to_i, ((prize_pool - fee) * 0.05).to_i, fee ]}
    when 6
      {:payouts => 6,  :amounts => [ ((prize_pool - fee*2) * 0.65).to_i, ((prize_pool - fee*2) * 0.2).to_i, ((prize_pool - fee*2) * 0.1).to_i, ((prize_pool - fee*2) * 0.05).to_i, fee, fee ]}
    when 7
      {:payouts => 7,  :amounts => [ ((prize_pool - fee*3) * 0.65).to_i, ((prize_pool - fee*3) * 0.2).to_i, ((prize_pool - fee*3) * 0.1).to_i, ((prize_pool - fee*3) * 0.05).to_i, fee, fee, fee ]}
    when 8
     {:payouts => 8,  :amounts => [ ((prize_pool - fee*4) * 0.65).to_i, ((prize_pool - fee*4) * 0.2).to_i, ((prize_pool - fee*4) * 0.1).to_i, ((prize_pool - fee*4) * 0.05).to_i, fee, fee, fee, fee ]}
    when 9
     {:payouts => 9,  :amounts => [ ((prize_pool - fee*5) * 0.65).to_i, ((prize_pool - fee*5) * 0.2).to_i, ((prize_pool - fee*5) * 0.1).to_i, ((prize_pool - fee*5) * 0.05).to_i, fee, fee, fee, fee, fee ]}
    when 10
     {:payouts => 10, :amounts => [ ((prize_pool - fee*6) * 0.65).to_i, ((prize_pool - fee*6) * 0.2).to_i, ((prize_pool - fee*6) * 0.1).to_i, ((prize_pool - fee*6) * 0.05).to_i, fee, fee, fee, fee, fee, fee ]}
    end
  end
  
  
  def self.calculate_maximum_payouts(size) 
    # [[2,1],[5,2],[9,3],[13,4],[20,5],[30,6],[40,7],[50,8],[60,9],[70,10]]
    case size
    when 2..4
      1
    when 5..8
      2
    when 9..12
      3
    when 13..19
      4
    when 20..29
      5
    when 30..39
      6
    when 40..49
      7
    when 50..59
      8
    when 60..69
      9
    when 70..200
      10
    end    
  end

  def needs_how_many(position)
    count = 0
    if position = Position.get_position(position, sport)
      if roster_requirement.position_requirements.where("position_id" => position.id).count > 0
        count = roster_requirement.position_requirements.where("position_id" => position.id).first.number_required        
      end
    end
    
    count
  end  

end
