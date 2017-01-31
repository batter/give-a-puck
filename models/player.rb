class Player
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :email

  belongs_to :event, inverse_of: :players
  has_and_belongs_to_many :games, inverse_of: :players
  has_many :won_games, class_name: 'Game', inverse_of: :winner

  validates_presence_of :event, :name
  validates_uniqueness_of :name, scope: :event

  def games_won_count
    won_games.size
  end

  def games_lost_count
    (games.finished.to_a - won_games).size
  end

  def win_pct
    games.finished.size > 0 ? games_won_count / games.finished.size.to_f : 0
  end
end
