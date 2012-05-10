module Forem
  class ModeratorGroup
    include Mongoid::Document

    belongs_to :forum, :inverse_of => :moderator_groups, :class_name => "Forem::Forum"
    belongs_to :group, :class_name => "Forem::Group"

    attr_accessible :group_id
  end
end
