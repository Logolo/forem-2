

class Team
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Token

  token  :length => 5, :contains => :alphanumeric
  
  field :name, :type => String, :index => true
  field :status, :type => String
  field :star_rank, :type => Integer
  field :site_points, :type => Integer
  field :is_active, :type => Boolean
  field :draft_messages, :type => Array, :default => []

  # Relations
  belongs_to :user  
  has_and_belongs_to_many :drafts
  belongs_to :team_reference, :polymorphic => true
  belongs_to :team_room_reference, :polymorphic => true
  belongs_to :team_ready_reference, :polymorphic => true
  belongs_to :team_autodraft_reference, :polymorphic => true
  has_many :team_rosters
  has_many :draft_queues
  
  validates :name, :presence => true, :uniqueness => true

  class Team::AvatarUploader < CarrierWave::Uploader::Base
    include CarrierWave::RMagick
    storage :grid_fs

    def extension_white_list
      %w(jpg jpeg gif png)
    end
    
    def store_dir
      "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end
  
    process :resize_to_fit => [50, 50]
    
    version :thumb do
        process :resize_to_fill => [30,30]
    end      
  end

  mount_uploader :avatar, AvatarUploader

  def roster_for_draft(draft)
    team_roster = team_rosters.where(:draft_id => draft.id).first
    if team_roster.nil?
      team_roster = TeamRoster.create({:team => self, :draft => draft})
      team_rosters << team_roster
    end
    team_roster
  end

end

  