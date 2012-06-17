module Forem
  class Group
    include Mongoid::Document

    field :name
    field :html_color, :default => "none"
    field :badge_color, :default => "none"
    field :mc_color
    field :mc_permissions
    field :priority, :type => Integer, :default => 0

    validates :name, :presence => true

    has_and_belongs_to_many :members, :class_name => Forem.user_class.to_s, :inverse_of => :groups

    attr_accessible :name, :html_color, :badge_color, :mc_color, :mc_permissions, :priority

    class << self
        def by_priority
            order_by(:priority)
        end
    end

    def to_s
      name
    end
  end
end
