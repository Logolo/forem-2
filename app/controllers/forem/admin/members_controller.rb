module Forem
  class Admin::MembersController < ApplicationController

    def create
      user = Forem.user_class.where(Forem.autocomplete_field => params[:user]).first
      unless group.members.where(:username => user.username).count > 0
        user.groups << group
        user.save
      end
      render :json => nil, :status => :ok
    end

    def destroy
      user = Forem.user_class.find(params[:id])
      group.member_ids.delete(user.id)
      group.save
      flash[:alert] = user.username + " was removed from the group"
      redirect_to [:admin, group]
    end

    private

    def group
      @group ||= Group.find(params[:group_id])
    end
  end
end
