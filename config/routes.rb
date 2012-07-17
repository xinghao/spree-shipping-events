Spree::Core::Engine.routes.draw do
  resources :inventory_shipping_events

  resources :shipping_events

  namespace :admin do
    resources :shipment_manifests do
      put 'commit', :on => :member
    end
  end

  # Add your extension routes here
    
end
