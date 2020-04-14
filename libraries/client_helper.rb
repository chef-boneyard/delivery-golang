module Chef_Delivery
  class ClientHelper
    class << self
      def return_to_zero(_zero_config = nil)
        if @@zero_mode_config
          Chef::Log.info('Entering zero mode')
          Chef::Config.configuration = @@zero_mode_config
        end
      end

      def load_delivery_user
        Chef::Log.info('Loading delivery user')
        # This will allow you to interact with the chef-server
        # but first lets save the chef-zero Chef::Config
        @@zero_mode_config = Chef::Config.configuration.dup
        Chef::Config.from_file(File.expand_path(File.join('/var/opt/delivery/workspace/.chef', 'knife.rb')))
      end
    end
  end
end
