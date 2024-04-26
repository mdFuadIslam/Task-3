require 'securerandom'
require 'openssl'
require 'terminal-table'

class Table
  def initialize(moves,judge)
    @moves = moves
    @judge = judge
    rows=[]
    for i in moves
      currentRow=[]
      currentRow << i
      for j in moves
        currentRow << @judge.decideWinner(i,j)
      end
      rows << currentRow
    end
    @table = Terminal::Table.new do |t|
      t.headings = ["v PC/User >"]+@moves
      rows.each { |row| t << row }
    end
  end
  def showCase()
    puts @table
  end
end

class Rules
  def initialize(moves)
    @moves = moves
  end
  def u_move_validity(move)
    if move == "?" || move.to_i >=0 && move.to_i <= @moves.length 
      return move
    end
    return nil
  end
  def decideWinner(c_move,u_move)
    a = @moves.index(u_move)
    b = @moves.index(c_move)
    n = @moves.length
    p = @moves.length/2
    if @moves.index(u_move) == @moves.index(c_move)
      return "Draw"
    elsif (a - b + p + n) % n - p > 0
      return "Win"
    else
      return "Lose"
    end
  end
end

class Key
  def initialize()
    random_key = SecureRandom.random_bytes(32)
    @hkey = random_key.unpack('H*').first.upcase
  end
  def generate_hmac_sha256( key = @hkey, move)
    hmac = OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), key, move)
    return hmac.unpack1('H*').upcase
  end
  def key()
    return @hkey
  end
end

class Game
  def initialize(moves)
    @moves=moves
    @key = Key.new()
    @judge = Rules.new(@moves)
    @table = Table.new(@moves,@judge)
    @computer_move = computer_move()
    @hmac = @key.generate_hmac_sha256(@computer_move)
  end
  def menu()
    puts "HMAC:\n"+@hmac
    puts "Available moves:"
    index = 1
    for i in @moves do
      puts "#{index} - #{i}"
      index += 1
    end
    puts "0 - exit"
    puts "? - help"
  end
  def user_move()
    print "Enter your move: "
    user_input = @judge.u_move_validity( $stdin.gets.chomp)
    if user_input == nil
      puts "Invalid move!"
      puts "Try 1,2,3... "
      return nil
    elsif user_input == "?"
      @table.showCase()
      return nil
    elsif user_input.to_i == 0
      @verdict = nil
      return ""
    else
      @user_move = @moves[user_input.to_i-1]
      @verdict = @judge.decideWinner(@computer_move,@user_move)
      return ""
    end
  end
  def scoreboard()
    if @verdict == nil
      return ""
    end
    puts "Your move: #{@user_move}"
    puts "Computer move: #{@computer_move}"
    puts "You #{@verdict}!!"
    puts "HMAC Key:\n#{@key.key()}"
  end
  def computer_move()
    return @moves.sample
  end
end

def showError(errorMessage)
  return "\nIncorrect Input!\n\n#{errorMessage}\n\nexample: ruby task-3.rb rock paper scissors\n\n"
end

moves = ARGV

if moves.length <= 1
  error = "The number of moves has to be greater than one!"
  puts showError(error)
elsif moves.length % 2 == 0
  error = "The number of moves CANNOT BE EVEN!"
  puts showError(error)
elsif moves.to_set.length != moves.length
  error = "The moves are NOT UNIQUE!!"
  puts showError(error)
else
  game = Game.new(moves)
  loop do
    game.menu()
    progress = game.user_move()
    break if progress != nil
  end 
  game.scoreboard()
end