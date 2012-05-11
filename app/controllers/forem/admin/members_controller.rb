module Forem
  class Admin::MembersController < ApplicationController

    def create
      user = Forem.user_class.where(Forem.autocomplete_field => params[:user]).first
      unless group.members.where(:user_id => user.id).count > 0
        group.push(:members, user)
        group.save
      end
      render :status => :ok
    end

    private

    def group
      @group ||= Group.find(params[:group_id])
    end
  end
end
