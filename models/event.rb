class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title
  field :is_live, type: Boolean, default: false

  has_many :players, inverse_of: :event
  has_many :games, inverse_of: :event

  validates_presence_of :title
  validates_uniqueness_of :title
end
