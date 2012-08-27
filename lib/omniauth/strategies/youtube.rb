require 'omniauth-oauth2'
require 'multi_json'

module OmniAuth
  module Strategies
    class YouTube < OmniAuth::Strategies::OAuth2
      # Give your strategy a name.
      option :name, 'youtube'
      
      # This is where you pass the options you would pass when
      # initializing your consumer from the OAuth gem.
      option :client_options, {
        :site => 'https://www.youtube.com',
        :authorize_url => 'https://accounts.google.com/o/oauth2/auth',
        :token_url => 'https://accounts.google.com/o/oauth2/token'
      }
      option :authorize_params, {
        :scope => 'http://gdata.youtube.com',
        :access_type => 'offline',
        :approval_prompt => 'force'
      }
      
      # These are called after authentication has succeeded. If
      # possible, you should try to set the UID without making
      # additional calls (if the user id is returned with the token
      # or as a URI parameter). This may not be possible with all
      # providers.
      
      uid { user['id']['$t'] }

      info do
        {
          'uid' => user['id']['$t'],
          'nickname' => user['author'].first['name']['$t'],
          'first_name' => user['yt$firstName'] && user['yt$firstName']['$t'],
          'last_name' => user['yt$lastName'] && user['yt$lastName']['$t'],
          'image' => user['media$thumbnail'] && user['media$thumbnail']['url'],
          'description' => user['yt$description'] && user['yt$description']['$t'],
          'location' => user['yt$location'] && user['yt$location']['$t']
        }
      end

      extra do
        { 'user_hash' => user }
      end

      def user
        user_hash['entry']
      end
      
      def build_access_token
        verifier = request.params['code']
        client.auth_code.get_token(verifier, {:redirect_uri => callback_url}.merge(token_params.to_hash(:symbolize_keys => true)))
      end

      def user_hash
        p "==============user hash"
        p @access_token
        @user_hash ||= MultiJson.decode(@access_token.get("http://gdata.youtube.com/feeds/api/users/default?alt=json").body)
      end

    end
  end
end

OmniAuth.config.add_camelization 'youtube', 'YouTube'