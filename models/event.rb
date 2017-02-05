class Event
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title
  field :is_live, type: Boolean, default: false
  field :on_deck_player_ids, type: Array

  has_many :players, inverse_of: :event
  has_many :games, inverse_of: :event

  validates_presence_of :title
  validates_uniqueness_of :title

  def make_live!
    self.class.where(is_live: true).update_all(is_live: false)
    self.update_attribute(:is_live, true)
  end

  def create_next_game!
    game = games.create!(players: Player.find(on_deck_player_ids))
    self.assign_next_on_deck!
    game
  end

  def assign_next_on_deck!
    update!(on_deck_player_ids: next_matching_players.pluck(:id))
  end

  # generate a match from the player pool
  def next_matching_players
    players(true).next_up
  end
end
