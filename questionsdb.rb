
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  def self.find_by_id(id)
    user_data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?;
    SQL
    self.new(user_data)
  end

  def initialize(user_data)
    @id = user_data['id']
    @fname = user_data['fname']
    @lname = user_data['lname']
  end

  def self.find_by_name(fname, lname)

  end

end
