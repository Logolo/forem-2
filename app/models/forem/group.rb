module Forem
  class Group
    include Mongoid::Document

    field :name
    field :html_color
    field :mc_color

    validates :name, :presence => true

    has_many :members, :class_name => Forem.user_class.to_s

    attr_accessible :name

    def to_s
      name
    end
  end
end
