require 'roda'
require 'rack/indifferent'
require 'haml'

require File.expand_path('../models/all', __FILE__)

class App < Roda
  use Rack::Session::Cookie, secret: ENV['SECRET'] || 'Et facilis Qui sin'

  plugin :hooks
  plugin :render, engine: 'haml'
  plugin :flash
  plugin :indifferent_params
  plugin :all_verbs
  plugin :partials
  plugin :public
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

  if env.production?
    compile_assets

    require File.expand_path('../config/rollbar', __FILE__)
    use Rollbar::Middleware::Rack
  end

  # before hook runs before every request execution
  before do
    response.headers['Cache-Control'] = 'no-cache' unless env.production?
  end

  route do |r|
    r.public
    r.assets unless env.production?

    # GET /
    r.root do
      if @event = Event.where(is_live: true).first
        @page_refresh = 10 # number of seconds
        @players = @event.players.sort_by(&:win_pct).reverse
        view '/events/show'
      else
        flash[:notice] = 'There is not currently a live event'
        r.redirect '/events'
      end
    end

    # /events
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

      # GET /events/new
      r.get 'new' do
        view 'events/new'
      end

      # /events/:id
      r.on ':id' do |event_id|
        @event = Event.find(event_id)

        r.is do
          r.get do
            @page_refresh = 10 # number of seconds
            @players = @event.players.sort_by(&:win_pct).reverse
            view 'events/show'
          end
        end

        # /events/:id/make_live
        r.post 'make_live' do
          @event.make_live!
          r.redirect "/events/#{@event.id}"
        end

        # /events/:id/live_games
        r.get 'live_games' do
          @page_refresh = 20 # number of seconds
          @event.assign_next_on_deck! unless @event.on_deck_player_ids.present?
          @proposed_game = @event.games.new(players: Player.find(@event.on_deck_player_ids))
          @current_games = Game.unscored.order_by(created_at: :desc)
          view 'events/live_games'
        end

        # /events/:id/generate_match_without/:player_id
        # used for kicking a player out of the next proposed game (since player is not available)
        r.post 'generate_match_without/:player_id' do |player_id|
          @event.assign_next_on_deck!(player_id)
          flash['success'] = 'Player kicked from game; new match proposed'
          r.redirect "/events/#{@event.id}/live_games"
        end

        # /events/:id/create_next_game
        # creates the proposed match on the event into a legitimate game, generates next match
        r.post 'create_next_game' do
          @event.create_next_game!
          r.redirect "/events/#{@event.id}/live_games"
        end

        # /events/:id/games
        r.on 'games' do
          # /events/:id/games/:game_id
          r.on ':id' do |game_id|
            @game = @event.games.find(game_id)

            r.is do
              r.post do
                if params[:scoreboard_submit]
                  if params[:game][:player_1_score].present? && params[:game][:player_2_score].present?
                    score1 = params[:game][:player_1_score].to_i
                    score2 = params[:game][:player_2_score].to_i
                    winner_id = score1 > score2 ? params[:game][:player_1_id] : params[:game][:player_2_id]
                    @game.update_attributes!(
                      win_score: [score1, score2].max, lose_score: [score1, score2].min, winner_id: winner_id
                    )
                    flash[:success] = 'Game score entered successfully'
                    r.redirect "/events/#{@event.id}/live_games"
                  else
                    flash[:error] = 'Please enter a score for both players'
                    r.redirect "/events/#{@event.id}/live_games"
                  end
                else
                  flash[:error] = 'Games must be updated from the live games page'
                  r.redirect "/events/#{@event.id}"
                end
              end
            end

            # /events/:id/games/:game_id/finalize_early
            r.post 'finalize_early' do
              @game.touch(:end_time)
              r.redirect "/events/#{@event.id}/live_games"
            end
          end
        end

        # /events/:id/players
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

          # /events/:id/players/new
          r.get 'new' do
            view 'players/new'
          end

          # /events/:id/players/:id
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

            # /events/:id/players/:id/toggle_active_state
            r.post 'toggle_active_state' do
              @player.update_attribute(:active, !@player.active?)
              r.redirect "/events/#{@event.id}"
            end
          end
        end
      end
    end
  end
end
