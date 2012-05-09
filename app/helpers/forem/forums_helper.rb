module Forem
  module ForumsHelper
    def topics_count(forum)
      if forem_admin_or_moderator?(forum)
        forum.topics.count
      else
        forum.topics.approved.count
      end
    end

    def posts_count(forum)
      if forem_admin_or_moderator?(forum)
        forum.topics.inject(0) {|sum, topic| topic.posts.count + sum }
      else
        forum.topics.where(:state => :approved).inject(0) {|sum, topic| topic.posts.count + sum }
      end
    end
  end
end
