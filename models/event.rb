class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title

  validates_presence_of :title
  validates_uniqueness_of :title

  has_many :players
  has_many :games
end
