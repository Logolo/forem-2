module Forem
  class Post
    include Mongoid::Document
    include Mongoid::Timestamps
    include Workflow
    include Forem::Concerns::Viewable

    field :state
    field :text
    field :notified, :type => Boolean

    workflow_column :state
    workflow do
      state :pending_review do
        event :spam,    :transitions_to => :spam
        event :approve, :transitions_to => :approved
      end
      state :approved do
        event :hide, :transitions_to => :hidden
      end
      state :hidden do
        event :hide, :transitions_to => :hidden
        event :approve, :transitions_to => :approved
      end
      state :spam
    end

    # Used in the moderation tools partial
    attr_accessor :moderation_option

    attr_accessible :text, :reply_to_id

    belongs_to :topic, :class_name => 'Forem::Topic'
    belongs_to :user,     :class_name => Forem.user_class.to_s
    belongs_to :reply_to, :class_name => "Forem::Post"

    has_many :replies, :class_name  => "Forem::Post",
                       :foreign_key => "reply_to_id",
                       :dependent   => :nullify

    validates :text, :presence => true

    delegate :forum, :to => :topic

    after_save :subscribe_replier, :if => Proc.new { |p| p.user && p.user.forem_auto_subscribe? }
    after_save :approve_user,   :if => :approved?
    after_save :blacklist_user, :if => :spam?
    before_save :set_topic_last_post_at

    class << self
      def approved
        where(:state => 'approved')
      end

      def approved_or_pending_review_for(user)
        if user
          Post.all_of("$or" => [{:state => :approved}, {"$and" => [{:state => :pending_review}, {:user_id => user.id}]}])
        else
          approved
        end
      end

      def by_created_at
        order_by([:created_at, :asc])
      end

      def by_updated_at
        order_by([:updated_at, :desc])
      end

      def pending_review
        where(:state => 'pending_review')
      end

      def spam
        where(:state => 'spam')
      end

      def visible
        joins(:topic).where Topic.arel_table[:hidden].eq(false)
      end

      def topic_not_pending_review
        joins(:topic).where Topic.arel_table[:state].eq('approved')
      end

      def moderate!(posts, action)
        posts.each do |post_id, moderation|
          # We use find_by_id here just in case a post has been deleted.
          post = Post.where(:_id => post_id).first
          puts post_id
          if post && moderation["post"] == "1"
              post.send("#{action}!")
          end
        end
      end
    end

    def owner_or_admin?(other_user)
      self.user == other_user || other_user.forem_admin?
    end

    def approved?
      state == 'approved'
    end

    def skip_pending_review_if_user_approved
      self.update_attribute(:state, 'approved') if user && user.forem_state == 'approved'
    end

    protected

    def subscribe_replier
      if self.topic && self.user
        self.topic.subscribe_user(self.user.id)
      end
    end

    def subscribe_replier
      topic.subscribe_user(user.id)
    end

    def set_topic_last_post_at
      self.topic.update_attribute(:last_post_at, self.created_at)
    end

    def approve_user
      user.update_attribute(:forem_state, "approved") if user && user.forem_state != "approved"
    end

    def blacklist_user
      user.update_attribute(:forem_state, "spam") if user
    end

    def delete!
      delete
    end
  end
end
