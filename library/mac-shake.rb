# frozen_string_literal: true
module TelegramConstants
  API_KEY ="API_KEY"
  ERROR_CHANNEL_ID='ID'
  ADMIN_LIST=["ID","ID"]
  WHITE_LIST_IDS=['ID','ID']#may not include admins, different arrays
  #CHANNEL_LINK="@type or t.me"
  def setup()
    #file = File.open("whitelist.txt")
    #file.readlines.map(&:chomp).each{|element| TelegramConstants::WHITE_LIST_IDS<<element}
    #p TelegramConstants::WHITE_LIST_IDS
    #file.close
  end
  module_function(
          :setup
      )
end
