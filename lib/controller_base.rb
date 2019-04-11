require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res)
    @res = res
    @req = req
    @already_built_response = false
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise 'Error double render' if already_built_response?
    @already_built_response = true
    @res.status = 302
    @res.location = url
    @session.store_session(@res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise 'Error double render' if already_built_response?
    @already_built_response = true
    @res['Content-Type'] = content_type
    @res.write(content)
    @session.store_session(@res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    raise 'Error double render' if already_built_response?
    @already_built_response = true
    controller_name = ActiveSupport::Inflector.underscore(self.class.to_s)
    path = "views/#{controller_name}/#{template_name}.html.erb"
    erb_content = File.read(path)
    content = ERB.new(erb_content).result(binding)
    @res['Content-Type'] = "text/html"
    @res.write(content)
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
  end
end

