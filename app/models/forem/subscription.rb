module Forem
  class Subscription
    include Mongoid::Document
    include Mongoid::Timestamps

    belongs_to :topic, :class_name => 'Forem::Topic'
    belongs_to :subscriber, :class_name => Forem.user_class.to_s

    validates :subscriber_id, :presence => true

    attr_accessible :subscriber_id

    def send_notification(post_id)
      SubscriptionMailer.topic_reply(post_id, self.subscriber.id).deliver
    end
  end
end
