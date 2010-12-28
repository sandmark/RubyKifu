# -*- coding: utf-8 -*-

$KCODE='u'
require 'nkf'
require 'date'

module Kifu
  class Kifu
    ValidKifuPattern = "手数----指手---------消費時間--"
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

    def started_at
      @attributes[:started_at]
    end

    def same? another
      each_with_index do |sashite, index|
        return false if not sashite.te == another[index].te
      end
      return true
    end

    def strict_same? another
      if (header     != another.header     or
          started_at != another.started_at or
          kisen      != another.kisen      or
          teai       != another.teai       or
          sente      != another.sente      or
          gote       != another.gote)
        return false
      end

      each_with_index do |sashite, index|
        if (sashite.te      != another[index].te or
            sashite.comment != another[index].comment)
          return false
        end
      end
    end

    def header
      @attributes[:header]
    end

    def teai
      @attributes[:teai]
    end

    def sente
      @attributes[:sente]
    end

    def gote
      @attributes[:gote]
    end

    def kisen
      @attributes[:kisen]
    end
  
    def at pos
      @body[pos]
    end

    def [] pos
      at pos
    end

    def each &block
      @body.each do |sashite|
        block.call sashite
      end
    end

    def each_with_index &block
      @body.each_with_index do |sashite, index|
        block.call sashite, index
      end
    end

    def to_s
      buffer = []
      buffer.push @headers.join("\n")
      buffer.push ValidKifuPattern
      buffer += @body.map{|sashite| sashite.to_s}
      buffer.push @footer.to_s

      # to_s するときは改行コードを CRLF に固定
      return buffer.join("\n").gsub(/\r/m, "").gsub(/\n/m, "\r\n") + "\r\n"
    end

    def kifu
      to_s
    end

    def parse kifu
      @headers = []
      @attributes = {}
      @body = []
      @footer = []
      queue = ""

      sashite_mode = false
      kifu.each_line do |line|
        if not sashite_mode and line.match HeaderPattern
          @headers << line.chomp
          @attributes[:header] = line.strip

        elsif not sashite_mode and not line.match SplitPattern # まだヘッダ部分
          @headers << line.chomp
          key, value = line.split(/：/)
          if key == "開始日時"
            @attributes[:started_at] = DateTime.parse value
          else
            @attributes[KifuHeaders[key]] = zenkaku_strip(value.to_s)
          end

        else # 指し手突入
          if not sashite_mode
            sashite_mode = true
            next # 最初の行はスキップ
          end

          if Sashite.comment? line
            queue += line
          elsif Sashite.sashite? line
            queue += line
            @body << Sashite.new(queue)
            queue = ""
          elsif Sashite.footer?(line)
            queue += line
            @footer = Sashite.new(queue)
          end
        end
      end
    end

    def zenkaku_strip string
      string.strip.gsub(/　+$/, '')
    end

    private :parse, :zenkaku_strip
  end

  class Sashite
    attr_reader :tesuu, :te, :prev_te, :time_considered, :clock
    SashitePattern = /^\s+?(\d+?)\s(.+?)(\(\d\d\))?\s+?\(\s(.*?)\)/
    CommentPattern = /^\*(.*)/
    ToryoPattern   = /^まで.*/

    def self.sashite? line
      line.to_s.match SashitePattern
    end

    def self.comment? line
      line.to_s.match CommentPattern
    end

    def self.comment_or_sashite? line
      comment?(line) or sashite?(line)
    end

    def self.footer? line
      line.to_s.match ToryoPattern
    end

    def initialize text, name="no name", args={}
      if args.empty?
        @names = []
        @comments = []
        @names.push name
        @comment = []
        text.each_line do |line|
          if match = Sashite.comment?(line)
            @comment << match[1].to_s.chomp
          elsif match = Sashite.footer?(line)
            @footer = match[0]
          elsif match = Sashite.sashite?(line)
            @tesuu = match[1].to_i
            @te    = match[2].chomp
            @prev_te = match[3].match(/\d\d/)[0].chomp if match[3]
            @time_considered, @clock = match[4].chomp.split(/\//)
          end
        end
        @comment = @comment.join("\n")
        @comments.push @comment
      else # args 処理
        @names           = args[:names]
        @comments        = args[:comments].map{|c| c.gsub(/\r/, "")}
        @tesuu           = args[:tesuu]
        @te              = args[:te]
        @prev_te         = args[:prev_te]
        @time_considered = args[:time_considered]
        @clock           = args[:clock]
      end
    end

    def footer?
      true if @footer
    end

    def names
      @names.dup.freeze
    end

    def name
      @names.first
    end

    def merge another
      Sashite.new(nil, nil, {
                    :names   => @names + another.names,
                    :comments => @comments + another.comments,
                    :tesuu   => @tesuu,   :te       => @te,
                    :prev_te => @prev_te,
                    :time_considered => @time_considered,
                    :clock   => @clock})
    end

    def & another
      merge another
    end

    def comments_with_names
      comments_with_names_within(0..-1)
    end

    def comments
      @comments.map{|c| crlfize c}
    end

    def comment_with_name
      comments_with_names_within(0..0).first
    end

    def comments_with_names_within range
      result = []
      queue = ""
      @comments[range].each_with_index do |comment, index|
        comment.each_line do |line|
          queue += "#{@names[index]}: #{line}"
        end
        result.push queue
        queue = ""
      end
      result.map{|c| crlfize c}
    end

    def comment
      crlfize @comments.first
    end

    def crlfize string
      string.gsub(/\n/m, "\r\n")
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

    def _to_s with_comment=nil
      result = ""
      if with_comment
        if commented?
          result += @comment.split(/\n/).map{|l| '*'+l}.join("\n") + "\n"
        end
      end

      if footer?
        result += @footer
        return crlfize result
      end

      result += sprintf("%4d", @tesuu) + " "

      te  = @te.to_s
      te += "(#{@prev_te})" if @prev_te
      te += "    " if not @prev_te
      sprintf_length  = 13
      sprintf_length += (te.length - NKF.nkf("-s", te).length)
      result += sprintf("%-*s", sprintf_length, te)

      time = "( " + @time_considered.to_s + "/" + @clock.to_s + ")"
      result += time
      return crlfize result
    end

    private :_to_s, :crlfize, :comments_with_names_within
  end
end

if $0 == __FILE__
  k = Kifu::Kifu.new NKF.nkf("-w", File.read("sandmark.kif"))
  puts NKF.nkf("-s", k.to_s)
end
