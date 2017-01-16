class Player
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name

  has_and_belongs_to_many :games

  validates_presence_of :name
end
