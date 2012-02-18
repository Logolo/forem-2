class Privacy
  include Mongoid::Document

  embedded_in :user
  field :show_draft_buddies,            type: Boolean, default: true
  field :show_previous_drafts,          type: Boolean, default: true
  field :view_online_status,            type: Boolean, default: true
  field :receive_draft_buddy_requests,  type: Boolean, default: true
  field :receive_challenges,            default: :from_anyone # not_at_all, only_draft_buddies, from_anyone
  field :receive_group_invitations,     default: :from_anyone # not_at_all, only_draft_buddies, from_anyone
  embeds_many :blocked_users

  class << self
    def receive_options
      [:not_at_all, :only_draft_buddies, :from_anyone]
    end
  end
end
