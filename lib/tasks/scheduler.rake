task :crawl => :environment do
  Exec.crawl
end

class Exec
  def self.crawl
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['BIOTTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['BIOTTER_CONSUMER_SECRET']
      config.access_token        = ENV['BIOTTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['BIOTTER_ACCESS_TOKEN_SECRET']
    end

    follower_profiles = client.followers.map(&:to_h).map do |follower|
      url_master              = ((follower[:entities][:url] && follower[:entities][:url][:urls]).to_a + follower[:entities][:description][:urls]).map { |url| [url[:url], url[:expanded_url]] }
      user_twitter_id         = follower[:id]
      user_screen_name        = follower[:screen_name]
      user_name               = follower[:name]
      user_location           = follower[:location]
      user_profile_image      = fetch_profile_image(follower[:profile_image_url].gsub('_normal', '_200x200'))
      user_profile_banner     = fetch_profile_banner(follower[:profile_banner_url])
      user_description        = follower[:description].then do |description|
        description.nil? ? nil : url_master.inject(description) { |new_description, (short_url, full_url)| new_description.gsub(short_url, full_url) }
      end
      user_url = follower[:url].then do |url|
        url.nil? ? nil : url_master.inject(url) { |new_url, (short_url, full_url)| new_url.gsub(short_url, full_url) }
      end
      {
        user_twitter_id: user_twitter_id,
        user_screen_name: user_screen_name,
        user_name: user_name,
        user_profile_image: user_profile_image,
        user_description: user_description,
        user_url: user_url,
        user_location: user_location,
        user_profile_banner: user_profile_banner
      }
    rescue => e
      p e.full_message
      next nil
    end.compact

    # これらのカラムに変更があったときに更新とみなす
    compare_target_colmn = %i[user_description user_screen_name user_name user_profile_image user_profile_banner user_location]
    selected_follower_profiles = follower_profiles.select do |follower_profile|
      user = User.where(user_twitter_id: follower_profile[:user_twitter_id]).last
      user.nil? || user.profiles.order('created_at DESC').first.slice(*compare_target_colmn).symbolize_keys != follower_profile.slice(*compare_target_colmn)
    end

    selected_follower_profiles.each do |follower_profile|
      user =  User.find_by(user_twitter_id: follower_profile[:user_twitter_id]) \
           || User.create(user_twitter_id: follower_profile[:user_twitter_id])
      user.profiles.create(follower_profile)

      safe_description = follower_profile[:user_description].gsub(/@|#/, ' ')
      tweet_str = "#{follower_profile[:user_name]}さん(#{follower_profile[:user_screen_name]})のプロフィールが更新されました!\n #{safe_description}".truncate(100) \
       + "\nhttp://biotter.tetetratra.net/#{follower_profile[:user_screen_name]}"
      client.update(tweet_str)
    end
  end

  def self.fetch_profile_image(url)
    return nil if url.nil?

    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request['Upgrade-Insecure-Requests'] = '1'
    request['Sec-Fetch-Mode'] = 'navigate'
    request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3'
    req_options = { use_ssl: uri.scheme == 'https' }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(request) }
    body = response.body
    raise if body.include?('DOCTYPE html')

    body
  end

  def self.fetch_profile_banner(url)
    return nil if url.nil?

    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri)
    request['Upgrade-Insecure-Requests'] = '1'
    request['Sec-Fetch-Mode'] = 'navigate'
    request['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3'
    req_options = { use_ssl: uri.scheme == 'https' }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) { |http| http.request(request) }
    body = response.body
    raise if body.include?('DOCTYPE html')

    body
  end
end
