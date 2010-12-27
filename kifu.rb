# -*- coding: utf-8 -*-

$KCODE='u'
require 'nkf'
require 'date'

module Kifu
  class Kifu
    ValidKifuPattern = /手数----指手---------消費時間--/
    HeaderPattern    = /^#/
    SplitPattern     = ValidKifuPattern # ここから指し手
    KifuHeaders      = {"棋戦" => :kisen, "手合割" => :teai,
                        "先手" => :sente, "後手"  => :gote}

    # 柿木形式棋譜の判定を行う（適当）
    def self.valid? kifu
      if NKF.nkf('-w', kifu).match(ValidKifuPattern)
        true
      else
        false
      end
    end

    def initialize kifu, name=''
      if not Kifu.valid? kifu
        raise RuntimeError, "正式な柿木形式棋譜ファイルではありません"
      end

      parse NKF.nkf('-w', kifu)
    end

    def to_s
      buffer = ""
      @headers.each do |key, value|
        if key == :header
          buffer += value + "\n"
        else
          buffer += "#{key}：#{value}\n"
        end
      end
      buffer.chomp!

      @body
    end

    private
    def parse kifu
      @headers = {}
      @body = []
      queue = ""

      kifu.each_line do |line|
        if line.match HeaderPattern
          @headers[:header] = line

        elsif not line.match SplitPattern # まだヘッダ部分
          key, value = line.split(/：/)
          if key == "開始日時"
            @headers[:started_at] = DateTime.parse value
          else
            @headers[KifuHeaders[key]] = value
          end

        else # 指し手突入
          if Sashite.comment? line
            queue += line
          else
            queue += line
            @body << Sashite.new(queue)
            queue = ""
          end
        end
      end
    end
  end

  class Sashite
    attr_reader :comment, :tesuu, :te, :prev_te, :time_considered, :clock
    SashitePattern = /^\s+?(\d+?)\s(.+?)\((\d\d)\)\s+?\(\s(.*?)\)/
    CommentPattern = /^\*(.*)/

    def self.sashite? line
      line.match SashitePattern
    end

    def self.comment? line
      line.match CommentPattern
    end

    def initialize text
      @comment = []
      text.each_line do |line|
        if match = Sashite.comment?(line)
          @comment << match[1]
        elsif match = Sashite.sashite?(line)
          @tesuu = match[1].to_i
          @te    = match[2]
          @prev_te = match[3]
          @time_considered, @clock = match[4].split(/\//)
        end
      end
      @comment = @comment.join("\n")
    end

    def to_s
      _to_s true
    end

    def to_s_without_comment
      _to_s
    end

    def commented?
      not @comment.empty?
    end

    private
    def _to_s with_comment=nil
      result = ""
      if with_comment
        if commented?
          result += @comment.split(/\n/).map{|l| '*'+l}.join("\n") + "\n"
        end
      end
      result += sprintf("%4d", self.tesuu) + " " +
        self.te +
        "(" + self.prev_te + ")" + "   ( " +
        self.time_considered + "/" +
        self.clock + ")"
      return result
    end
  end
end

if $0 == __FILE__
  player1 = NKF.nkf("-w", File.read(ARGV[0]))
  player2 = NKF.nkf("-w", File.read(ARGV[1]))
  k1 = Kifu::Kifu.new player1, "将棋指しＡ"
  k2 = Kifu::Kifu.new player2, "将棋指しＢ"
  puts NKF.nkf("-s", (k1 & k2).to_s)
end
