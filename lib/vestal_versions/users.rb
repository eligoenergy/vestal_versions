module VestalVersions
  # Provides a way for information to be associated with specific versions as to who was
  # responsible for the associated update to the parent.
  module Users
    extend ActiveSupport::Concern

    included do
      attr_accessor :updated_by
      Version.class_eval{ include UserVersionMethods }
    end

    # Methods added to versioned ActiveRecord::Base instances to enable versioning with additional
    # user information.


    private
    # Adds version user attribution, preferring explicit +updated_by+ and
    # falling back to +config.retrieve_user_actor+ when available.
    # Only ActiveRecord actors are accepted.
    def version_attributes
      resolver = vestal_versions_options[:retrieve_user_actor]
      resolved_actor = resolver&.arity == 0 ? resolver.call : resolver&.call(self)
      user_actor = updated_by || resolved_actor

      user_actor = nil unless user_actor.is_a?(ActiveRecord::Base)

      super.merge(:user => user_actor)
    end
  end

  # Instance methods added to VestalVersions::Version to accomodate incoming user information.
  module UserVersionMethods
    extend ActiveSupport::Concern

    included do
      belongs_to :user, :polymorphic => true

      alias_method :user_without_name, :user
      alias_method :user, :user_with_name

      alias_method :user_without_name=, :user=
      alias_method :user=, :user_with_name=
    end


    # Overrides the +user+ method created by the polymorphic +belongs_to+ user association. If
    # the association is absent, defaults to the +user_name+ string column. This allows
    # VestalVersions::Version#user to either return an ActiveRecord::Base object or a string,
    # depending on what is sent to the +user_with_name=+ method.
    def user_with_name
      user_without_name || user_name
    end

    # Overrides the +user=+ method created by the polymorphic +belongs_to+ user association.
    # Based on the class of the object given, either the +user+ association columns or the
    # +user_name+ string column is populated.
    def user_with_name=(value)
      case value
        when ActiveRecord::Base then self.user_without_name = value
        else self.user_name = value
      end
    end

  end
end
