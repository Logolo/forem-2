module Forem
  class Category
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name
    field :order, :type => Integer, :default => 0

    has_many :forums, :class_name => 'Forem::Forum'
    validates :name, :presence => true
    attr_accessible :name, :order

    def to_s
      name
    end

  end
end
