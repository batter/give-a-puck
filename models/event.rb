class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title
  field :is_live, type: Boolean, default: false

  validates_presence_of :title
  validates_uniqueness_of :title

  has_many :players, inverse_of: :event
  has_many :games, inverse_of: :event
end
