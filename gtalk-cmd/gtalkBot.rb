require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/roster'
require 'highline/import'

include Jabber
#Jabber::debug = true

class GTalk
  def initialize(username, password)
    @username = username
    @password = password
    @client = Client.new(JID::new(username + '@gmail.com'))
    puts "Connecting to server..."
    @client.connect('talk.l.google.com', 5222)
    puts "Authenticating..."
    begin
      @client.auth(@password)
    rescue ClientAuthenticationFailure => caf
      abort "Invalid credentials. Exiting."
    end
    puts "Logged in successfully. Setting status to available..."
    @client.send(Presence.new.set_type(:available).set_status("I am code!"))
    puts "Getting friend list..."
    @roster = Roster::Helper.new(@client)

    @roster.add_subscription_request_callback do |item, pres|
      puts "Got a friend request. Accepting it"
      @roster.accept_subscription(pres.from)
      puts "Accepted. Sending friend request back."
      x = Presence.new.set_type(:subscribe)
      x.set_to(pres.from)
      @client.send(x)
      puts "Sent"
    end

    @roster.add_presence_callback do |item, opres, npres|
      puts item.iname.to_s + ' - ' + item.jid.to_s + ' is now ' + npres.show.to_s unless npres.nil?
    end

    @roster.get_roster
    @roster.wait_for_roster

    @client.add_message_callback do |m|
      @peer = m.from
      puts 'Message from ' + @peer.to_s + ': ' + m.body.to_s unless m.body.to_s == ""
    end
  end

  def send_message(message)
    puts "Trying to send message to: " + ((@peer.to_s.empty?) ? "" : @peer.to_s) + " Message body: " + message
    msg = Message::new(@peer.strip.to_s, message)
    msg.type = :chat
    @client.send(msg)
  end

  def get_friends
    #item_helper = Roster::Helper::RosterItem.new(@client)
    #item_helper.each_presence do |pres|
    #    puts pres.to_s
    #end
    #groups = @roster.groups
    #groups.each do |group|
    #    members = @roster.find_by_group group
    #    members.each do |member|
    #    # print item_helper.presence(member.jid).show.to_s + ' - '
    #    puts member.iname.to_s + ' - ' + member.jid.to_s
    #    end
    #end
  end
  def close
    @client.close
  end
end

username = ask "Enter gmail username: "
password = ask ("Enter password: ") { |p| p.echo = "*" }
client = GTalk.new(username, password)

sender = Thread.new do
  loop do
    message = gets.chomp
    if message == "exit"
      client.close
      abort "Quitting..."
    end
    client.send_message(message)
  end
end

client.get_friends

sender.join
