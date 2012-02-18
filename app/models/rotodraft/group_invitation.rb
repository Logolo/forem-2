class GroupInvitation
  include Mongoid::Document

  field :group_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :from_user_id, type: BSON::ObjectId
  field :status, default: 'pending' # pending, accepted

  validates :group_id, presence: true
  validates :user_id, presence: true
  validates :from_user_id, presence: true
  validates :status, presence: true

  def user
    @user ||= User.find(self.user_id)
  end

  def sender
    @sender ||= User.find(self.from_user_id)
  end

  def group
    @group ||= Group.find(self.group_id)
  end

  def accept!
    self.update_attributes!(status: 'accepted')
  end
end
