module Forem
  class Category
    include Mongoid::Document
    include Mongoid::Timestamps

    field :name
    has_many :forums, :class_name => 'Forem::Forum'
    validates :name, :presence => true

    def to_s
      name
    end

  end
end
