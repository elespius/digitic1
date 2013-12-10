class BraintreeAccountsController < ApplicationController

  before_filter do |controller|
    # FIXME Change copy text
    controller.ensure_logged_in t("layouts.notifications.you_must_log_in_to_change_profile_settings")
  end

  # Commonly used paths
  before_filter do |controller|
    @create_path = create_braintree_settings_payment_path(@current_user)
    @update_path = update_braintree_settings_payment_path(@current_user)
    @edit_path = edit_braintree_settings_payment_path(@current_user)
    @new_path = new_braintree_settings_payment_path(@current_user)
  end

  # New/create
  before_filter :ensure_user_does_not_have_account, :only => [:new, :create]

  # Edit/update
  before_filter :ensure_user_has_account, :only => [:edit, :update]

  skip_filter :dashboard_only

  def new
    @braintree_account = create_new_account_object
    render locals: { form_action: @create_path }
  end

  def edit
    @braintree_account = BraintreeAccount.find_by_person_id(@current_user.id)
    render :new, locals: { form_action: @update_path }
  end

  def create
    @braintree_account = BraintreeAccount.new(params[:braintree_account].merge(person: @current_user))
    if @braintree_account.valid?
      merchant_account_result = BraintreeService.create_merchant_account(@braintree_account, @current_community)
    else
      flash[:error] = @braintree_account.errors.full_messages
      render :new, locals: { form_action: @create_path } and return
    end

    if merchant_account_result.success?
      log_info("Successfully created Braintree account for person id #{@current_user.id}")
      @braintree_account.status = merchant_account_result.merchant_account.status
      success = @braintree_account.save!
    else
      log_error("Failed to created Braintree account for person id #{@current_user.id}: #{merchant_account_result.message}")

      success = false
      error_string = "Your payout details could not be saved, because of following errors: "
      merchant_account_result.errors.each do |e|
        error_string << e.message + " "
      end
      flash[:error] = error_string
    end

    if success
      # FIXME Copy text
      flash[:notice] = "Successfully saved!"
      redirect_to @edit_path
    else
      flash[:error] ||= "Error in saving"
      render :new, locals: { form_action: @create_path }
    end
  end

  def update
    success = @braintree_account.update_attributes(params[:braintree_account])

    if success
      # FIXME Copy text
      flash[:notice] = "Successfully updated!"
      redirect_to @edit_path
    else
      flash[:error] = "Error in update"
      render :new, locals: { form_action: @update_path }
    end
  end

  private

  # Before filter
  def ensure_user_does_not_have_account
    braintree_account = BraintreeAccount.find_by_person_id(@current_user.id)

    unless braintree_account.blank?
      flash[:error] = "Can not create a new Braintree account. You already have one"
      redirect_to @edit_path
    end
  end

  # Before filter
  def ensure_user_has_account
    @braintree_account = BraintreeAccount.find_by_person_id(@current_user.id)

    if @braintree_account.blank?
      flash[:error] = "Illegal Braintree accout id"
      redirect_to @new_path
    end
  end

  def create_new_account_object
    person = @current_user
    person_details = {
      first_name: person.given_name,
      last_name: person.family_name,
      email: person.confirmed_notification_email_to, # Our best guess for "primary" email
      phone: person.phone_number
    }

    BraintreeAccount.new(person_details)
  end

  def log_info(msg)
    logger.info "[Braintree] #{msg}"
  end

  def log_error(msg)
    logger.error "[Braintree] #{msg}"
  end
end