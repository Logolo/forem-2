module Forem
  class ForumsController < Forem::ApplicationController

    before_filter :authenticate_forem_user, :only => [:create, :new]
    before_filter :block_spammers, :only => [:new, :create]
    helper 'forem/topics'

    def index
      @categories = Forem::Category.all.order_by([:order, :asc])
      @whatsnew = Forem::Topic.all.by_most_recent_post.page(params[:page]).per(20)
    end

    def show
      @forum = Forem::Forum.find(params[:id])
      register_view

      @topics = if forem_admin_or_moderator?(@forum)
        @forum.topics
      else
        @forum.topics.visible.approved_or_pending_review_for(forem_user)
      end

      @topics = @topics.by_pinned_or_most_recent_post.page(params[:page]).per(Forem.per_page)

      respond_to do |format|
        format.html
        format.atom { render :layout => false }
      end
    end

    def new
      @forum = Forem::Forum.find(params[:forum_id])
      authorize! :create_topic, @forum
      @topic = @forum.topics.build
      @topic.posts.build
    end

    def create
      @forum = Forem::Forum.find(params[:forum_id])
      authorize! :create_topic, @forum
      @topic = @forum.topics.build(params[:topic])
      @topic.user = forem_user
      if @topic.save && @topic.posts.first.save
        flash[:notice] = t("forem.topic.created")
        redirect_to @topic
      else
        flash.now.alert = t("forem.topic.not_created")
        render :action => "new"
      end
    end

    private
    def register_view
      @forum.register_view_by(forem_user)
    end

    def block_spammers
      if forem_user.forem_state == "spam"
        flash[:alert] = t('forem.general.flagged_for_spam') + ' ' + t('forem.general.cannot_create_topic')
        redirect_to :back
      end
    end
  end
end
