module Devise
  module Controllers
    module Filters

    protected

      # The main accessor for the warden proxy instance
      #
      def warden
        request.env['warden']
      end

      # Check if a user is authenticated or not performing the proper action.
      #
      def authenticate!(scope)
        warden.authenticate!(:scope => scope)
      end

      # Proxy to the authenticated? method on warden
      #
      def authenticated?(scope)
        warden.authenticated?(scope)
      end
      alias :signed_in? :authenticated?

      # Logout based on scope
      #
      def logout(scope, *args)
        warden.raw_session.inspect # Without this inspect here. The session does not clear.
        warden.logout(scope, *args)
      end

      # Define authentication filters based on mappings. These filters should be
      # used inside the controllers as before_filters, so you can control the
      # scope of the user who should be signed in to access that specific
      # controller/action.
      #
      # Example:
      #
      #   Maps:
      #     Devise.map :users, :for => [:authenticable]
      #     Devise.map :admin, :for => [:authenticable]
      #
      #   Generated Filters:
      #     user_authenticate!
      #     admin_authenticate!
      #
      #   Use:
      #     before_filter :user_authenticate! # Tell devise to use :user map
      #     before_filter :admin_authenticate! # Tell devise to use :admin map
      #
      Devise.mappings.each_key do |mapping|
        class_eval <<-METHODS, __FILE__, __LINE__
          def #{mapping}_authenticate!
            warden.authenticate!(:scope => :#{mapping})
          end

          def #{mapping}_authenticated?
            warden.authenticated?(:#{mapping})
          end

          def current_#{mapping}
            @current_#{mapping} ||= warden.user(:#{mapping})
          end
        METHODS
      end

      # Helper for use in before_filters where no authentication is required.
      #
      # Example:
      #   before_filter :require_no_authentication, :only => :new
      #
      def require_no_authentication
        redirect_to root_path if warden.authenticated?(resource_name)
      end

      def is_devise_resource?
        raise ActionController::UnknownAction unless devise_mapping && devise_mapping.allows?(controller_name)
      end

    end
  end
end
