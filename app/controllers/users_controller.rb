class UsersController < ApplicationController
  def index
    @users = User.joins(:profile)
  end

  def show
    @user = User.find_by(id: params[:id])
  end
end

