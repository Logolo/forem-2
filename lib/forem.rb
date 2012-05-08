# Fix for #185 and build issues
require 'active_support/core_ext/kernel/singleton_class'

require 'forem/engine'
require 'forem/autocomplete'
require 'forem/default_permissions'
require 'workflow'

module Forem
  mattr_accessor :user_class, :theme, :formatter, :default_gravatar, :default_gravatar_image,
                 :user_profile_links, :email_from_address, :autocomplete_field,
                 :avatar_user_method, :per_page, :sign_in_path


  class << self
    def autocomplete_field
      @@autocomplete_field || "email"
    end

    def per_page
      @@per_page || 20
    end

    def user_class
      if @@user_class.is_a?(Class)
        raise "You can no longer set Forem.user_class to be a class. Please use a string instead.\n\n " +
              "See https://github.com/radar/forem/issues/88 for more information."
      elsif @@user_class.is_a?(String)
        @@user_class.constantize
      end
    end
  end
end
