module Forem
  class Subscription
    include Mongoid::Document
    include Mongoid::Timestamps

    embedded_in :topic, :class_name => 'Forem::Topic'
    belongs_to :subscriber, :class_name => Forem.user_class.to_s
    validates_presence_of :subscriber_id

		def send_notification(post_id)
			SubscriptionMailer.topic_reply(post_id, self.subscriber.id).deliver
		end
  end
end
