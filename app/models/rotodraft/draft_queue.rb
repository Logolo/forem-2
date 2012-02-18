class DraftQueue
  include ActiveModel::Validations
  include Mongoid::Document
  include Mongoid::Token

  token  :length => 5, :contains => :alphanumeric

  # Relations
  belongs_to :team,  autosave: true #
  belongs_to :draft,  autosave: true #  

  # Embeds
  embeds_many :draft_queue_entries

  # Nested Attributes
  accepts_nested_attributes_for :team, :draft
  
  index :team
  index :draft
  
  validates :team, :draft, :presence => true
  
  def set_player_ids(player_xml_ids)
    self.draft_queue_entries.delete_all
    player_xml_ids.each_with_index do |id, index|  
      self.draft_queue_entries << DraftQueueEntry.new(:player_xml_id => id, :queue_position => index + 1 )          
    end      
  end
  
  def add_player_id(player_xml_id)
    position = self.draft_queue_entries.max(:queue_position) || 0
    entry = DraftQueueEntry.new(:player_xml_id => player_xml_id, :queue_position => position += 1)
    self.draft_queue_entries << entry
  end
  
  def get_player_ids
    @ids = Array.new
    self.draft_queue_entries.order_by([:queue_position, :asc]).each { |p| @ids << p.player_xml_id }
    return @ids
  end
  
  def move_player_id(player_xml_id, position)
    # increment queue_position for items above target position that are not the player
    self.draft_queue_entries.where(:queue_position.gte => position).excludes(:player_xml_id => player_xml_id).each do |entry|
      entry.queue_position += 1
    end
    # set the position for the player
    self.draft_queue_entries.where(:player_xml_id => player_xml_id).all.first.queue_position = position
    self.save
    self.get_player_ids
  end
  
end
