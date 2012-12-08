require 'cancan'

class Forem::ApplicationController < ApplicationController

  before_filter :calculate_online_users

  rescue_from CanCan::AccessDenied do
    redirect_to root_path, :alert => t("forem.access_denied")
  end

  def current_ability
    Forem::Ability.new(forem_user)
  end

  def calculate_online_users
    users = Forem.user_class.where(:last_page_load.gt => 10.minutes.ago)
    max = 0
    @online_list = {}

    users.each do |u|
        group = Forem::Group.where(:members => u.username).asc(:priority).first
        if group == nil
            max = (2**(0.size * 8 -2) -1) # fixnum max
        else
            max = group.priority
        end

        @online_list[max] = Hash.new if @online_list[max] == nil

        @online_list[max].merge!({u.username => (group == nil || group.html_color == nil ? "" : group.html_color)})
    end
  end

  private

  def authenticate_forem_user
    if !forem_user
      session["user_return_to"] = request.fullpath
      flash.alert = t("forem.errors.not_signed_in")
      redirect_to Forem.sign_in_path || main_app.sign_in_path
    end
  end


  def forem_admin?
    forem_user && forem_user.forem_admin?
  end
  helper_method :forem_admin?

  def forem_admin_or_moderator?(forum)
    forem_user && (forem_user.forem_admin? || forum.moderator?(forem_user))
  end
  helper_method :forem_admin_or_moderator?

end
