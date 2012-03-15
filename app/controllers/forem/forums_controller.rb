module Forem
  class ForumsController < Forem::ApplicationController
#TODO reenable this
#    load_and_authorize_resource :only => :show
    helper 'forem/topics'

    def index
      @categories = Forem::Category.all
    end

    def show
      if params[:id].length < 8 # Our token length is set to 5, but this gives us room to grow before we see bugs. 
        @group = Group.find_by_token(params[:id])
        @forum = Forem::Forum.find(@group.forum_id)    
      else
        if Group.count(:conditions => {:id => params[:id]}) > 0
          @group = Group.find(params[:id])
          @forum = Forem::Forum.find(@group.forum_id)
        else
          @forum = Forem::Forum.find(params[:id])  
          @group = Group.where(:forum_id => @forum.id).first 
        end       
      end

      @topics = forem_admin? ? @forum.topics : @forum.topics.visible
      @topics = @topics.by_pinned_or_most_recent_post.page(params[:page]).per(10)
    end
        
  end
end
