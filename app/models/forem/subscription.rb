module Forem
  class Subscription
    include Mongoid::Document
    include Mongoid::Timestamps

    field :unsubscribed, :type => Boolean, :default => false

    belongs_to :subscribable, :polymorphic => true, :index => true
    belongs_to :subscriber, :class_name => Forem.user_class.to_s, :index => true

    validates :subscriber_id, :presence => true
    validates :subscribable_id,   :presence => true
    validates :subscribable_type, :presence => true

    attr_accessible :subscriber_id

    def alert_subscriber(*args)
      alert = Forem::Alert.where(:subscription_id => self.id, :read => false).first
      case self.subscribable_type
      when "Forem::Topic"
        if alert == nil
          last_post = self.subscribable.posts.last
          return if last_post.user.id == self.subscriber_id
          Forem::Alert.create(:subscription_id => self.id, :user_id => self.subscriber_id, :forem_topic_post => last_post, :forem_topic_replier => last_post.user.username, :created_at => Time.now, :updated_at => Time.now)
        else
          alert.updated_at = Time.now
          alert.forem_topic_count += 1
          alert.save
        end
      else
        raise TypeError, 'This object is not subscribable!'
      end
    end
  end
end
