require 'sinatra'
require 'sqlite3'
require 'slim'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

before do
    session_id = session[:user_id]
    if session_id == nil
        @user = nil
        return
    end

    db = connectToDb()
    user = db.execute("SELECT id, username FROM users WHERE id=?", [session_id])
    if user.empty?
        @user = nil
        return
    end

    @user = user[0]
    p @user
end


def connectToDb()
    db = SQLite3::Database.new("db/todos.db")
    db.results_as_hash = true

    return db
end

def getTodoById(db, id, user_id)
    todo = db.execute("SELECT * FROM todos WHERE id=? AND owner_id=?", [id, user_id])
    if !todo
        return nil
    end

    return todo[0]
end

def getTodoCategories(db, id, user_id)
    categories = db.execute("SELECT categories.id, categories.name FROM categories INNER JOIN todo_cat_rel ON categories.id = todo_cat_rel.category_id WHERE todo_cat_rel.todo_id=? AND categories.owner_id=?", [id, user_id])
    return categories
end

def getCategoryById(db, id, user_id) 
    category = db.execute("SELECT * FROM categories WHERE id=? AND owner_id=?", [id, user_id])
    if !category
        return nil
    end

    return category[0]
end

get '/' do
    slim(:index)
end

get "/todos" do
    if @user == nil
        redirect("/login")
    end
    user_id = @user["id"]

    db = connectToDb()
    
    todos = db.execute("SELECT * FROM todos where owner_id=?", [user_id])
    @todo_categories = {}
    todos.each do |todo|
      @todo_categories[todo["id"]] = getTodoCategories(db, todo["id"], user_id)
    end

    @done_todos = todos.select { |todo| todo["is_done"] == 1 }
    @undone_todos = todos.select { |todo| todo["is_done"] == 0 }
    @categories = db.execute("SELECT * FROM categories WHERE owner_id=?", [user_id])

    slim(:"todos/index")
end

post "/todos" do
    if @user == nil
        redirect("/login")
    end
    user_id = @user["id"]

    db = connectToDb()

    name = params[:name]
    description = params[:description]
    category_ids = (params[:category] || []).map {|v| v.to_i}

    if name.include? "roblox" or name.include? "robux"
        return redirect("https://tenor.com/p8jv5bc6AED.gif")
    end

    category_ids.each do |category_id|
        category = getCategoryById(db, category_id, user_id)
        if !category
            error(404)
        end
    end

    id = db.execute("INSERT INTO todos (name, description, owner_id) VALUES (?, ?, ?) RETURNING id", [name, description, user_id])[0]["id"]
    p id

    category_ids.each do |category_id|
        db.execute("INSERT INTO todo_cat_rel (todo_id, category_id) VALUES (?, ?)", [id, category_id])
    end

    redirect("/todos")
end

get "/todos/:id/edit" do
    if @user == nil
        redirect("/login")
    end
    user_id = @user["id"]

    id = params[:id].to_i
    db = connectToDb()

    @todo = getTodoById(db, id)
    p @todo
    if !@todo
        error(404)
    end

    @categories = db.execute("SELECT * FROM categories WHERE owner_id=?", [user_id])
    @todo_categories = getTodoCategories(db, @todo["id"], user_id).map {|category| category["id"]}

    slim(:"todos/edit")
end

post "/todos/:id/update" do
    if @user == nil
        redirect("/login")
    end
    user_id = @user["id"]

    id = params[:id].to_i
    db = connectToDb()

    @todo = getTodoById(db, id, user_id)
    if !@todo
        error(404)
    end

    name = params[:name]
    description = params[:description]
    is_done = params[:is_done].to_i
    category_ids = (params[:category] || []).map {|v| v.to_i}

    p params.inspect

    category_ids.each do |category_id|
        category = getCategoryById(db, category_id, user_id)
        if !category
            error(404)
        end
    end

    if is_done != nil and name == nil
        db.execute("UPDATE todos SET is_done=? WHERE id=? AND owner_id=?", [is_done, id, user_id])
    else
        db.execute("DELETE FROM todo_cat_rel WHERE todo_id=?", [id])

        category_ids.each do |category_id|
            db.execute("INSERT INTO todo_cat_rel (todo_id, category_id) VALUES (?, ?)", [id, category_id])
        end

        db.execute("UPDATE todos SET name=?, description=?, is_done=? WHERE id=? and owner_id=?", [name, description, is_done, id, user_id])
    end

    redirect("/todos")
end

post "/todos/:id/delete" do
    if @user == nil
        redirect("/login")
    end
    user_id = @user["id"]

    id = params[:id].to_i
    db = connectToDb()

    @todo = getTodoById(db, id, user_id)
    if !@todo
        error(404)
    end

    db.execute("DELETE FROM todos WHERE id=? AND owner_id=?", [id, user_id])

    redirect("/todos")
end

get "/categories" do
    if @user == nil
        redirect("/login")
    end
    user_id = @user["id"]

    db = connectToDb()

    @categories = db.execute("SELECT * FROM categories WHERE owner_id=?", [user_id])

    slim(:"categories/index")
end

post "/categories" do
    if @user == nil
        redirect("/login")
    end
    user_id = @user["id"]

    db = connectToDb()

    name = params[:name]
    if !name
        error(400)
    end

    db.execute("INSERT INTO categories (name, owner_id) VALUES (?, ?)", [name, user_id])
    
    redirect("/categories")
end

get "/categories/:id/edit" do
    if @user == nil
        redirect("/login")
    end
    user_id = @user["id"]

    db = connectToDb()
    id = params[:id].to_i

    @category = getCategoryById(db, id, user_id)

    slim(:"categories/edit")
end

post "/categories/:id/update" do
    if @user == nil
        redirect("/login")
    end
    user_id = @user["id"]

    db = connectToDb()
    id = params[:id].to_i

    category = getCategoryById(db, id, user_id)
    if !category
        error(404)
    end

    name = params[:name]

    db.execute("UPDATE categories SET name=? WHERE id=? AND owner_id=?", [name, id, user_id])
    redirect("/categories")
end

post "/categories/:id/delete" do
    if @user == nil
        redirect("/login")
    end
    user_id = @user["id"]

    db = connectToDb()
    id = params[:id].to_i

    category = getCategoryById(db, id, user_id)
    if !category
        error(404)
    end

    db.execute("DELETE FROM todo_cat_rel WHERE category_id=?", [id])
    db.execute("DELETE FROM categories WHERE id=?", id)

    redirect("/categories")
end

get "/user" do
    if @user != nil
        redirect("/todos")
    end

    slim(:user)
end

post "/user" do
    if @user != nil
        redirect("/todos")
    end

    username = params["username"]
    pass = params["pass"]
    pass_con = params["pass_conf"]

    p pass
    p pass_con

    db = connectToDb()
    existing_user = db.execute("SELECT id FROM users WHERE username=?", username)
    if existing_user.empty?
        if pass == pass_con
            pass_digest = BCrypt::Password.create(pass)
            row = db.execute("INSERT INTO users (username, pass_digest) VALUES (?, ?) RETURNING id", [username, pass_digest])
            user_id = row[0]["id"]

            session[:user_id] = user_id
            
            redirect("/todos")
        else
            redirect("/user")
        end
    else
        redirect("/login")
    end
end

get "/login" do
    if @user != nil
        redirect("/todos")
    end

    slim(:login)
end

post "/login" do
    if @user != nil
        redirect("/todos")
    end

    username = params["username"]
    pass = params["pass"]

    db = connectToDb()
    existing_user = db.execute("SELECT id, pass_digest FROM users WHERE username=?", username)
    if existing_user.empty?
        redirect("/login")
    end

    user_id = existing_user[0]["id"]
    pass_digest = existing_user[0]["pass_digest"]

    if BCrypt::Password.new(pass_digest) == pass 
        session[:user_id] = user_id
        redirect("/todos")
    end

    redirect("/login")
end

post "/logout" do
    if !@user then
        error(401)
    end

    session[:user_id] = nil

    redirect("/login")
end