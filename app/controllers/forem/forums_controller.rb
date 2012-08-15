module Forem
  class ForumsController < Forem::ApplicationController
#TODO reenable this
#    load_and_authorize_resource :only => :show
    helper 'forem/topics'

    def index
      @categories = Forem::Category.all.order_by([:order, :asc])
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

  end
end
