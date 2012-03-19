module Sorcery
  module Controller
    module Submodules
      module External
        module Providers
          # This module adds support for OAuth with vk.com.
          # When included in the 'config.providers' option, it adds a new option, 'config.vk'.
          # Via this new option you can configure VK specific settings like your app's key and secret.
          #
          #   config.vk.key = <key>
          #   config.vk.secret = <secret>
          #   ...
          #
          module Vk
            def self.included(base)
              base.module_eval do
                class << self
                  attr_reader :vk                           # access to vk_client.

                  def merge_vk_defaults!
                    @defaults.merge!(:@vk => VkClient)
                  end
                end
                merge_vk_defaults!
                update!
              end
            end

            module VkClient
              class << self
                attr_accessor :key,
                              :secret,
                              :callback_url,
                              :site,
                              :user_info_path,
                              :scope,
                              :user_info_mapping,
                              :display
                attr_reader   :access_token

                include Protocols::Oauth2

                def init
                  @site           = "https://oauth.vk.com/"
                  @auth_url       = "authorize"
                  @token_path     = "access_token"
                  @scope          = "notify,friends"
                  @user_info_mapping = {}
                  @display        = "page"
                  @mode           = :query
                  @parse          = :query
                  @param_name     = "code"
                  @fields = ['uid', 'first_name', 'last_name', 'nickname', 'domain', 'sex', 'city', 'country', 'timezone', 'photo', 'photo_big']
                end

                def get_user_hash
                  user_hash = {}
                  response = @access_token.get("https://api.vk.com/method/getProfiles?uid=#{@access_token['user_id']}&fields=#{@fields.join(',')}&access_token=#{@access_token.token}")
                  user_hash[:user_info] = JSON.parse(response.body)['response'][0]
                  user_hash[:uid] = user_hash[:user_info]['uid']
                  user_hash
                end

                def has_callback?
                  true
                end

                # calculates and returns the url to which the user should be redirected,
                # to get authenticated at the external provider's site.
                def login_url(params,session)
                  self.authorize_url
                end

                # tries to login the user from access token
                def process_callback(params,session)
                  args = {}
                  args.merge!({:code => params[:code]}) if params[:code]
                  options = {
                      :token_url => @token_path,
                      :token_method => :get
                  }
                  @access_token = self.get_access_token(args, options)
                end

              end
              init
            end
          end
        end
      end
    end
  end
end


