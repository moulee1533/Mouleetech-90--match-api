module Api
  module V1
    module Admin
      class BaseController < ApplicationController
        include StaffAuthenticable

        before_action :authenticate_staff!
      end
    end
  end
end
