module Forem
  class Topic
    include Mongoid::Document
    include Mongoid::Timestamps

    attr_protected :pinned, :locked

    field :subject
    field :locked, type: Boolean, default: false
    field :pinned, type: Boolean, default: false
    field :hidden, type: Boolean, default: false
    belongs_to :forum, :class_name => 'Forem::Forum'
    belongs_to :user, :class_name => Forem.user_class.to_s
    embeds_many :views, :class_name => 'Forem::View'
    embeds_many :subscriptions, :class_name => 'Forem::Subscription'

    has_many :posts, :class_name => 'Forem::Post'
    accepts_nested_attributes_for :posts

    validates :subject, :presence => true

    before_save :set_first_post_user
    after_create :subscribe_poster

    scope :visible, where(:hidden => false)
    scope :by_pinned, order_by([[:pinned, :desc], [:id, :asc]])
    scope :by_most_recent_post, order_by([['posts.created_at', :desc]])
    scope :by_pinned_or_most_recent_post, order_by([[:pinned, :desc],['posts.created_at', :desc]])

    def to_s
      subject
    end

    # Cannot use method name lock! because it's reserved by AR::Base
    def lock_topic!
      update_attribute(:locked, true)
    end

    def unlock_topic!
      update_attribute(:locked, false)
    end

    # Provide convenience methods for pinning, unpinning a topic
    def pin!
      update_attribute(:pinned, true)
    end

    def unpin!
      update_attribute(:pinned, false)
    end

    # A Topic cannot be replied to if it's locked.
    def can_be_replied_to?
      !locked?
    end

    def view_for(user)
      views.where(user_id: user.id).first
    end

    # Track when users last viewed topics
    def register_view_by(user)
      if user
        view = views.find_or_create_by(user: user, topic: self)
#        view.increment!("count")
      end
    end
    
    def subscribe_poster
      subscribe_user(self.user_id)
    end

    def subscribe_user(user_id)
      if user_id && !subscriber?(user_id)         
				subscriptions.create!(:subscriber_id => user_id)
      end
    end

    def unsubscribe_user(user_id)
      subscriptions.where(:subscriber_id => user_id).destroy_all
    end

		def subscriber?(user_id)
			subscriptions.where(:subscriber_id => user_id).any?
		end

		def subscription_for user_id
			subscriptions.first(:conditions => { :subscriber_id=>user_id })
		end

    protected
    def set_first_post_user
      post = self.posts.first
      post.user = self.user
    end
  end
end
