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
      # ツイッター用に短縮されたURLを戻すため、URLの対応テーブルをつくる
      url_master = ((follower[:entities][:url] && follower[:entities][:url][:urls]).to_a + follower[:entities][:description][:urls])
                     .map { |url| [url[:url], url[:expanded_url]] }

      user_twitter_id         = follower[:id]
      user_screen_name        = follower[:screen_name]
      user_name               = follower[:name]
      user_location           = follower[:location]
      user_description        = follower[:description].then do |description|
        description.nil? ? nil : url_master.inject(description) { |new_description, (short_url, full_url)| new_description.gsub(short_url, full_url) }
      end
      user_url = follower[:url].then do |url|
        url.nil? ? nil : url_master.inject(url) { |new_url, (short_url, full_url)| new_url.gsub(short_url, full_url) }
      end
      user_profile_image      = fetch_profile_image(follower[:profile_image_url].gsub('_normal', '_200x200'))
      user_profile_banner     = fetch_profile_banner(follower[:profile_banner_url])

      {
        user_twitter_id: user_twitter_id,
        user_screen_name: user_screen_name,
        user_name: user_name,
        user_location: user_location,
        user_description: user_description,
        user_url: user_url,
        user_profile_image: user_profile_image,
        user_profile_banner: user_profile_banner
      }
    rescue => e
      p e.full_message(highlight: false)
      next nil
    end.compact

    follower_profiles.each do |follower_profile|
      next unless Profile.find_by(**follower_profile).empty?

      Profile.create(**follower_profile)

      safe_description = follower_profile[:user_description].gsub(/@|#|\*/, '●')
      tweet_str = "#{follower_profile[:user_name]}さん(#{follower_profile[:user_screen_name]})のプロフィールが更新されました!\n #{safe_description}".truncate(100) \
       + "\nhttps://biotter.tetetratra.net/#{follower_profile[:user_screen_name]}"
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
