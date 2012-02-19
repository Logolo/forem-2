module Forem
  module TopicsHelper
    def link_to_latest_post(post)
      post_link = link_to "#{time_ago_in_words(post.created_at)}", forum_topic_path(post.topic.forum, post.topic, :anchor => "post-#{post.id}")
      user_link = link_to (render :partial => "shared/decorated_username_for", :object => post.user), main_app.public_user_path(post.user.id)

      return post_link + " #{t("ago_by")} " + user_link
    end
  end
end
