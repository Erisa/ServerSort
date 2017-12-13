require 'discordrb'
require 'open-uri'
require 'yaml'

begin
  (raise Discordrb::Errors::NoPermission)
rescue
  nil
end

@store = {}

@config = YAML.load_file('config.yml')

bot = Discordrb::Bot.new(
  token: @config['token'],
  type: @config['type'],
  parse_self: false
)

puts '-=-=-==--=-WARNING-=-=-==--=-'
puts '- Running this script will permanently change the order of your servers.'
puts '- If you are unhappy with the result of this script, you will have to fix it yourself.'
puts '- To continue, please enter your user ID. '
result = gets.chomp

bot.run(true)

puts "Logged in as: #{bot.profile.distinct} [#{bot.profile.id}]"
puts "Servers: #{bot.servers.count}"

puts result
if result != bot.profile.id.to_s
  puts 'That\'s not your user id!'
  exit
end

bot.servers.each do |_num, server|
  puts "Searching #{server.name}.."
  begin
    body = Discordrb::API.request(
      :users_me,
      nil,
      :get,
      "#{Discordrb::API.api_base}/guilds/#{server.id}/messages/search?author_id=#{bot.profile.id}",
      Authorization: bot.token
    ).body
    count = JSON.parse(body)['total_results']
    @store[server.id] = count
    puts "  Found: #{count} messages."
  rescue
    puts 'Error occured. Ignoring server (Counting as 0)'
    @store[server.id] = 0
  end
end

@final_order = []
@store.sort_by { |_id, count| count }.each { |arr| @final_order.push(arr[0].to_s) }

Discordrb::API.request(nil,
                       nil,
                       :patch,
                       "#{Discordrb::API.api_base}/users/@me/settings",
                       { guild_positions: @final_order.reverse }.to_json,
                       content_type: :json,
                       Authorization: bot.token).body

puts 'All done! Check discord to see the result.'
