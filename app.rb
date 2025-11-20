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
    todo = db.execute("SELECT * FROM todos WHERE id=?", id)
    if !todo
        return nil
    end

    return todo[0]
end

get '/' do
    slim(:index)
end

get "/todos" do
    db = connectToDb()
    
    @todos = db.execute("SELECT * FROM todos")

    slim(:"todos/index")
end

post "/todos" do
    db = connectToDb()

    name = params[:name]
    description = params[:description]

    if name.include? "roblox" or name.include? "robux"
        return redirect("https://tenor.com/p8jv5bc6AED.gif")
    end

    db.execute("INSERT INTO todos (name, description) VALUES (?, ?)", [name, description])

    redirect("/todos")
end

get "/todos/:id/edit" do
    id = params[:id].to_i
    db = connectToDb()

    @todo = getTodoById(db, id)
    if !@todo
        error(404)
    end

    slim(:"todos/edit")
end

post "/todos/:id/update" do
    id = params[:id].to_i
    db = connectToDb()

    @todo = getTodoById(db, id)
    p @todo
    if !@todo
        error(404)
    end

    name = params[:name]
    description = params[:description]

    db.execute("UPDATE todos SET name=?, description=? WHERE id=?", [name, description, id])

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