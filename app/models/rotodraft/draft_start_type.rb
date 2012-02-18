class DraftStartType
  include Mongoid::Document

  field :name, :type => String, :index => true
  embedded_in :draft

  validates :name, :presence => true, :draft_start_type => true
  validates_uniqueness_of :name
  
  def self.types
    ["When Full", "Scheduled"]
  end
end

