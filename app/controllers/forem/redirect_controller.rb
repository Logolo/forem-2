class Forem::RedirectController < ApplicationController
    def forum
        return redirect_to forum_path(params[:forum_id])
    end

    def topic
        return redirect_to topic_path(params[:topic_id])
    end

    def posts
        post = Forem::Post.find(params[:post_id])
        x = 0
        post.topic.posts.each_with_index do |p, i|
            x = i
            break if p.id == post.id
        end
        return redirect_to topic_url(post.topic, :page => (x / 20) + 1) + "#" + post.id.to_s

    end
end
