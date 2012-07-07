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

    validates :name, :presence => true

    has_and_belongs_to_many :members, :class_name => Forem.user_class.to_s, :inverse_of => :groups

    attr_accessible :name, :html_color, :badge_color, :mc_color, :mc_permissions, :priority, :can_view, :can_create, :can_reply

    class << self
        def by_priority
            order_by(:priority, :asc)
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
