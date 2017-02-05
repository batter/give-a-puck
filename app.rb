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
  plugin :assets, css: 'application.css', js: ['application.js', 'jquery_ujs.js'],
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
    response.headers['Cache-Control'] = 'no-cache' unless env.production?
  end

  route do |r|
    r.assets unless env.production?

    # GET /
    r.root do
      if @event = Event.where(is_live: true).first
        view '/events/show'
      else
        flash[:notice] = 'There is not currently a live event'
        r.redirect '/events'
      end
    end

    r.on 'events' do
      r.is do
        r.get do
          @events = Event.all
          view 'events/index'
        end

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
            @players = @event.players.sort_by { |p| p.win_pct }
            view 'events/show'
          end
        end

        r.post 'make_live' do
          @event.make_live!
          r.redirect "/events/#{@event.id}"
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
                view 'players/edit'
              end
            end
          end

          r.on ':id' do |player_id|
            @player = @event.players.find(player_id)

            r.is do
              r.get do
                view 'players/edit'
              end

              r.post do
                if @player.update_attributes(params[:player])
                  flash['success'] = "Player #{@player.name} Updated"
                  r.redirect "/events/#{@event.id}"
                else
                  flash.now['error'] = @player.errors.full_messages.join(', ')
                  view 'players/edit'
                end
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
