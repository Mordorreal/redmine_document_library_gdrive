class GdrivesController < ApplicationController
  unloadable

  def oauth2callback
    @gdrive = Gdrive.all.first || Gdrive.new
    @gdrive.access_token = request.env["omniauth.auth"]
    @gdrive.save
    @gdrive.clear_db
    redirect_to "#{ENV['RAILS_RELATIVE_URL_ROOT']}/admin/plugins"
  end

  def create_workspace
    @issue = Issue.find params[:id]
    @issue.create_workspace
    redirect_to @issue
  end

  def new_google_file
    @issue = Issue.find params[:id]
    if params[:google_file][:upload_file]
      @issue.upload_file(params[:google_file][:upload_file][0])
    else
      @issue.new_file(params[:google_file][:file_title], params[:google_file][:file_type])
    end
    redirect_to @issue
  end

end
