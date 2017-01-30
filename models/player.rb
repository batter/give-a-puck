class Player
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :event

  belongs_to :event, inverse_of: :players
  has_and_belongs_to_many :games, inverse_of: :players
  has_many :won_games, class_name: 'Game', inverse_of: :winner
end
