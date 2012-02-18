class BuddyRelationship
  include Mongoid::Document

  belongs_to :user
  field :buddy_id, type: BSON::ObjectId
  field :status # pending, requested, accepted

  def buddy
    @buddy ||= User.find(self.buddy_id)
  end
end
