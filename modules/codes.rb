class FishSocket
  module Listener
    # This module assigned to processing all promo-codes
    module Codes
      def is_admin?(user)
        return true if TelegramConstants::ADMIN_LIST.include? user.id.to_s
        return false
      end
      def is_in_whitelist?(user)
        if TelegramConstants::WHITE_LIST_IDS.include? user.id.to_s
          Listener.bot.logger.info("in whitelist")
          return true
        end
        Listener.bot.logger.info("NOT in whitelist")
        return false
      end
      module_function(
          :is_admin?,
          :is_in_whitelist?
      )
    end
  end
end
