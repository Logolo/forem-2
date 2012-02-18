class BlockedUser
  include Mongoid::Document

  embedded_in :privacy
  field :user_id, type: BSON::ObjectId
end
