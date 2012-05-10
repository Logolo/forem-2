require 'active_support/concern'

module Forem
  module Concerns
    module Viewable
      extend ActiveSupport::Concern

      included do
        field :views_count
        has_many :views, :as => :viewable, :class_name => "Forem::View"
      end

      def view_for(user)
        views.where(:user_id => user.id).first
      end

      # Track when users last viewed topics
      def register_view_by(user)
        return unless user

        view = views.find_or_create_by(:user_id => user.id)
        view.inc(:count, 1)
        inc(:views_count, 1)
        #view.increment(:views_count, 1)
        #view.increment!("count")
        #increment!(:views_count)

        # update current viewed at if more than 15 minutes ago
        if view.current_viewed_at < 15.minutes.ago
          view.past_viewed_at    = view.current_viewed_at
          view.current_viewed_at = Time.now
          view.save
        end
      end
    end
  end
end