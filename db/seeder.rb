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
end

def create_tables(db)
  db.execute('CREATE TABLE todos (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL, 
              description TEXT,
              is_done BOOL NOT NULL DEFAULT FALSE,
              category_id INTEGER,
              FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
              )')
  db.execute('CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
  )')
end

def populate_tables(db)
  db.execute('INSERT INTO categories (name) VALUES ("Matlista")')

  db.execute('INSERT INTO todos (name, description, category_id) VALUES ("Köp mjölk", "3 liter mellanmjölk, eko", 1)')
  db.execute('INSERT INTO todos (name, description) VALUES ("Köp julgran", "En rödgran")')
  db.execute('INSERT INTO todos (name, description) VALUES ("Pynta gran", "Glöm inte lamporna i granen och tomten")')
end

seed!(db)