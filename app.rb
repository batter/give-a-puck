require 'roda'
require 'rack/indifferent'
require 'haml'

require File.expand_path('../models/all', __FILE__)

class App < Roda
  use Rack::Session::Cookie, secret: ENV['SECRET'] || 'Et facilis Qui sin'

  plugin :hooks
  plugin :render, engine: 'haml'
  plugin :json
  plugin :flash
  plugin :indifferent_params
  plugin :all_verbs
  plugin :assets, css: 'application.css', js: 'application.js',
    js_compressor: :uglifier

  def self.root
    @@root ||= Pathname.new(File.dirname(__FILE__))
  end

  def self.env
    @@env ||= ActiveSupport::StringInquirer.new(ENV['RACK_ENV'])
  end

  def env
    self.class.env
  end

  # before hook runs before every request execution
  before do
    @payload = JSON.parse(request.env['rack.input'].read) rescue nil
    response.headers['Cache-Control'] = 'no-cache' unless env.production?
  end

  route do |r|
    r.assets unless env.production?

    # GET /
    r.root do
      @events = Event.all
      view :index
    end

    r.on 'events' do
      r.is do
        r.post do
          @event = Event.new(params[:event])
          if @event.save
            flash['success'] = 'Event Created'
            r.redirect '/'
          else
            flash.now['error'] = @event.errors.full_messages.join(', ')
            view 'events/new'
          end
        end
      end

      r.get 'new' do
        view 'events/new'
      end

      r.on ':id' do |event_id|
        @event = Event.find(event_id)

        r.is do
          r.get do
            view 'events/show'
          end
        end

        r.on 'players' do
          r.is do
            r.post do
              @player = @event.players.new(params[:player])
              if @player.save
                flash['success'] = "Player #{@player.name} Created"
                r.redirect "/events/#{@event.id}"
              else
                flash.now['error'] = @player.errors.full_messages.join(', ')
                view 'players/new'
              end
            end
          end

          r.get 'new' do
            view 'players/new'
          end
        end
      end
    end
  end
end
