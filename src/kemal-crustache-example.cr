require "json"
require "uri"

require "crustache"
require "kemal"

# == Integrate kemal and crustache ==

# When release build, loading template on compile time,
# otherwise loading dynamically.
loader = begin
{% begin %}
  {% view = "src/view" %}
  ifdef release
    Crustache.loader_static {{ view }}
  else
    Crustache.loader {{ view }}
  end
{% end %}
end

$engine = Crustache::Engine.new loader

struct Partial
  def initialize(@view, @model); end

  def has_key?(key); true end

  def [](type)
    return $engine.render @view, {
      "section" => { type => true },
      "model" => @model,
    }
  end
end

# Render a view with model and layout
def render_mustache(view, model = nil, layout = "template")
  $engine.render layout, {
    "partial" => Partial.new(view, model),
  }
end

# Add method for Mustache embedding and JSON mapping
macro model(properties, methods = [] of String)
  JSON.mapping({{ properties }})

  def has_key?(key)
    {% for k in properties %}
      if {{ k.id.stringify }} == key
        return true
      end
    {% end %}
    {% for k in methods %}
      if {{ k }} == key
        return true
      end
    {% end %}
    false
  end

  def [](key)
    {% for k in properties %}
      if {{ k.id.stringify }} == key
        return self.{{ k.id }}
      end
    {% end %}
    {% for k in methods %}
      if {{ k }} == key
        return self.{{ k.id }}
      end
    {% end %}
    nil
  end
end

TimeFormat = Time::Format.new "%Y-%m-%d %H:%M:%S"

struct Time
  def self.new(pull : JSON::PullParser)
    TimeFormat.from_json pull
  end

  def to_json(io)
    TimeFormat.to_json self, io
  end
end

# == Wiki API ==

class Wiki
  model({
    name: String,
    entries: Hash(String, Entry)
  }, %w(recent_update_entries))

  class Entry
    model({
      path: String,
      title: String,
      body: String,
      created_by: String,
      created_at: Time,
      updated_by: String,
      updated_at: Time,
    }, %w(created_at_format updated_at_format path_escape))

    def initialize(@path, @title, @body, @created_by, @created_at)
      @updated_by = @created_by
      @updated_at = @created_at
    end

    def update(@title, @body, @updated_by, @updated_at); end

    def created_at_format; TimeFormat.format created_at end
    def updated_at_format; TimeFormat.format updated_at end
    def path_escape; URI.escape path end
  end

  property! filename

  def self.load(filename)
    self.from_json(File.read filename).tap do |wiki|
      wiki.filename = filename
    end
  end

  def save
    File.write filename, to_pretty_json
  end

  def get(path)
    entries[path]?
  end

  def edit(path, title, body, user)
    now = Time.now
    if e = entries[path]?
      e.update title, body, user, now
    else
      e = Entry.new(path, title, body, user, now)
    end
    entries[path] = e
  end

  def recent_update_entries
    entries.each_value.to_a.sort_by!(&.updated_at.not_nil!).reverse[0...100]
  end
end


# == Routing ==

wiki = Wiki.load "wiki.json"

get "/" do
  render_mustache "index", wiki
end

get "/edit" do |env|
  path = env.params["path"] as String
  render_mustache "edit", {"wiki" => wiki, "path" => path, "entry" => wiki.get(path)}
end

get "/*path" do |env|
  path = "/#{env.params["path"]}"
  if e = wiki.get(path)
    render_mustache "view", {"wiki" => wiki, "entry" => e}
  else
    env.redirect "/edit?path=#{URI.escape path}"
  end
end

post "/edit" do |env|
  params = env.params

  path = params["path"] as String
  title = params["title"] as String
  body = params["body"] as String
  user = params["user"] as String

  title = title.strip
  body = body.strip
  user = user.strip

  if !path.starts_with?("/") || title.empty? || body.empty? || user.empty?
    next render_403(env)
  end

  wiki.edit path, title, body, user
  wiki.save

  env.redirect "/"
end
