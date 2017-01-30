class Game
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :finished, type: Boolean, default: false
  field :win_score,  type: Integer
  field :lose_score, type: Integer

  validates_presence_of :name

  belongs_to :event, inverse_of: :games
  has_and_belongs_to_many :players, inverse_of: :games
  belongs_to :winner, class_name: 'Player', inverse_of: :won_games

  scope :unfinished, -> { where(finished: false) }
  scope :finished,   -> { where(finished: true) }

  def set_winner!(player, win_score, lose_score)
    self.winner = player
    self.win_score = win_score
    self.lose_score = lose_score
    save!
  end
end
