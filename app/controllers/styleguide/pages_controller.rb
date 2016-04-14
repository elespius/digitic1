class Styleguide::PagesController < ApplicationController
  include ReactOnRails::Controller
  layout "styleguide"

  before_action :data

  rescue_from ReactOnRails::PrerenderError do |err|
    Rails.logger.error(err.message)
    Rails.logger.error(err.backtrace.join("\n"))
    redirect_to styleguide_path,
                flash: { error: "Error prerendering in react_on_rails. See server logs." }
  end

  private

  def data
    path_parts = request.env['PATH_INFO'].split("/getting_started_guide")
    has_deep_path = !(path_parts.count == 1 || path_parts == "")
    path_string = has_deep_path ? path_parts[1] : "";

    # This is the props used by the React component.
    @app_props_server_render = {
      helloReduxData: {
        name: "Re Dux"
      },
      onboardingGuidePage: {
        path: path_string,
        onboarding_status: {
          community_id: 1,
          slogan_and_description: true,
          cover_photo: false,
          filter: true,
          paypal: true,
          listing: true,
          invitation: true
        },
        name: PersonViewUtils.person_display_name(@current_user, @current_community),
        translations: I18n.t('admin.onboarding.guide')
      }
    }

  end
end
