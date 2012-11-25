module Forem
  class Alert
    include Mongoid::Document
    include Mongoid::Timestamps
    include ActionView::Helpers::DateHelper

    field :read, :type => Boolean, :default => false

    field :created_at, :type => DateTime
    field :updated_at, :type => DateTime
    field :read_at, :type => DateTime

    # Forem::Topic
    field :forem_topic_replier
    field :forem_topic_count, :default => 0
    belongs_to :forem_topic_post, :class_name => "Forem::Post"

    # Relations
    belongs_to :subscription, :class_name => "Forem::Subscription"
    belongs_to :user, :index => true

    def link
      str = ""
      case self.subscription.subscribable_type
      when "Forem::Topic"
        str += "/forums/"
        if self.forem_topic_post == nil
          str += "topics/" + self.subscription.subscribable.id.to_s
        else
          str += "posts/" + self.forem_topic_post_id.to_s
        end
      when "Friendship"
        str += "/friendships/pending"
      else
        str
      end
      str
    end

    def text
      str = ""
      case self.subscription.subscribable_type
      when "Forem::Topic"
        str += self.forem_topic_replier
        if self.forem_topic_count > 0
          str += " and " + self.forem_topic_count.to_s + " other" + (self.forem_topic_count > 1 ? "s" : "")
        end
        str += " replied to " + self.subscription.subscribable.subject
      when "Friendship"
        str += self.subscription.subscribable.friender + " has requested to be your friend"
      else
        str
      end
      str += " " + time_ago_in_words(self.updated_at, false, :vague => true) + " ago"
    end
  end

end