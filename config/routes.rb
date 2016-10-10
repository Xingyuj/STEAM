Rails.application.routes.draw do

  root to: 'dashing#dashboard'
  get 'dashing/dashboard'
  get 'billing_sites/:id/predictions' => 'billing_sites#show_predict_usage', as: :show_predictions_billing_site
  get 'billing_sites/:id/usage' => 'billing_sites#show_usage', as: :show_usage_billing_site
  post 'billing_sites/:id/usage' => 'billing_sites#show_usage'
  resources :ftp_servers


  # nested resources for testing purpose
  scope shallow_prefix: "billing_site" do
    resources :billing_sites do
      resources :retail_plans, shallow: true
    end
  end

#  resources :billing_sites

  resources :sites
  devise_for :users, controllers: { registrations: "users/registrations" }
  get 'users/import' => 'users#upload_nem12'
  post 'users/import' => 'users#import_nem12'
  # user's show page
  get 'users/:id' => 'users#show', as: 'user', constraints: { id: /\d+/ }

  # resources :users, only: [:show],
  get 'users/profile' => 'users#show'

  resources :meters, except: [:new, :index, :show, :edit]

  # If no route matches for show, index, edit page
  get '/meters' => 'application#redirect_user'
  get '/meters/:id' => 'application#redirect_user'
  get '/meters/:id/edit' => 'application#redirect_user'

  # resources :retail_plans do
  #   collection do
  #     get :edit
  #   end
  # end

  resources :invoices do
    collection do
      get :predictNew
      post :select_date_period
      post :predict, to: "invoices#create_predicted_invoice"
      get :generateNew
      post :generate, to: "invoices#create_generated_invoice"
      get :import_invoice
      post :import, to: "invoices#create_imported_invoice"
      post :compare
    end
  end

  get 'meter_records/truncate' => 'meter_records#truncate'
  get 'meter_records/import' => 'meter_records#import_nem12'
  get 'meter_records/single_usage' => 'meter_records#single_usage'
  get 'meter_records/multiple_usage' => 'meter_records#multiple_usage'
  get 'meter_records/single_predicted_usage' => 'meter_records#single_predicted_usage'
  get 'meter_records/multiple_predicted_usage' => 'meter_records#multiple_predicted_usage'

  get 'meter_aggregations/truncate' => 'meter_aggregations#truncate'

  resources :meter_records, :meter_aggregations

  # duplicated resources
  # resources :meters

  post '/billing_sites/:id' => 'billing_sites#show'

end
