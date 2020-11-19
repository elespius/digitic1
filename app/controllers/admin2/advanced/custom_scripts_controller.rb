module Admin2::Advanced
  class CustomScriptsController < Admin2::AdminBaseController

    def index; end

    def update_script
      @current_community.update!(script_params)
      render json: { message: t('admin2.notifications.custom_script_updated') }
    rescue StandardError => e
      render json: { message: e.message }, status: :unprocessable_entity
    end

    private

    def script_params
      params.require(:community).permit(:custom_head_script)
    end
  end
end
