module EmailService::API
  AddressStore = EmailService::Store::Address
  Synchronize = EmailService::SES::Synchronize

  class Addresses

    def initialize(default_sender:, ses_client: nil)
      @default_sender = default_sender
      @ses_client = ses_client
    end

    def get_sender(community_id:)
      sender = Maybe(community_id).map {
        AddressStore.get_latest_verified(community_id: community_id)
      }.map { |address|
        {
          type: :user_defined,
          display_format: to_format(name: address[:name], email: address[:email], quotes: false),
          smtp_format: to_format(name: address[:name], email: address[:email], quotes: true)
        }
      }.or_else(
        type: :default,
        display_format: @default_sender,
        smtp_format: @default_sender
      )

      Result::Success.new(sender)
    end

    def get_user_defined(community_id:)
      Maybe(AddressStore.get_latest(community_id: community_id)).map { |address|
        Result::Success.new(
          with_formats(address))
      }.or_else {
        Result::Error.new("Can not find for community_id: #{community_id}")
      }
    end

    def create(community_id:, address:)
      unless valid_email?(address[:email])
        return Result::Error.new("Incorrect email format: '#{address[:email]}'", error_code: :invalid_email, email: address[:email])
      end

      create_in_status = @ses_client ? :none : :verified

      address = with_formats(
        AddressStore.create(
        community_id: community_id,
        address: address.merge(verification_status: create_in_status)))

      if @ses_client
        enqueue_verification_request(community_id: address[:community_id], id: address[:id])
      end

      Result::Success.new(address)
    end

    def enqueue_verification_request(community_id:, id:)
      if @ses_client
        Delayed::Job.enqueue(
          EmailService::Jobs::RequestEmailVerification.new(community_id, id))
      end
    end

    def enqueue_status_sync(community_id:, id:)
      if @ses_client
        Delayed::Job.enqueue(
          EmailService::Jobs::SingleSync.new(community_id, id))
      end
    end

    def enqueue_batch_sync
      if @ses_client
        Delayed::Job.enqueue(EmailService::Jobs::BatchSync.new)
      end
    end

    private

    def with_formats(address)
      address.merge(
        display_format: to_format(name: address[:name], email: address[:email], quotes: false),
        smtp_format: to_format(name: address[:name], email: address[:email], quotes: true))
    end

    def to_format(name: nil, email:, quotes:)
      if name.present?
        "#{quote(name, quotes)} <#{email}>"
      else
        email
      end
    end

    def quote(str, quotes)
      if quotes
        # Use inspect to add quotes.
        # Accoring to Ruby docs, inspect:
        # "Returns a printable version of str, surrounded by quote marks, with special characters escaped"
        str.inspect
      else
        str
      end
    end

    def valid_email?(email)
      if email
        email_regexp =
          /\A[A-Z0-9._%\-\+\~\/]+@([A-Z0-9-]+\.)+[A-Z]+\z/i # This is the same
                                                            # regexp that is used
                                                            # in Email model
        email_regexp.match(email).present?
      else
        false
      end
    end
  end

end
