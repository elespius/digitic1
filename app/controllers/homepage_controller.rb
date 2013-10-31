class HomepageController < ApplicationController

  before_filter :save_current_path, :except => :sign_in

  skip_filter :dashboard_only

  def index
    ## Support old /?map=true URL START
    ## This can be removed after March 2014
    if !params[:view] && params[:map] == "true" then
      redirect_params = params.except(:map).merge({view: "map"});
      redirect_to url_for(redirect_params), status: :moved_permanently
    end
    ## Support old /?map=true URL END

    @homepage = true
    
    @view_type = params[:view] || @current_community.default_browse_view || "grid"
    
    listings_per_page = 24
    
    #Load community categories
    @categories =  Rails.cache.fetch("/community/#{@current_community.id}_#{@current_community.updated_at}/categories") {
      @current_community.categories
    } 
    
    @main_categories =  Rails.cache.fetch("/community/#{@current_community.id}_#{@current_community.updated_at}/main_categories") {
      @current_community.main_categories
    }
    @share_types = Rails.cache.fetch("/community/#{@current_community.id}_#{@current_community.updated_at}/share_types") {
      @current_community.share_types
    }
    @listing_types = Rails.cache.fetch("/community/#{@current_community.id}_#{@current_community.updated_at}/listing_types") {
      @current_community.listing_types
    }
    
    @category_menu_enabled = @current_community.categories.size > 1
    
    @filter_params = params.slice("category", "share_type")
    
    # If no Share Type specified, use listing_type if that is specified.
    # both are chosen in one dropdown
    @filter_params["share_type"] ||= @filter_params["listing_type"]
    @filter_params.delete("listing_type")
    
    @listing_count = @current_community.listings.currently_open.count
    unless @current_user
      @private_listing_count = Listing.currently_open.private_to_community(@current_community).count
    end
    
    @filter_params[:search] = params[:q] if params[:q]
    @filter_params[:include] = [:listing_images, :author, :category, :share_type]
      
    @listings = Listing.find_with(@filter_params, @current_user, @current_community, listings_per_page, params[:page])

    @app_store_badge_filename = "/assets/Available_on_the_App_Store_Badge_en_135x40.svg"    
    if File.exists?("app/assets/images/Available_on_the_App_Store_Badge_#{I18n.locale}_135x40.svg")
       @app_store_badge_filename = "/assets/Available_on_the_App_Store_Badge_#{I18n.locale}_135x40.svg"
    end
    
    if request.xhr? # checks if AJAX request
      if params["view"] == "grid" then
        render :partial => "grid_item", :collection => @listings, :as => :listing
      else
        render :partial => "list_item", :collection => @listings, :as => :listing
      end
    else
      if @current_community.news_enabled?
        @news_items = @current_community.news_items.order("created_at DESC").limit(2)
        @news_item_count = @current_community.news_items.count
      end  
    end
  end
end
