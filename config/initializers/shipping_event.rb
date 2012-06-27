# Configure Spree Preferences
# 
# Note: Initializing preferences available within the Admin will overwrite any changes that were made through the user interface when you restart.
#       If you would like users to be able to update a setting with the Admin it should NOT be set here.
#
# In order to initialize a setting do: 
# config.setting_name = 'new value'
Spree.config do |config|
  Spree::Config[:allow_backorder_shipping] = false
end

