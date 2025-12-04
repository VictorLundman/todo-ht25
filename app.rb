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
    todo = db.execute("SELECT * FROM todos WHERE todos.id=?", id)
    if !todo
        return nil
    end

    return todo[0]
end

def getTodoCategories(db, id)
    categories = db.execute("SELECT categories.id, categories.name FROM categories INNER JOIN todo_cat_rel ON categories.id = todo_cat_rel.category_id WHERE todo_cat_rel.todo_id = ?", id)
    return categories
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
    
    todos = db.execute("SELECT * FROM todos")
    @todo_categories = {}
    todos.each do |todo|
      @todo_categories[todo["id"]] = getTodoCategories(db, todo["id"])
      p @todo_categories[todo["id"]]
    end

    @done_todos = todos.select { |todo| todo["is_done"] == 1 }
    @undone_todos = todos.select { |todo| todo["is_done"] == 0 }
    @categories = db.execute("SELECT * FROM categories")

    slim(:"todos/index")
end

post "/todos" do
    db = connectToDb()

    name = params[:name]
    description = params[:description]
    category_ids = (params[:category] || []).map {|v| v.to_i}

    if name.include? "roblox" or name.include? "robux"
        return redirect("https://tenor.com/p8jv5bc6AED.gif")
    end

    category_ids.each do |category_id|
        category = getCategoryById(db, category_id)
        if !category
            error(404)
        end
    end

    id = db.execute("INSERT INTO todos (name, description) VALUES (?, ?) RETURNING id", [name, description])[0]["id"]
    p id

    category_ids.each do |category_id|
        db.execute("INSERT INTO todo_cat_rel (todo_id, category_id) VALUES (?, ?)", [id, category_id])
    end

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
    @todo_categories = getTodoCategories(db, @todo["id"]).map {|category| category["id"]}

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
    category_ids = (params[:category] || []).map {|v| v.to_i}

    p params.inspect

    category_ids.each do |category_id|
        category = getCategoryById(db, category_id)
        if !category
            error(404)
        end
    end

    if is_done != nil and name == nil
        db.execute("UPDATE todos SET is_done=? WHERE id=?", [is_done, id])
    else
        db.execute("DELETE FROM todo_cat_rel WHERE todo_id = ?", [id])

        category_ids.each do |category_id|
            db.execute("INSERT INTO todo_cat_rel (todo_id, category_id) VALUES (?, ?)", [id, category_id])
        end

        db.execute("UPDATE todos SET name=?, description=?, is_done=? WHERE id=?", [name, description, is_done, id])
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

    db.execute("DELETE FROM todo_cat_rel WHERE category_id=?", [id])
    db.execute("DELETE FROM categories WHERE id=?", id)

    redirect("/categories")
end