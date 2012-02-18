class GroupMembership
  include Mongoid::Document

  embedded_in :group
  field :user_id, type: BSON::ObjectId

  def user
    @user ||= User.find(self.user_id)
  end

  def team_name
    user.team.name
  end

  def full_name
    user.full_name
  end

  def experience
    'TODO'
  end

  def group_rank
    'TODO'
  end

  def overall_rank
    'TODO'
  end

  def online_status
    'TODO'
  end

  def commissioner?
    self.user_id == self.group.commissioner_id
  end
end
