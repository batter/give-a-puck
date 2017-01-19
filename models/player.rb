class Player
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :event

  belongs_to :event
  has_and_belongs_to_many :games
end
