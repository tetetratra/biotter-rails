class ProfilesController < ApplicationController
  def index
    @user_name = params[:user_name]
    @user_name = nil if @user_name.blank?
    if @user_name
      user_twitter_ids = Profile.where('user_screen_name = ? OR user_name = ?', @user_name, @user_name).pluck(:user_twitter_id).uniq
      if user_twitter_ids.empty?
        @profiles = Profile.none.page(nil)
        @table_title = "#{@user_name}さんは見つかりません..."
        @title = 'Biotter'
      else
        @profiles = Profile.where(user_twitter_id: user_twitter_ids).order('created_at DESC').page(params[:page])
        @table_title = "#{@profiles.first.user_name}さんのプロフィール履歴"
        @title = "#{@table_title} | Biotter"
      end
    else
      @profiles = Profile.order('created_at DESC').page(params[:page])
      @table_title = '最近の更新'
      @title = 'Biotter'
    end
  end
end
