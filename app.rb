require 'sinatra'
require 'sqlite3'
require 'slim'
require 'sinatra/reloader'


def connectToDb()
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    return db
end

def getTodoById(db, id)
    todo = db.execute("SELECT todos.id, todos.name, todos.description, todos.is_done, todos.category_id,categories.name as category_name FROM todos LEFT JOIN categories ON todos.category_id = categories.id WHERE todos.id=?", id)
    p todo
    if !todo
        return nil
    end

    return todo[0]
end

def getCategoryById(db, id) 
    category = db.execute("SELECT * FROM categories WHERE id=?", [id])
    if !category
        return nil
    end

    return category[0]
end

get '/' do
    slim(:index)
end

get "/todos" do
    db = connectToDb()
    
    todos = db.execute("SELECT todos.id, todos.name, todos.description, todos.is_done, todos.category_id,categories.name as category_name FROM todos LEFT JOIN categories ON todos.category_id = categories.id")
    p todos

    @done_todos = todos.select { |todo| todo["is_done"] == 1 }
    @undone_todos = todos.select { |todo| todo["is_done"] == 0 }
    @categories = db.execute("SELECT * FROM categories")

    slim(:"todos/index")
end

post "/todos" do
    db = connectToDb()

    name = params[:name]
    description = params[:description]
    category_id = params[:category].to_i

    if name.include? "roblox" or name.include? "robux"
        return redirect("https://tenor.com/p8jv5bc6AED.gif")
    end

    category = getCategoryById(db, category_id)
    if !category
        error(404)
    end

    db.execute("INSERT INTO todos (name, description, category_id) VALUES (?, ?, ?)", [name, description, category_id])

    redirect("/todos")
end

get "/todos/:id/edit" do
    id = params[:id].to_i
    db = connectToDb()

    @todo = getTodoById(db, id)
    p @todo
    if !@todo
        error(404)
    end

    @categories = db.execute("SELECT * FROM categories")

    slim(:"todos/edit")
end

post "/todos/:id/update" do
    id = params[:id].to_i
    db = connectToDb()

    @todo = getTodoById(db, id)
    if !@todo
        error(404)
    end

    name = params[:name]
    description = params[:description]
    is_done = params[:is_done].to_i
    category_id = params[:category].to_i

    if category_id == 0 
        category_id = nil
    else
        category = getCategoryById(db, category_id)
        if !category
            error(404)
        end
    end

    if is_done != nil and name == nil
        db.execute("UPDATE todos SET is_done=? WHERE id=?", [is_done, id])
    else
        db.execute("UPDATE todos SET name=?, description=?, is_done=?, category_id=? WHERE id=?", [name, description, is_done, category_id, id])
    end

    redirect("/todos")
end

post "/todos/:id/delete" do
    id = params[:id].to_i
    db = connectToDb()

    @todo = getTodoById(db, id)
    if !@todo
        error(404)
    end

    db.execute("DELETE FROM todos WHERE id=?", id)

    redirect("/todos")
end

get "/categories" do
    db = connectToDb()

    @categories = db.execute("SELECT * FROM categories")

    slim(:"categories/index")
end

post "/categories" do
    db = connectToDb()

    name = params[:name]
    if !name
        error(400)
    end

    db.execute("INSERT INTO categories (name) VALUES (?)", [name])
    
    redirect("/categories")
end

get "/categories/:id/edit" do
    db = connectToDb()
    id = params[:id].to_i

    @category = getCategoryById(db, id)

    slim(:"categories/edit")
end

post "/categories/:id/update" do
    db = connectToDb()
    id = params[:id].to_i

    category = getCategoryById(db, id)
    if !category
        error(404)
    end

    name = params[:name]

    db.execute("UPDATE categories SET name=? WHERE id=?", [name, id])
    redirect("/categories")
end

post "/categories/:id/delete" do
    db = connectToDb()
    id = params[:id].to_i

    category = getCategoryById(db, id)
    if !category
        error(404)
    end

    db.execute("DELETE FROM categories WHERE id=?", id)

    redirect("/categories")
end