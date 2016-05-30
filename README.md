# redmine_document_library_gdrive
Redmine plugin that add option to Redmine to store any files in issues in Gdrive. You can restrict access per tracker. You need only one Gdrive account and you can manage access to files from Gdrive interface.

## Installing a plugin
1. Copy plugin directory into `RAILS_ROOT/plugins`. If you are downloading the plugin directly from GitHub, you can do so by changing into your plugin directory and issuing a command 
`git clone https://github.com/Mordorreal/redmine_document_library_gdrive`

2. Run the following command in `RAILS_ROOT` to upgrade your database (make a db backup before).
`rake redmine:plugins:migrate RAILS_ENV=production`

3. Restart Redmine
You should now be able to see the plugin list in Administration -> Plugins and configure installed plugin.

4. Create Google Project in https://console.developers.google.com and add http://yourredmine.com/auth/google_oauth2/callback and https://yourredmine.com/auth/google_oauth2/callback as callbacks.

5. Enable GDrive and Google+ API in Google Developer Console for your project.

6. Type GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET as ENV with data from Google Project.

## Uninstalling a plugin
1. Run the following command to downgrade your database (make a db backup before):
`rake redmine:plugins:migrate NAME=plugin_name VERSION=0 RAILS_ENV=production`

2. Remove your plugin from the plugins folder: `RAILS_ROOT/plugins`

3. Restart Redmine
