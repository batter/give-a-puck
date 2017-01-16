class Game
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :finished, type: Boolean, default: false

  validates_presence_of :name

  belongs_to :event
  has_and_belongs_to_many :players

  scope :unfinished, -> { where(finished: false) }
  scope :finished,   -> { where(finished: true) }
end
