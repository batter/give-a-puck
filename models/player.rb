class Player
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :email
  field :active, type: Boolean, default: true

  belongs_to :event, inverse_of: :players
  has_and_belongs_to_many :games, inverse_of: :players
  has_many :won_games, class_name: 'Game', inverse_of: :winner

  validates_presence_of :event, :name
  validates_uniqueness_of :name, scope: :event

  scope :active,   -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :fifteen_mins_old, -> { where(created_at: { :$lt => (-> { 15.minutes.ago }).call }) }

  def self.by_least_games_played
    all.to_a.sort_by { |p| p.games.size }
  end

  # return next players eligible to play based on players that have played least amount of games thus far
  def self.next_up(size = 2, except_player_id = nil, include_player_id = nil)
    players = active.fifteen_mins_old.by_least_games_played
    players.reject! { |p| p.id.to_s == except_player_id.to_s } if except_player_id
    # Don't toss a player into the pool of if they are already playing
    players.reject! { |p| p.games.unfinished.any? }
    # if the player pool is the size of the passed `size` in a game or less, return the whole pool
    return players if players.size <= size
    # if an included player id is passed, 
    player_to_include = players.delete(players.detect { |p| p.id.to_s == include_player_id.to_s }) if include_player_id

    # otherwise generate a new match from the player pool
    generate_player_match(players, size, player_to_include)
  end

  # returns an array of players from the player pool collection
  def self.generate_player_match(player_pool, size, player_to_include)
    # 66% chance that it just selects a random player
    pool =
      if Random.rand(3).even?
        player_pool.sample(size)
      else
        generate_weighted_pool(player_pool, size)
      end

    player_to_include ? [player_to_include, *pool.sample(size - 1)] : pool.sample(size)
  end

  # returns an array of players from the player pool, prioritizing players who have played the least number of games
  def self.generate_weighted_pool(player_pool, size)
    groupings = player_pool.group_by { |p| p.games.size }.values
    [].tap do |pool|
      pool.push(*groupings.shift) until pool.size >= size
      # 33% random chance that it introduces some additional random players who have played a bit more
      pool.push(*groupings.shift) if Random.rand(3).odd? && groupings.any?
    end
  end

  def point_differential
    return 0 unless games.finished.scored.exists?
    total_points_for.to_i - total_points_against.to_i
  end
  alias_method :point_diff, :point_differential

  # Amongst games the player has completed
  def total_points_against
    return 0 unless games.finished.scored.exists?
    won_games.pluck(:lose_score).map(&:to_i).inject(:+).to_i + self.lost_games.pluck(:win_score).inject(:+).to_i
  end

  # Amongst games the player has completed
  def total_points_for
    return 0 unless games.finished.scored.exists?
    won_games.pluck(:win_score).inject(:+).to_i + self.lost_games.pluck(:lose_score).inject(:+).to_i
  end

  def games_won_count
    won_games.size
  end

  def lost_games_count
    lost_games.present? && lost_games.size
  end
  alias_method :games_lost_count, :lost_games_count

  def lost_games
    (Array.wrap(games.finished.scored) - won_games)
  end

  def win_pct
    games.finished.size > 0 ? games_won_count / games.finished.size.to_f : 0
  end

  def win_pct_readable
    self.win_pct == 1 ? '1.000' : ('%.3f' % self.win_pct)[1..-1]
  end
end
