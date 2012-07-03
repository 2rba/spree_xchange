Spree::Core::Engine.routes.draw do
  # Add your extension routes here
  match '/1c_exchange.php' => 'exchange1c#main'
  match '/test' => 'exchange1c#test'

end
