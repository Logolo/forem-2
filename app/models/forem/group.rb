module Forem
  class Group
    include Mongoid::Document

    field :name
    field :html_color, :default => "none"
    field :badge_color, :default => "none"
    field :mc_color
    field :mc_permissions

    validates :name, :presence => true

    has_many :members, :class_name => Forem.user_class.to_s

    attr_accessible :name, :html_color, :badge_color, :mc_color, :mc_permissions

    def to_s
      name
    end
  end
end
