require 'sqlite3'

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
end

def create_tables(db)
  db.execute('CREATE TABLE todos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              description TEXT,
              is_done BOOL NOT NULL DEFAULT FALSE
              )')
  db.execute('CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
  )')
  db.execute("CREATE TABLE todo_cat_rel (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    todo_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL
  )")
end

def populate_tables(db)
  db.execute('INSERT INTO categories (name) VALUES ("Matlista")')
  db.execute('INSERT INTO categories (name) VALUES ("Kylskåpet")')

  db.execute('INSERT INTO todos (name, description) VALUES ("Köp mjölk", "3 liter mellanmjölk, eko")')
  db.execute('INSERT INTO todos (name, description) VALUES ("Köp julgran", "En rödgran")')
  db.execute('INSERT INTO todos (name, description) VALUES ("Pynta gran", "Glöm inte lamporna i granen och tomten")')

  db.execute("INSERT INTO todo_cat_rel (todo_id, category_id) VALUES (1, 1)")
  db.execute("INSERT INTO todo_cat_rel (todo_id, category_id) VALUES (1, 2)")
end

seed!(db)