require 'google/api_client'
require 'rest-client'

class Gdrive < ActiveRecord::Base

  unloadable

  GOOGLE_CLIENT_ID = ENV['GOOGLE_CLIENT_ID']
  GOOGLE_SECRET = ENV['GOOGLE_CLIENT_SECRET']
  APP_NAME = 'Redmine'
  APP_VERSION = '0.0.1'
  SCOPES = %w(https://www.googleapis.com/auth/drive.file email profile)

  serialize :access_token, Hash

  # create connection with Gdrive
  def connect
    @client ||= Google::APIClient.new application_name: APP_NAME, application_version: APP_VERSION
    refresh_token!
    @client.authorization.access_token = self.access_token[:credentials][:token]
    @drive ||= @client.discovered_api 'drive', 'v2'
  end
  # refresh token
  def refresh_token!
    data = {
        :client_id => GOOGLE_CLIENT_ID,
        :client_secret => GOOGLE_SECRET,
        :refresh_token => self.access_token[:credentials][:refresh_token],
        :grant_type => 'refresh_token'
    }
    response = ActiveSupport::JSON.decode(RestClient.post "https://accounts.google.com/o/oauth2/token", data)
    if response["access_token"].present?
      self.access_token[:credentials][:token] = response["access_token"]
      self.save
    else
      # No Token
    end
  rescue RestClient::BadRequest => e
    # Bad request
  rescue
    # Something else bad happened
  end
  # check if main folder deleted
  def check_main_folder!
    root_folder = self.get_file(self.app_folder_id)
    if root_folder && root_folder['labels']['trashed']
      root_folder = nil
    end
    unless root_folder
      self.app_folder_id = create_folder APP_NAME, 'root'
      self.save
    end
  end
  # create application folder on gdrive if not existing. return folder id
  def application_root_folder
    self.app_folder_id || check_main_folder!
  end
  # create folder with google api
  def create_item(name, parent, mime_type)
    connect unless @client
    parent = '' unless parent
    file = @drive.files.insert.request_schema.new({
                                                      'title' => name,
                                                      'mimeType'=> mime_type,
                                                      'parents'=> [{ 'id' => parent}]
                                                  })
    result = @client.execute(
        :api_method => @drive.files.insert,
        :body_object => file)
    response_body = JSON.parse result.response.body
    response_body['id']
  end
  # create empty file link
  def create_file_link(title, parent = nil)
    create_item title, parent, 'application/vnd.google-apps.drive-sdk'
  end
  # Create new spreadsheet
  def create_file_spreadsheet(title, parent = nil)
    create_item title, parent, 'application/vnd.google-apps.spreadsheet'
  end
  # Create doc file
  def create_file_doc(title, parent = nil)
    create_item title, parent, 'application/vnd.google-apps.document'
  end
  # Create presentation file
  def create_file_presentation(title, parent = nil)
    create_item title, parent, 'application/vnd.google-apps.presentation'
  end
  # Create new folder
  def create_folder(title, parent = nil)
    create_item title, parent, 'application/vnd.google-apps.folder'
  end
  # delete file
  def delete_file(file_id)
    connect unless @client
    result = @client.execute(
        :api_method => @drive.files.delete,
        :parameters => { 'fileId' => file_id })
  end
  # upload file to gdrive
  def upload_file(title, mime_type, media, parent = nil)
    connect unless @client
    file = @drive.files.insert.request_schema.new({
                                                      'title' => title,
                                                      'mimeType' => mime_type,
                                                      'parents' => [{ 'id' => parent}]
                                                  })
    result = @client.execute(
        api_method: @drive.files.insert,
        body_object: file,
        media: media,
        parameters: {
            'uploadType' => 'multipart',
            'alt' => 'json'
        })
    if result.status == 200
      response_body = JSON.parse result.response.body
      return response_body['id']
    end
    nil
  end
  # find file by title. return array with results. [0]['id'] get file id
  def find_by_title_name(title)
    connect unless @client
    result = @client.execute(
        api_method: @drive.files.list,
        parameters: {'q' => "title = '#{ title }'" })
    if result.status == 200
      response_body = JSON.parse result.response.body
      response_body['items']
    end
  end
  # find file by parents id. return array with results. [0]['id'] get file id
  def find_by_parents_id(parents_id)
    connect unless @client
    result = @client.execute(
        api_method: @drive.files.list,
        parameters: {'q' => "'#{ parents_id }' in parents" })
    if result.status == 200
      response_body = JSON.parse result.response.body
      response_body['items']
    end
  end
  # get file by id
  def get_file(file_id)
    return if file_id.nil? || file_id == ''
    connect unless @client
    result = @client.execute(
        api_method: @drive.files.get,
        parameters: { 'fileId' => file_id })
    if result.status == 200
      JSON.parse result.response.body
    end
  end
  # get file title by id and return array [title, link to icon]
  def get_file_title(file_id)
    return if file_id.nil? || file_id == ''
    connect unless @client
    result = @client.execute(
        api_method: @drive.files.get,
        parameters: { 'fileId' => file_id })
    if result.status == 200
      body = JSON.parse result.response.body
      [body['title'], body['iconLink']]
    end
  end
  # move file in gdrive @get arrays
  def move_file(file_id, parents_package_id)
    connect unless @client
    clear_parents file_id
    pac = Package.where( id: parents_package_id)
    pac.each do |package|
      new_parent = @drive.parents.insert.request_schema.new({'id' => package.package_id_gdrive })
      @client.execute(
          api_method: @drive.parents.insert,
          body_object: new_parent,
          parameters: { 'fileId' => file_id })
    end
  end
  # copy file in gdrive @get string
  def copy_file(file_id, folder_id)
    connect unless @client
    new_parent = @drive.parents.insert.request_schema.new({'id' => folder_id })
    @client.execute(
        api_method: @drive.parents.insert,
        body_object: new_parent,
        parameters: { 'fileId' => file_id })
  end
  # clear all parents return file if all ok
  def clear_parents(file_id)
    connect unless @client
    result = @client.execute(
        api_method: @drive.parents.list,
        parameters: { 'fileId' => file_id })
    if result.status == 200
      parents_id = result.data
      parents_id.items.each do |parent_id|
        @client.execute(
            api_method: @drive.parents.delete,
            parameters: { 'fileId' => file_id,
                          'parentId' => parent_id['id'] })
      end
    end
  end
  # Move files @get { file_id: (id: google_file_id, parents: 'parents1, parents2') }
  def move_files(data)
    data.each do |file|
      move_file file[:id], file[:parents]
    end
  end
  # set permission to share to anyone with link
  def set_permission_open(folder_id)
    connect unless @client
    new_permission = @drive.permissions.insert.request_schema.new({
                                                                      'withLink' => true,
                                                                      'type' => 'anyone',
                                                                      'role' => 'writer'
                                                                  })
    result = @client.execute(
        api_method: @drive.permissions.insert,
        body_object: new_permission,
        parameters: { 'fileId' => folder_id })
    if result.status == 200
      result.data
    end
  end
  # set permission to share to anyone with link
  def set_permission_close(folder_id)
    connect unless @client
    new_permission = @drive.permissions.insert.request_schema.new({
                                                                      'withLink' => true,
                                                                      'type' => 'default',
                                                                      'role' => 'owner'
                                                                  })
    result = @client.execute(
        api_method: @drive.permissions.insert,
        body_object: new_permission,
        parameters: { 'fileId' => folder_id })
    if result.status == 200
      result.data
    end
  end
  # get children gdrive id in folder
  def get_children(folder_id)
    connect unless @client
    result = @client.execute(
        api_method: @drive.children.list,
        parameters: { 'folderId' => folder_id })
    if result.status == 200
      children = result.data
      children_ids = []
      children.items.each do |child|
        children_ids << child.id
      end
      children_ids
    end
  end
  # remove children from folder
  def remove_children(folder_id, child_id)
    connect unless @client
    result = @client.execute(
        api_method: @drive.children.delete,
        parameters: {
            'folderId' => folder_id,
            'childId' => child_id })
    result.status
  end
  # get link to file in gdrive
  def download_link(folder_id)
    "https://drive.google.com/open?id=#{folder_id}".html_safe
  end
  # clear redmine db
  def clear_db
    Issue.where.not(gdrive_id: '').each do|issue|
      issue.gdrive_id = nil
      issue.save
    end
    Attachment.where.not(gdrive_id: '').each do|attachment|
      attachment.gdrive_id = nil
      attachment.save
    end
    Project.where.not(gdrive_id: '').each do |project|
      project.gdrive_id = nil
      project.save
    end
    self.app_folder_id = nil
    self.save
  end
end

