class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  validates :username, :presence => true, :uniqueness => { :case_sensitive => false }
  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, :multiline => true


  def login=(login)
    @login = login
  end

  def login
    @login || self.username || self.email
  end

  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["username = :value OR email = :value", { :value => login.downcase }]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end

  def to_s
    self.username
  end

  has_many :template
  has_many :meme
  has_many :votes
  has_many :comments, dependent: :destroy
end
