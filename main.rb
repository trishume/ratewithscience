require 'sinatra/base'
require "open3"
require "json"

class WikiProc
  def initialize(executable)
    @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(executable)
  end
  def find_path(start,endpoint)
    raise "No params" unless start && endpoint
    @stdin.puts "#{start.downcase}|#{endpoint.downcase}"
    res = get_res
    return nil unless res[0]=="path" || res[0]=="bpath"
    return res[1..-1].map(&:capitalize),res[0] == "bpath"
  end
  def get_res
    while !@stdout.eof?
      res = @stdout.gets.chomp.split('|')
      STDERR.puts res.inspect
      return res if ["path","error","done","bpath"].include? res[0]
    end
  end
end

class MyApp < Sinatra::Base
  configure do
    # logger.info "loading helper process"
    finder = WikiProc.new("/Users/tristan/Box/Dev/Projects/ratews_backend/target/release/ratews_backend")
    finder.get_res
    set :wikifinder, finder
  end

  get '/api/findscale' do
    path,bid = settings.wikifinder.find_path(params[:start],params[:stop])
    return {status: "fail"}.to_json unless path
    {status: "ok", scale: path, quality: bid ? 2 : 1}.to_json
  end

  run! if app_file == $0
end
