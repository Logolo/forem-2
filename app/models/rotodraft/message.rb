class Message
  include Mongoid::Document

  after_create :send_email

  field :to_user_id, type: BSON::ObjectId
  field :from_user_id, type: BSON::ObjectId
  field :body

  validates :to_user_id, presence: true
  validates :from_user_id, presence: true
  validates :body, presence: true

  def from
    User.find(self.from_user_id)
  end

  private

  def send_email
    UserMailer.new_message_email(self).deliver
  end
end
