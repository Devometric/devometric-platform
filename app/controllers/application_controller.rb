class ApplicationController < ActionController::Base
  include Localizable

  allow_browser versions: :modern
end
