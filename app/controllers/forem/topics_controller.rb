module Forem
  class TopicsController < Forem::ApplicationController
    helper 'forem/posts'
    before_filter :authenticate_forem_user, :except => [:show]
    before_filter :find_forum, :except => [:subscriptions]
    before_filter :block_spammers, :only => [:new, :create]

    def show
      if find_topic
        register_view
        @posts = @topic.posts.order_by([:created_at, :asc])
        unless forem_admin_or_moderator?(@forum)
          @posts = @posts.approved_or_pending_review_for(forem_user)
        end
        @posts = @posts.page(params[:page]).per(Forem.per_page)
      end
    end

    def destroy
      @topic = @forum.topics.find(params[:id])
      if forem_user == @topic.user || forem_user.forem_admin?
        @topic.destroy
        flash[:notice] = t("forem.topic.deleted")
      else
        flash.alert = t("forem.topic.cannot_delete")
      end

      redirect_to @topic.forum
    end

    def subscribe
      if find_topic
        @topic.subscribe_user(forem_user.id)
        flash[:notice] = t("forem.topic.subscribed")
        redirect_to topic_url(@topic)
      end
    end

    def unsubscribe
      if find_topic
        @topic.unsubscribe_user(forem_user.id)
        flash[:notice] = t("forem.topic.unsubscribed")
        redirect_to topic_url(@topic)
      end
    end

    def subscriptions
        @subscriptions = Forem::Subscription.where(:subscriber_id => forem_user.id, :subscribable_type => "Forem::Topic").asc(:updated_at)
        @topics = Array.new
        @subscriptions.each do |sub|
            @topics << sub.subscribable
        end
        @topics = Kaminari.paginate_array(@topics).page(params[:page]).per(20)
    end

    private
    def find_forum
      @forum = Forem::Topic.find(params[:id]).forum
      authorize! :read, @forum
    end

    def find_topic
      begin
        scope = forem_admin_or_moderator?(@forum) ? @forum.topics : @forum.topics.visible.approved_or_pending_review_for(forem_user)
        @topic = scope.find(params[:id])
        authorize! :read, @topic
      rescue Mongoid::Errors::DocumentNotFound
        flash.alert = t("forem.topic.not_found")
        redirect_to @forum and return
      end
    end

    def register_view
      @topic.register_view_by(forem_user)
    end

    def block_spammers
      if forem_user.forem_state == "spam"
        flash[:alert] = t('forem.general.flagged_for_spam') + ' ' + t('forem.general.cannot_create_topic')
        redirect_to :back
      end
    end
  end
end
