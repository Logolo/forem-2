require 'active_support/concern'

module Forem
    module Concerns
        module Subscribable
            extend ActiveSupport::Concern

            included do
                has_many :subscriptions, :as => :subscribable, :class_name => "Forem::Subscription"
            end

            def subscribe_creator
                subscribe_user(self.user_id)
            end

            def subscribe_user(user_id)
                if user_id && !subscriber?(user_id)
                    subscriptions.create(:subscriber_id => user_id)
                end
            end

            def unsubscribe_user(user_id)
                subscriptions.where(:subscriber_id => user_id).destroy_all
            end

            def subscriber?(user_id)
                subscriptions.where(:subscriber_id => user_id).count > 0
            end

            def subscription_for user_id
                subscriptions.first(:conditions => { :subscriber_id=>user_id })
            end

            def alert_subscribers(*args)
                subscriptions.each do |sub|
                    sub.alert_subscriber(args)
                end
            end
        end
    end
end