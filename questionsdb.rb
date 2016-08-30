
require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :id, :fname, :lname

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?;
    SQL
    return nil if data.empty?

    self.new(data.first)
  end

  def self.find_by_name(fname, lname)
    data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      fname = ? AND lname = ?;
    SQL
    return nil if data.empty?

    self.new(data.first)
  end

  def initialize(data)
    @id = data['id']
    @fname = data['fname']
    @lname = data['lname']
  end

  def authored_questions
    Question.find_by_author_id(id)
  end

  def authored_replies
    Reply.find_by_user_id(id)
  end

  def followed_questions
    QuestionFollow.followed_questions_for_user_id(id)
  end

  def liked_questions
    QuestionLike.liked_question_for_user_id(id)
  end

  def average_karma
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        COUNT(question_likes.id) / CAST(COUNT(DISTINCT u_q.id) AS FLOAT)
      FROM
        (SELECT * FROM questions WHERE author_id = ?) u_q
      LEFT OUTER JOIN
        question_likes ON question_likes.question_id = u_q.id
    SQL

    data.first.values.first
  end

  def save
    unless @id
      QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
        INSERT INTO
          users (fname, lname)
        VALUES
          (?, ?);
      SQL

      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, fname, lname, id)
        UPDATE
          users
        SET
          fname = ?, lname = ?
        WHERE
          id = ?;
      SQL
    end
  end

end

class Question
  attr_accessor :id, :title, :body, :author_id

  def self.find_by_author_id(author_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?;
    SQL
    return nil if data.empty?

    data.map { |datum| self.new(datum) }
  end

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?;
    SQL
    return nil if data.empty?

    self.new(data.first)
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def initialize(data)
    @id = data['id']
    @title = data['title']
    @body = data['body']
    @author_id = data['author_id']
  end

  def author
    User.find_by_id(author_id)
  end

  def replies
    Reply.find_by_question_id(id)
  end

  def followers
    QuestionFollow.followers_for_question_id(id)
  end

  def likers
    QuestionLike.likers_for_question_id(id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(id)
  end

  def save
    unless @id
      QuestionsDatabase.instance.execute(<<-SQL, title, body, author_id)
        INSERT INTO
          questions (title, body, author_id)
        VALUES
          (?, ?, ?);
      SQL

      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance.execute(<<-SQL, title, body, author_id, id)
        UPDATE
          questions
        SET
          title = ?, body = ?, author_id = ?
        WHERE
          id = ?;
      SQL
    end
  end

end

class Reply

  attr_accessor :id, :user_id, :question_id, :parent_reply_id, :body

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?;
    SQL
    return nil if data.empty?

    self.new(data.first)
  end

  def self.find_by_user_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?;
    SQL
    return nil if data.empty?

    data.map { |datum| self.new(datum) }
  end

  def self.find_by_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?;
    SQL
    return nil if data.empty?
    data.map { |datum| self.new(datum) }
  end

  def initialize(data)
    @id = data['id']
    @user_id = data['user_id']
    @question_id = data['question_id']
    @parent_reply_id = data['parent_reply_id']
    @body = data['body']
  end

  def author
    User.find_by_id(user_id)
  end

  def question
    Question.find_by_id(question_id)
  end

  def parent_reply
    Reply.find_by_id(parent_reply_id)
  end

  def child_replies
    children = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_reply_id = ?;
    SQL
    return nil if children.empty?

    children.map { |child| Reply.new(child) }
  end

  def save
    unless id
      QuestionsDatabase.instance
        .execute(<<-SQL, user_id, question_id, parent_reply_id, body)
        INSERT INTO
          replies (user_id, question_id, parent_reply_id, body)
        VALUES
          (?, ?, ?, ?);
      SQL

      @id = QuestionsDatabase.instance.last_insert_row_id
    else
      QuestionsDatabase.instance
        .execute(<<-SQL, user_id, question_id, parent_reply_id, body, id)
        UPDATE
          replies
        SET
          user_id = ?, question_id = ?, parent_reply_id = ?, body = ?
        WHERE
          id = ?;
      SQL
    end
  end

end

class QuestionFollow
  attr_accessor :id, :user_id, :question_id

  def self.find_by_id(id)
    data = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?;
    SQL
    return nil if data.empty?

    self.new(data.first)
  end

  def self.followers_for_question_id(question_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.*
      FROM
        users
      JOIN
        question_follows
        ON question_follows.user_id = users.id
      WHERE
        question_id = ?;
    SQL
    return nil if data.empty?

    data.map { |datum| User.new(datum) }
  end

  def self.followed_questions_for_user_id(user_id)
    data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.*
      FROM
        questions
      JOIN
        question_follows
        ON question_follows.question_id = questions.id
      WHERE
        user_id = ?;
    SQL
    return nil if data.empty?

    data.map { |datum| Question.new(datum) }
  end

  def self.most_followed_questions(n)
    data = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        questions.*
      FROM
        questions
      JOIN
        question_follows
        ON question_follows.question_id = questions.id
      GROUP BY
        questions.id
      ORDER BY
        COUNT(question_follows.id) DESC
      LIMIT
        ?;
    SQL
    return nil if data.empty?

    data.map { |datum| Question.new(datum) }
  end

  def initialize(data)
    @id = data['id']
    @user_id = data['user_id']
    @question_id = data['question_id']
  end
end

class QuestionLike
  attr_accessor :id, :user_id, :question_id

    def self.find_by_id(id)
      data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
          *
        FROM
          question_likes
        WHERE
          id = ?;
      SQL
      return nil if data.empty?

      self.new(data.first)
    end

    def self.likers_for_question_id(question_id)
      data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
          users.*
        FROM
          users
        JOIN
          questions_likes ON questions_likes.user_id = users.id
        WHERE
          question_id = ?
      SQL
      return nil if data.empty?
      data.map { |datum| User.new(datum) }
    end

    def self.num_likes_for_question_id(question_id)
      data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
          COUNT(*)
        FROM
          questions_likes
        WHERE
          question_id = ?;
      SQL

      data.first
    end

    def self.liked_question_for_user_id(user_id)
      data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
          questions.*
        FROM
          questions
        JOIN
          question_likes ON question_likes.question_id = questions.id
        JOIN
          users ON question_likes.user_id = users.id
        WHERE
          user_id = ?;
      SQL
      return nil if data.empty?

      data.map { |datum| Question.new(datum) }
    end

    def self.most_liked_questions(n)
      data = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
          questions.*
        FROM
          questions
        JOIN
          question_likes ON question_likes.question_id = questions.id
        GROUP BY
          questions.id
        ORDER BY
          COUNT(*) DESC
        LIMIT ?;
      SQL
      return nil if data.empty?

      data.map { |datum| Question.new(datum) }
    end

    def initialize(data)
      @id = data['id']
      @user_id = data['user_id']
      @question_id = data['question_id']
    end
end
