class PlayerUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors[attribute] << "value #{value} is not unique" unless is_unique_within_draft_queue(record, attribute, value)
  end

  def is_unique_within_draft_queue(draft_queue_entry, attribute, value)
    draft_queue_entry.draft_queue.draft_queue_entries.each do |sibling|
      return false if sibling != draft_queue_entry && draft_queue_entry.player_xml_id == sibling.player_xml_id
    end
    true
  end
end


class DraftQueueEntry
  include Mongoid::Document
  include ActiveModel::Validations
  include Mongoid::Token

  # Fields
  field :queue_position, :type => Integer
  field :player_xml_id, :type => String # THe ID from the data source, not the Mongoid ID

  embedded_in :draft_queue
  
  # Validations
  validates :queue_position, :presence => true
  validates :player_xml_id, :presence => true, :player_uniqueness => true
  validates_uniqueness_of :queue_position
  validates_numericality_of :queue_position, :greater_than => 0    
end
