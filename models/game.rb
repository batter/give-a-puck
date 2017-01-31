class Game
  include Mongoid::Document
  include Mongoid::Timestamps

  # field :finished, type: Boolean, default: false
  field :win_score,  type: Integer
  field :lose_score, type: Integer
  field :end_time, type: Time

  belongs_to :event, inverse_of: :games
  has_and_belongs_to_many :players, inverse_of: :games
  belongs_to :winner, class_name: 'Player', inverse_of: :won_games, required: false

  validates_presence_of :event, :players
  validates_length_of :players, is: 2
  validate :players_must_belong_to_event

  # scope :unfinished, -> { where(finished: false) }
  # scope :finished,   -> { where(finished: true) }

  scope :finished,   -> { where(:end_time.lte => Time.now) }
  scope :unfinished, -> { where(:end_time.gte => Time.now) }

  before_create { self.end_time = created_at + 5.minutes }

  def set_winner!(player, win_score, lose_score)
    self.winner = player
    self.win_score = win_score
    self.lose_score = lose_score
    save!
  end

  protected

  def players_must_belong_to_event
    unless players.all? { |player| player.event_id == event_id }
      errors.add(:players, 'must be part of the same event as this game')
    end
  end
end
