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

    #def posts
    #  # TODO: this is probably a bad idea
    #  self.all.map(&:topics).flatten.map(&:posts).flatten
    #end

    def last_post_for(forem_user)
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
