module Digilocker
  class CallbackProcessor
    Result = Struct.new(:success?, :user, :error, keyword_init: true)

    def self.call(code:, state:)
      new(code:, state:).call
    end

    def initialize(code:, state:)
      @code = code
      @state = state
    end

    def call
      session = DigilockerSession.find_by(state: @state)
      return failure("invalid state") unless session
      return failure("session expired", session:) if session.expired? || session.status != "started"
      return failure("missing authorization code", session:) if @code.blank?

      token = Digilocker::TokenExchanger.call(code: @code, code_verifier: session.code_verifier)
      profile = Digilocker::ProfileFetcher.call(
        access_token: token["access_token"],
        user: session.user
      )
      user = Digilocker::UserLinker.call(user: session.user, profile: profile)
      session.mark_completed!

      Result.new(success?: true, user: user, error: nil)
    rescue Digilocker::TokenExchanger::Error, Digilocker::ProfileFetcher::Error, Digilocker::UserLinker::Error => e
      session&.mark_failed!(e.message)
      failure(e.message)
    end

    private

    def failure(message, session: nil)
      session&.mark_failed!(message) if session&.status == "started"
      Result.new(success?: false, user: session&.user, error: message)
    end
  end
end
