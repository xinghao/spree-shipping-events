Spree::Core::Engine.routes.draw do
  resources :inventory_shipping_events

  resources :shipping_events

  # Add your extension routes here
end
