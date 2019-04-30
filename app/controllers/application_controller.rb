class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
helper_method :current_user_session, :current_user, :prompt_login, :sidebar


  before_action :set_raven_context

  private

  def set_raven_context
    Raven.user_context(id: session[:current_user_id]) # or anything else in session
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end
 
  def current_user_session
    return @current_user_session if defined?(@current_user_session)

    @current_user_session = UserSession.find
  end

  def current_user
    unless defined?(@current_user)
      @current_user = current_user_session&.record
    end
    # if banned or moderated:
    if @current_user.try(:status) == 0
      # Same effect as if the user clicked logout:
      current_user_session.destroy
      # Ensures no code will use old @current_user info. Treat the user
      # as anonymous (until the login process sets @current_user again):
      @current_user = nil
    elsif @current_user.try(:status) == 5
      # Tell the user they are banned. Fails b/c redirect to require below.
      flash[:warning] = "The user '#{@current_user.username}' has been placed in moderation; please see <a href='https://#{request.host}/wiki/moderators'>our moderation policy</a> and contact <a href='mailto:moderators@#{request.host}'>moderators@#{request.host}</a> if you believe this is in error."
      # Same effect as if the user clicked logout:
      current_user_session.destroy
      # Ensures no code will use old @current_user info. Treat the user
      # as anonymous (until the login process sets @current_user again):
      @current_user = nil
    end
    @current_user
  end
end 