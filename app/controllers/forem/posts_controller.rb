module Forem
  class PostsController < Forem::ApplicationController
    before_filter :authenticate_forem_user
    before_filter :find_topic
    before_filter :block_spammers, :only => [:new, :create]

    def new
      authorize! :reply, @topic
      @post = @topic.posts.build
      if params[:reply_to_id]
        @reply_to = @topic.posts.find(params[:reply_to_id])
      end
    end

    def create
      authorize! :reply, @topic

      if !can?(:reply, @topic)
        flash.alert = t("forem.post.not_created_topic_locked")
        redirect_to [@topic] and return
      end

      @post = @topic.posts.create(params[:post])
      @post.user_id = forem_user.id
      if @post.save
        @post.skip_pending_review_if_user_approved
        @topic.alert_subscribers(current_user.id)
        @topic.forum.increment_posts_count
        flash[:notice] = t("forem.post.created")
        redirect_to root_path + "/posts/" + @post.id
      else
        params[:reply_to_id] = params[:post][:reply_to_id]
        flash.now.alert = t("forem.post.not_created")
        render :action => "new"
      end
    end

    def edit
      authorize! :edit_post, @topic.forum
      @post = Post.find(params[:id])
    end

    def update
      authorize! :edit_post, @topic.forum
      if @topic.locked?
        flash.alert = t("forem.post.not_created_topic_locked")
        redirect_to [@topic] and return
      end
      @post = Post.find(params[:id])
      if @post.owner_or_admin?(forem_user) and @post.update_attributes(params[:post])
        redirect_to [@topic], :notice => t('edited', :scope => 'forem.post')
      else
        flash.now.alert = t("forem.post.not_edited")
        render :action => "edit"
      end
    end

    def destroy
      @post = @topic.posts.find(params[:id])
      if @topic.locked
        flash.alert = t("forem.post.not_created_topic_locked")
        redirect_to [@topic] and return
      end

      if !can?(:delete, @post)
        flash.alert = t("forem.post.cannot_delete")
        redirect_to [@topic] and return
      end

      @post.destroy
      if @post.topic.posts.count == 0
          @post.topic.destroy
          flash[:notice] = t("forem.post.deleted_with_topic")
          redirect_to [@topic.forum]
      else
          flash[:notice] = t("forem.post.deleted")
          redirect_to [@topic]
      end
    end

    private

    def find_topic
      @topic = Forem::Topic.find(params[:topic_id])
    end

    def block_spammers
      if forem_user.forem_state == "spam"
        flash[:alert] = t('forem.general.flagged_for_spam') + ' ' + t('forem.general.cannot_create_post')
        redirect_to :back
      end
    end

    def last_page
      (@topic.posts.count.to_f / Forem.per_page.to_f).ceil
    end
  end
end
