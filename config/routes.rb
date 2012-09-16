Forem::Engine.routes.draw do
  root :to => "forums#index"

  # ME ROUTES
  get 'my_subscriptions', :to => "topics#my_subscriptions"
  get 'my_topics', :to => "topics#my_topics"
  get 'my_posts', :to => "topics#my_posts"

  # NEW ROUTES
  resources :forums, :path => "/" do
    get 'new'
    post 'create'
  end

  resources :topics, :path => "/topics" do
    resources :posts
    member do
      get :subscribe
      get :unsubscribe
    end
  end

  resources :categories

  # REDIRECT OLD ROUTES
  get '/forums/:forum_id/', :to => "redirect#forum"
  get '/forums/:forum_id/topics/:topic_id', :to => "redirect#topic"
  get '/posts/:post_id', :to => "redirect#posts"
  get '/subscriptions', :to => "redirect#subscriptions"

  # MODERATION
  get '/:forum_id/moderation', :to => "moderation#index", :as => :forum_moderator_tools
  put '/:forum_id/moderate/posts', :to => "moderation#posts", :as => :forum_moderate_posts
  put '/:forum_id/topics/:topic_id/moderate', :to => "moderation#topic", :as => :moderate_forum_topic


  # ADMINISTRATION
  namespace :admin, :path => "/admin/forums/" do
    root :to => "base#index"
    resources :groups do
      resources :members
    end

    resources :forums do
      resources :moderators
    end

    resources :categories
    resources :topics do
      member do
        put :toggle_hide
        put :toggle_lock
        put :toggle_pin
      end
    end

    get 'users/autocomplete', :to => "users#autocomplete"
  end
end
