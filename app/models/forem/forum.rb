module Forem
  class Forum
    include Mongoid::Document
    include Forem::Concerns::Viewable

    field :title
    field :description
    belongs_to :category, :class_name => 'Forem::Category'
    has_many :topics, :class_name => 'Forem::Topic'
    #has_many :posts, :through => :topics, :dependent => :destroy
    #has_many :moderators, :through => :moderator_groups, :source => :group
    has_many :moderator_groups

    validates :category_id, :presence => true
    validates :title, :presence => true
    validates :description, :presence => true

    attr_accessible :category_id, :title, :description, :moderator_ids

    def count_of_posts
      topics.inject(0) {|sum, topic| topic.posts.count + sum }
    end

    def last_post_for(forem_user)
      return last_visible_post if self.topics.order_by([['posts.created_at', :desc]]).first == nil
      last_post = self.topics.order_by([['posts.created_at', :desc]]).first.posts.first
      forem_user && forem_user.forem_admin? ? last_post : last_visible_post
    end

    def last_visible_post
      visible_topics = self.topics.where(:hidden => false)
      visible_posts = Post.where(:topic_id.in => visible_topics.map(&:id))
      visible_posts.order_by([[:created_at, :desc]]).first
    end

    def moderator?(user)
      user.forem_admin?
      # user && (user.forem_group_ids & self.moderator_ids).any?
    end
  end
end
