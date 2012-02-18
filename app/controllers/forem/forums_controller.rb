module Forem
  class ForumsController < Forem::ApplicationController
    load_and_authorize_resource :only => :show
    helper 'forem/topics'

    def index
      @categories = Forem::Category.all
    end

    def show
      @forum = Forem::Forum.find(params[:id])
      @topics = forem_admin? ? @forum.topics : @forum.topics.visible
      @topics = @topics.by_pinned_or_most_recent_post.page(params[:page]).per(20)
    end
  end
end
