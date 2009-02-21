class CampaignsController < ApplicationController
  before_filter :require_user
  before_filter :get_data_for_sidebar, :only => :index
  before_filter "set_current_tab(:campaigns)", :except => [ :new, :create, :destroy, :filter ]

  # GET /campaigns
  # GET /campaigns.xml
  #----------------------------------------------------------------------------
  def index
    unless session[:filter_by_campaign_status]
      @campaigns = Campaign.my(@current_user)
    else
      @campaigns = Campaign.my(@current_user).only(session[:filter_by_campaign_status].split(","))
    end

    # If [Create Campaign] form is visible get the data to render it.
    make_new_campaign if session["create_campaign"]

    respond_to do |format|
      format.html # index.html.haml
      format.xml  { render :xml => @campaigns }
    end
  end

  # GET /campaigns/1
  # GET /campaigns/1.xml
  #----------------------------------------------------------------------------
  def show
    @campaign = Campaign.find(params[:id])
    @comment = Comment.new

    respond_to do |format|
      format.html # show.html.haml
      format.xml  { render :xml => @campaign }
    end
  end

  # GET /campaigns/new
  # GET /campaigns/new.xml                                                 AJAX
  #----------------------------------------------------------------------------
  def new
    make_new_campaign

    # Save [Create Campaign] visiblity for given context.
    @context = (params[:context].blank? ? "create_campaign" : params[:context])
    session[@context] = (params[:visible] == "true" ? nil : true)

    respond_to do |format|
      format.js   # new.js.rjs
      format.html # new.html.haml
      format.xml  { render :xml => @campaign }
    end
  end

  # GET /campaigns/1/edit
  #----------------------------------------------------------------------------
  def edit
    @campaign = Campaign.find(params[:id])
  end

  # POST /campaigns
  # POST /campaigns.xml                                                    AJAX
  #----------------------------------------------------------------------------
  def create
    @campaign = Campaign.new(params[:campaign])
    @users = User.all_except(@current_user)
    @context = (params[:context].blank? ? "create_campaign" : params[:context])

    respond_to do |format|
      if @campaign.save_with_permissions(params[:users])
        session[@context] = nil
        format.js   # create.js.rjs
        format.html { redirect_to(@campaign) }
        format.xml  { render :xml => @campaign, :status => :created, :location => @campaign }
      else
        format.js   # create.js.rjs
        format.html { render :action => "new" }
        format.xml  { render :xml => @campaign.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /campaigns/1
  # PUT /campaigns/1.xml
  #----------------------------------------------------------------------------
  def update
    @campaign = Campaign.find(params[:id])

    respond_to do |format|
      if @campaign.update_attributes(params[:campaign])
        flash[:notice] = 'Campaign was successfully updated.'
        format.html { redirect_to(@campaign) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @campaign.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /campaigns/1
  # DELETE /campaigns/1.xml                                                AJAX
  #----------------------------------------------------------------------------
  def destroy
    @campaign = Campaign.find(params[:id])
    @campaign.destroy

    respond_to do |format|
      format.js   { get_data_for_sidebar; render }
      format.html { redirect_to(campaigns_url) }
      format.xml  { head :ok }
    end
  end

  # Ajax request to filter out list of campaigns.                          AJAX
  #----------------------------------------------------------------------------
  def filter
    session[:filter_by_campaign_status] = params[:status]
    @campaigns = Campaign.my(@current_user).only(params[:status].split(","))

    render :update do |page|
      page[:campaigns].replace_html render(:partial => "campaign", :collection => @campaigns)
    end
  end

  #----------------------------------------------------------------------------
  def get_data_for_sidebar
    @campaign_status_total = { :all => Campaign.my(@current_user).count, :other => 0 }
    Setting.campaign_status.keys.each do |key|
      @campaign_status_total[key] = Campaign.my(@current_user).count(:conditions => [ "status=?", key.to_s ])
      @campaign_status_total[:other] -= @campaign_status_total[key]
    end
    @campaign_status_total[:other] += @campaign_status_total[:all]
  end

end
