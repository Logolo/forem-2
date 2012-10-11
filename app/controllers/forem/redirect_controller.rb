class Forem::RedirectController < ApplicationController
    def forum
        return redirect_to forum_path(params[:forum_id])
    end

    def topic
        return redirect_to topic_path(params[:topic_id])
    end

    def posts
        post = Forem::Post.find(params[:post_id])
        return redirect_to root_path, :notice => "Post does not exist" if post.topic == nil
        x = 0

        if !forem_user || !forem_user.admin
            posts = post.topic.posts.approved
        else
            posts = post.topic.posts
        end

        posts.by_created_at.each_with_index do |p, i|
            x = i
            break if p.id == post.id
        end
        return redirect_to topic_url(post.topic, :page => (x / Forem.per_page) + 1) + "#" + post.id.to_s
    end

    def subscriptions
        return redirect_to my_subscriptions_path
    end
end
