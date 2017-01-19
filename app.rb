require 'roda'
require 'rack/indifferent'
require 'haml'

require File.expand_path('../models/all', __FILE__)

class App < Roda
  plugin :hooks
  plugin :render, engine: 'haml'
  plugin :json
  plugin :flash
  plugin :assets, css: 'application.css', js: 'application.js',
    js_compressor: :uglifier

  def self.root
    @@root ||= Pathname.new(File.dirname(__FILE__))
  end

  # before hook runs before every request execution
  before do
    @payload = JSON.parse(request.env['rack.input'].read) rescue nil
  end

  route do |r|
    r.assets unless ENV['RACK_ENV'] == 'production'

    # GET /
    r.root do
      @events = Event.all
      view :index
    end

    r.on :events do
      r.is do
        r.post do
          @event = Event.new(params[:event])
          if @event.save
            flash['success'] = 'Event Created'
          else
            view 'events/new'
          end
        end
      end

      r.get :new do
        view 'events/new'
      end
    end
  end
end
