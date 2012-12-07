module Forem
  class Topic
    include Mongoid::Document
    include Mongoid::Timestamps
    include Workflow
    include Forem::Concerns::Viewable
    include Forem::Concerns::Subscribable

    field :state

    workflow_column :state
    workflow do
      state :pending_review do
        event :spam,    :transitions_to => :spam
        event :approve, :transitions_to => :approved
      end
      state :spam
      state :approved
    end

    field :subject
    field :locked, type: Boolean, default: false
    field :pinned, type: Boolean, default: false
    field :hidden, type: Boolean, default: false
    belongs_to :forum, :class_name => 'Forem::Forum'
    belongs_to :user, :class_name => Forem.user_class.to_s
    has_many :posts, :class_name => "Forem::Post"

    attr_accessor :moderation_option
    attr_protected :pinned, :locked

    accepts_nested_attributes_for :posts

    validates :subject, :presence => true

    before_save  :set_first_post_user
    after_save   :approve_user_and_posts, :if => :approved?
    after_create :subscribe_creator
    after_create :skip_pending_review_if_user_approved

    class << self
      def visible
        where(:hidden => false)
      end

      def by_pinned
        order_by([:pinned, :desc])
      end

      def by_most_recent_post
        order_by([:last_post_at, :desc])
      end

      def by_pinned_or_most_recent_post
        order_by([:pinned, :desc], [:last_post_at, :desc])
      end

      def pending_review
        where(:state => 'pending_review')
      end

      def approved
        where(:state => 'approved')
      end

      def approved_or_pending_review_for(user)
        if user
          Topic.all_of("$or" => [{:state => :approved}, {"$and" => [{:state => :pending_review}, {:user_id => user.id}]}])
        else
          approved
        end
      end
    end

    def to_s
      subject
    end

    def toggle!(field)
      send "#{field}=", !self.send("#{field}?")
      save :validation => false
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

    def moderate!(option)
      send("#{option}!")
    end

    def can_be_replied_to?
      !locked? && !archived? && forum.replyable
    end

    def archived?
      self.last_post_at.to_i < 2.months.ago.to_i
    end

    protected
    def set_first_post_user
      post = self.posts.first
      post.user = self.user
    end

    def skip_pending_review_if_user_approved
      self.update_attribute(:state, 'approved') if user && user.forem_state == 'approved'
    end

    def approve_user_and_posts
      return unless state_changed?

      first_post = self.posts.first
      first_post.approve! unless first_post.approved?
      self.user.update_attribute(:forem_state, 'approved') if self.user.forem_state != 'approved'
    end
  end
end
