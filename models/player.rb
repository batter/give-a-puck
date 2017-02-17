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

  def self.by_least_games_played
    all.to_a.sort_by { |p| p.games.size }
  end

  # return next players eligible to play based on players that have played least amount of games thus far
  def self.next_up(number = 2, except_player_id = nil, include_player_id = nil)
    players = active.by_least_games_played
    players.reject! { |p| p.id.to_s == except_player_id } if except_player_id
    # Don't toss a player into the pool of if they are already playing
    players.reject! { |p| p.games.unfinished.any? }
    return players if players.size <= number

    groupings = players.group_by { |p| p.games.size }.values
    pool = []
    pool.push(*groupings.shift) until pool.size >= number
    # Add additional element of randomness
    pool.push(*groupings.shift) if Random.rand(3).odd? && groupings.any?
    if include_player_id
      [Player.find(include_player_id), pool.reject {|p| p.id.to_s == include_player_id}.sample]
    else
      pool.sample(number)
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
    lost_games && lost_games.size
  end
  alias_method :games_lost_count, :lost_games_count

  def lost_games
    (games.finished.scored.to_a - won_games)
  end

  def win_pct
    games.finished.size > 0 ? games_won_count / games.finished.size.to_f : 0
  end

  def win_pct_readable
    self.win_pct == 1 ? '1.000' : ('%.3f' % self.win_pct)[1..-1]
  end
end
