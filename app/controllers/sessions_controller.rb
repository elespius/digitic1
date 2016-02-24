require 'rest_client'

class SessionsController < ApplicationController

  skip_filter :check_email_confirmation
  skip_filter :cannot_access_if_banned, :only => [ :destroy, :confirmation_pending ]

  # For security purposes, Devise just authenticates an user
  # from the params hash if we explicitly allow it to. That's
  # why we need to call the before filter below.
  before_filter :allow_params_authentication!, :only => :create

  def new
    @selected_tribe_navi_tab = "members"
    @facebook_merge = session["devise.facebook_data"].present?
    if @facebook_merge
      @facebook_email = session["devise.facebook_data"]["email"]
      @facebook_name = "#{session["devise.facebook_data"]["given_name"]} #{session["devise.facebook_data"]["family_name"]}"
    end
  end

  def create
    session[:form_login] = params[:person][:login]

    # Start a session with Devise

    # In case of failure, set the message already here and
    # clear it afterwards, if authentication worked.
    flash.now[:error] = t("layouts.notifications.login_failed")

    # Since the authentication happens in the rack layer,
    # we need to tell Devise to call the action "sessions#new"
    # in case something goes bad.
    person = authenticate_person!(:recall => "sessions#new")
    @current_user = person

    flash[:error] = nil

    # Store Facebook ID and picture if connecting with FB
    if session["devise.facebook_data"]
      @current_user.update_attribute(:facebook_id, session["devise.facebook_data"]["id"])
      # FIXME: Currently this doesn't work for very unknown reason. Paper clip seems to be processing, but no pic
      if @current_user.image_file_size.nil?
        @current_user.store_picture_from_facebook
      end
    end

    sign_in @current_user

    session[:form_login] = nil

    if @current_user
      @current_user.update_attribute(:active, true) unless @current_user.active?
    end

    unless terms_accepted?(@current_user, @current_community) || @current_user.is_admin?
      sign_out @current_user
      session[:temp_cookie] = "pending acceptance of new terms"
      session[:temp_person_id] =  @current_user.id
      session[:temp_community_id] = @current_community.id
      session[:consent_changed] = true if @current_user
      redirect_to terms_path and return
    end

    session[:person_id] = current_person.id

    flash[:notice] = t("layouts.notifications.login_successful", person_name: view_context.link_to(@current_user.given_name_or_username, person_path(@current_user))).html_safe
    if session[:return_to]
      redirect_to session[:return_to]
      session[:return_to] = nil
    elsif session[:return_to_content]
      redirect_to session[:return_to_content]
      session[:return_to_content] = nil
    else
      redirect_to root_path
    end
  end

  def destroy
    sign_out
    session[:person_id] = nil
    flash[:notice] = t("layouts.notifications.logout_successful")
    redirect_to root
  end

  def index
    redirect_to login_path
  end

  def request_new_password
    if person = Person.find_by_email_address_and_community_id(params[:email], @current_community.id)
      token = person.reset_password_token_if_needed
      MailCarrier.deliver_later(PersonMailer.reset_password_instructions(person, params[:email], token, @current_community))
      flash[:notice] = t("layouts.notifications.password_recovery_sent")
    else
      flash[:error] = t("layouts.notifications.email_not_found")
    end

    redirect_to login_path
  end

  def facebook
    data = request.env["omniauth.auth"].extra.raw_info
    I18n.locale = URLUtils.extract_locale_from_url(request.env['omniauth.origin']) if request.env['omniauth.origin']

    person =
      Person.find_by_facebook_id_and_community(data.id, @current_community.id) ||
      Person.find_by_email_address_and_community_id(data.email, @current_community.id)

    if person
      person.update_facebook_data(data.id) unless person.facebook_id
      @person = person
      flash[:notice] = t("devise.omniauth_callbacks.success", :kind => "Facebook")
      sign_in_and_redirect @person, :event => :authentication
    else

      if data.email.blank?
        flash[:error] = t("layouts.notifications.could_not_get_email_from_facebook")
        redirect_to sign_up_path and return
      end

      facebook_data = {"email" => data.email,
                       "given_name" => data.first_name,
                       "family_name" => data.last_name,
                       "username" => data.username,
                       "id"  => data.id}

      session["devise.facebook_data"] = facebook_data
      redirect_to :action => :create_facebook_based, :controller => :people
    end
  end

  #Facebook setup phase hook, that is used to dynamically set up a omniauth strategy for facebook on customer basis
  def facebook_setup
    request.env["omniauth.strategy"].options[:client_id] = @current_community.facebook_connect_id || APP_CONFIG.fb_connect_id
    request.env["omniauth.strategy"].options[:client_secret] = @current_community.facebook_connect_secret || APP_CONFIG.fb_connect_secret
    request.env["omniauth.strategy"].options[:iframe] = true
    request.env["omniauth.strategy"].options[:scope] = "public_profile,email"
    request.env["omniauth.strategy"].options[:info_fields] = "name,email,last_name,first_name"

    render :plain => "Setup complete.", :status => 404 #This notifies the ominauth to continue
  end

  # Callback from Omniauth failures
  def failure
    I18n.locale = URLUtils.extract_locale_from_url(request.env['omniauth.origin']) if request.env['omniauth.origin']
    error_message = params[:error_reason] || "login error"
    kind = env["omniauth.error.strategy"].name.to_s || "Facebook"
    flash[:error] = t("devise.omniauth_callbacks.failure",:kind => kind.humanize, :reason => error_message.humanize)
    redirect_to root
  end

  # This is used if user has not confirmed her email address
  def confirmation_pending
    if @current_user.blank?
      redirect_to root
    end
  end

  private

  def terms_accepted?(user, community)
    user && community.consent.eql?(user.consent(community))
  end

end
