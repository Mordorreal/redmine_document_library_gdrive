# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get "/auth/google_oauth2/callback", to:  'gdrives#oauth2callback', as: :oauth2callback
get "#{ENV['RAILS_RELATIVE_URL_ROOT']}/issues/:id/create_workspace", to: 'gdrives#create_workspace', as: :create_workspace
post "#{ENV['RAILS_RELATIVE_URL_ROOT']}/issues/:id/new_google_file", to: 'gdrives#new_google_file', as: :new_google_file
