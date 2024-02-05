class FishSocket
  module Listener
    # This module assigned to processing all promo-codes
    module Codes
      def is_admin?()
        return true if TelegramConstants::ADMIN_LIST.include? Listener.message.from.id.to_s
        return false
      end
      module_function(
          :is_admin?
      )
    end
  end
end
