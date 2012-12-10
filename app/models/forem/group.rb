module Forem
  class Group
    include Mongoid::Document

    field :name
    field :html_color, :default => "none"
    field :badge_color, :default => "none"
    field :mc_color
    field :mc_permissions
    field :priority, :type => Integer, :default => 0
    field :can_view, :type => Boolean, :default => false
    field :can_create, :type => Boolean, :default => false
    field :can_reply, :type => Boolean, :default => false
    field :can_edit_punishments, :type => Boolean, :default => false
    field :can_appeal, :type => Boolean, :default => false

    validates :name, :presence => true

    field :members, :type => Array, :default => []

    attr_accessible :name, :html_color, :badge_color, :mc_color, :mc_permissions, :priority, :can_view, :can_create, :can_reply, :can_edit_punishments, :can_appeal

    class << self
        def by_priority
            asc(:priority)
        end
    end

    def to_s
      name
    end

    def server_side?
        self.name[0] == "_"
    end
  end
end
