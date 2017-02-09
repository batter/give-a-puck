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
  def self.next_up(number = 2, except_player_id = nil)
    players = active.by_least_games_played
    players.reject! { |p| p.id.to_s == except_player_id } if except_player_id
    return players if players.size <= number

    groupings = players.group_by { |p| p.games.size }.values
    pool = []
    pool.push(*groupings.shift) until pool.size >= number
    pool.sample(number)
  end

  def games_won_count
    won_games.size
  end

  def games_lost_count
    (games.finished.scored.to_a - won_games).size
  end

  def win_pct
    games.finished.size > 0 && games_won_count > 0 ? games_won_count / games.finished.size.to_f : 0
  end

  def win_pct_readable
    ('%.3f' % self.win_pct)[1..-1]
  end
end
