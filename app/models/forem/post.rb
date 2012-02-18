module Forem
  class Post
    include Mongoid::Document
    include Mongoid::Timestamps

    field :text

    belongs_to :topic, :class_name => 'Forem::Topic'
    belongs_to :user, :class_name => Forem.user_class.to_s
    belongs_to :reply_to, :class_name => "Forem::Post"
    has_many :replies, :class_name => "Forem::Post", :dependent => :nullify

    delegate :forum, :to => :topic

    scope :by_created_at, order_by([[:created_at, :asc]])

    validates :text, :presence => true
  	after_create :subscribe_replier
  	after_create :email_topic_subscribers

    def owner_or_admin?(other_user)
      self.user == other_user || other_user.forem_admin?
    end

    def subscribe_replier
      if self.topic && self.user
        self.topic.subscribe_user(self.user.id)
      end
    end

  	def email_topic_subscribers
  		if self.topic
  			self.topic.subscriptions.includes(:subscriber).each do |subscription|
  				if subscription.subscriber != self.user
  					subscription.send_notification(self.id)
  				end
  			end
  		end
  	end
  end
end
