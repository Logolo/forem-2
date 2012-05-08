module Forem
  class Forum
    include Mongoid::Document

    field :title
    field :description
    belongs_to :category, :class_name => 'Forem::Category'
    has_many :topics, :class_name => 'Forem::Topic', :dependent => :destroy
    #has_many :posts, :through => :topics, :dependent => :destroy
    #has_many :views, :through => :topics, :dependent => :destroy


    validates :category_id, :presence => true
    validates :title, :presence => true
    validates :description, :presence => true

    def count_of_posts
      topics.inject(0) {|sum, topic| topic.posts.count + sum }
    end

    def count_of_views
      topics.inject(0) {|sum, topic| topic.views.count + sum }
    end

    def last_post_for(forem_user)
      last_visible_post if self.topics.order_by([['posts.created_at', :desc]]).first == nil
      last_post = self.topics.order_by([['posts.created_at', :desc]]).first.posts.first
      forem_user && forem_user.forem_admin? ? last_post : last_visible_post
    end

    def last_visible_post
      visible_topics = self.topics.where(:hidden => false)
      visible_posts = Post.where(:topic_id.in => visible_topics.map(&:id))
      puts visible_posts.order_by([[:created_at, :desc]]).entries.inspect
      visible_posts.order_by([[:created_at, :desc]]).first
    end
  end
end
