require 'sqlite3'
require 'bcrypt'

db = SQLite3::Database.new("todos.db")


def seed!(db)
  puts "Using db file: db/todos.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  db.execute('DROP TABLE IF EXISTS todos')
  db.execute('DROP TABLE IF EXISTS categories')
  db.execute('DROP TABLE IF EXISTS todo_cat_rel')
  db.execute('DROP TABLE IF EXISTS users')
end

def create_tables(db)
  db.execute('CREATE TABLE todos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              description TEXT,
              is_done BOOL NOT NULL DEFAULT FALSE,
              owner_id INTEGER NOT NULL
              )')
  db.execute('CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    owner_id INTEGER NOT NULL
  )')
  db.execute("CREATE TABLE todo_cat_rel (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    todo_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL
  )")
  db.execute("CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username STRING NOT NULL,
    pass_digest STRING NOT NULL
  )")
end

def populate_tables(db)
  pass_digest = BCrypt::Password.create("roblox")
  db.execute("INSERT INTO USERS (username, pass_digest) VALUES (?, ?)", ["builderman", pass_digest])

  db.execute('INSERT INTO categories (name, owner_id) VALUES ("Matlista", 1)')
  db.execute('INSERT INTO categories (name, owner_id) VALUES ("Kylskåpet", 1)')

  db.execute('INSERT INTO todos (name, description, owner_id) VALUES ("Köp mjölk", "3 liter mellanmjölk, eko", 1)')
  db.execute('INSERT INTO todos (name, description, owner_id) VALUES ("Köp julgran", "En rödgran", 1)')
  db.execute('INSERT INTO todos (name, description, owner_id) VALUES ("Pynta gran", "Glöm inte lamporna i granen och tomten", 1)')

  db.execute("INSERT INTO todo_cat_rel (todo_id, category_id) VALUES (1, 1)")
  db.execute("INSERT INTO todo_cat_rel (todo_id, category_id) VALUES (1, 2)")
end

seed!(db)