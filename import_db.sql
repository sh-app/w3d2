DROP TABLE users;
DROP TABLE questions;
DROP TABLE question_follows;
DROP TABLE replies;
DROP TABLE question_likes;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname TEXT,
  lname TEXT
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT,
  body TEXT,
  author_id INTEGER NOT NULL,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL,
  parent_reply_id INTEGER,
  user_id INTEGER NOT NULL,
  body TEXT,

  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (parent_reply_id) REFERENCES replies(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Homer', 'Simpson'),
  ('Bart', 'Simpson'),
  ('Groundskeeper', 'Willy');

INSERT INTO
  questions (title, body, author_id)
VALUES
  ('How much do donuts cost?', 'Is it more than a dollar?',
    (SELECT id FROM users WHERE fname = 'Homer')),
  ('When is snow day?', 'Is it tomorrow?',
    (SELECT id FROM users WHERE fname = 'Bart'));

INSERT INTO
  question_follows (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname = 'Groundskeeper'),
  (SELECT id FROM questions WHERE title = 'When is snow day?'));

INSERT INTO
  replies (question_id, parent_reply_id, user_id, body)
VALUES
  ((SELECT id FROM questions WHERE title = 'When is snow day?'), NULL,
    (SELECT id FROM users WHERE fname= 'Groundskeeper'), 'NEVER!'),
  ((SELECT id FROM questions WHERE title = 'When is snow day?'),
    (SELECT id FROM replies WHERE body = 'NEVER!'),
    (SELECT id FROM users WHERE fname = 'Bart'), 'Eat my shorts!');

INSERT INTO
  question_likes (user_id, question_id)
VALUES
  ((SELECT id FROM users WHERE fname= 'Homer'),
    (SELECT id FROM questions WHERE title = 'How much do donuts cost?'));
