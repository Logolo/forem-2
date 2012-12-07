require 'cancan'

module Forem
  class Ability
    include CanCan::Ability

    def initialize(user)
      user ||= Forem.user_class.new

      # category
      can :read, Forem::Category do |category|
        user.can_read_forem_category?(category)
      end

      # forum
      can :read_forum, Forem::Forum do |forum|
        forum.viewable || user.has_group_permission?("can_view")
      end

      can :read, Forem::Forum do |forum|
        user.can_read_forem_category?(forum.category) && can?(:read_forum, forum)
      end

      # topic
      can :read, Forem::Topic do |topic|
        can?(:read_forum, topic.forum) && user.can_read_forem_topic?(topic)
      end

      can :create_topic, Forem::Forum do |forum|
        can?(:read, forum) && (forum.createable || user.has_group_permission?("can_create"))
      end

      can :reply, Forem::Topic do |topic|
        topic.can_be_replied_to?|| user.has_group_permission?("can_reply")
      end

      can :reply_to_archived, Forem::Topic do |topic|
        user.forem_admin?
      end

      can :delete, Forem::Topic do |topic|
        user.forem_admin?
      end

      # post
      can :edit_post, Forem::Forum do |forum|
        user.can_edit_forem_posts?(forum)
      end

      can :hide, Forem::Post do |post|
        post.user == user || user.forem_admin?
      end

      can :delete, Forem::Post do |post|
        user.forem_admin?
      end

      # punishments
      can :edit_punishments, Object do |obj|
        user.has_group_permission?("can_edit_punishments")
      end

      can :admin, Object do |obj|
        user.forem_admin?
      end
    end
  end
end
