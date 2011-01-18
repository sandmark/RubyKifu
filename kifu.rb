# -*- coding: utf-8 -*-

$KCODE='u'
require 'nkf'
require 'date'
require "enumerator"

module Kifu
  class KifuDifferenceError < Exception
  end
  
  class InvalidKifuError < Exception
  end
  
  class SashiteMismatchedError < Exception
  end
  
  class SashiteExpiredError < Exception
  end
  
  class Kifu
    attr_accessor :name
    attr_reader :footer
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

    def initialize kifu, name='', headers=[], attributes={}, body=[], footer=nil
      # merge 判定
      if (not headers.empty? or not attributes.empty? or
          not body.empty? or not footer.nil?)
        @name   = name
        @headers = headers
        @attributes = attributes
        @body   = body.dup
        @footer = footer

      elsif not Kifu.valid? kifu
        raise InvalidKifuError, "正式な柿木形式棋譜ファイルではありません"

      else
        @name = name
        parse NKF.nkf('-w', kifu) # 新たに解析する
      end
    end

    def merge_comment! sashite
      raise SashiteMismatchedError, "指し手オブジェクトではありません" if sashite.class != Sashite
      raise SashiteExpiredError, "手数が超過しています" if sashite.tesuu > (@body.length+1)
      if @body.length == sashite.tesuu # フッタの可能性チェック
        if @footer.class == Sashite
          @footer = @footer.merge sashite
        else
          @footer = sashite
        end
      else
        @body[sashite.tesuu] = @body[sashite.tesuu].merge sashite
      end
    end

    def merge another
      if not another.class == self.class
        raise InvalidKifuError, "棋譜オブジェクトではありません"
      elsif not same? another
        raise KifuDifferenceError, "同じ棋譜ではありません"
      end

      # ヘッダは呼び出し元を保持
      headers = @headers.dup
      attributes = @attributes.dup
      body   = @body.enum_with_index.map{|sashite, index|
        sashite.merge another[index]}
      footer = nil
      if @footer.class == Sashite and another.footer.class == Sashite
        footer = @footer.merge another.footer
      end

      Kifu.new nil, self.name, headers, attributes, body, footer
    end

    def & another
      merge another
    end

    def started_at
      @attributes[:started_at]
    end

    def same? another
      each_with_index do |sashite, index|
        if not sashite.te == another[index].te
          unless sashite.te.match(/同/) or another[index].te.match(/同/)
            return false
          end
        end
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
      _to_s :to_s
    end

    def to_s_with_names
      _to_s :to_s_with_names_and_comments
    end

    def _to_s method # private
      buffer = []
      buffer.push @headers.join("\n")
      buffer.push ValidKifuPattern
      buffer += @body.map{ |sashite| sashite.__send__ method }
      buffer.push @footer.__send__ method if @footer.class == Sashite

      # to_s するときは改行コードを CRLF に固定
      buffer.join("\n").gsub(/\r/m, "").gsub(/\n/m, "\r\n") + "\r\n"
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
            @body << Sashite.new(queue, @name)
            queue = ""
          elsif Sashite.footer?(line)
            queue += line
            @footer = Sashite.new(queue, @name)
          end
        end
      end
    end

    def zenkaku_strip string
      string.strip.gsub(/　+$/, '')
    end

    private :parse, :zenkaku_strip, :_to_s
  end

  class Sashite
    attr_reader :tesuu, :te, :prev_te, :time_considered, :clock
    SashitePattern = /^\s*?(\d+?)\s(.+?)(\(\d\d\))?\s+?\(\s?(.*?)\)/
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
        if args[:merge] # マージ用の一時オブジェクトの場合
          @tesuu = args[:tesuu]
          @names = [args[:name]]
          @comments = [args[:comment]]
        else
          @names           = args[:names]
          @comments        = args[:comments].map{|c| c.gsub(/\r/, "")}
          @tesuu           = args[:tesuu]
          @te              = args[:te]
          @prev_te         = args[:prev_te]
          @time_considered = args[:time_considered]
          @clock           = args[:clock]
          @footer          = args[:footer]
        end
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
      if not another.class == self.class
        raise SashiteMismatchedError, "指し手オブジェクトではありません"
      end

      Sashite.new(nil, nil, {
                    :names   => @names + another.names,
                    :comments => @comments + another.comments,
                    :tesuu   => @tesuu,   :te       => @te,
                    :prev_te => @prev_te,
                    :time_considered => @time_considered,
                    :clock   => @clock, :footer => @footer})
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

    # to_s は最初のコメントを名前無し + 指し手で返す
    def to_s
      return crlfize(comments_to_s(0, false)) + @footer if footer?

      result = comments_to_s 0, false
      result += te_to_s
      crlfize result
    end

    def to_s_with_names_and_comments
      return crlfize(comments_to_s((0..-1), true)) + @footer if footer?

      result = comments_to_s((0..-1), true)
      result += te_to_s
      crlfize result
    end

    def to_s_without_comments
      return crlfize(@footer) if footer?
      te_to_s
    end

    def comment_to_s pos, with_name # private
      @comments[pos].split("\n").map{ |comment|
        if with_name
          "*#{@names[pos]}: #{comment}"
        else
          "*#{comment}"
        end
      }.join("\n")
    end

    def comments_to_s range, with_name # private
      result = ""
      if range.class == Range
        result = 
          @comments[range].enum_with_index.map{ |c, pos|
            comment_to_s pos, with_name
          }.select{|v| not v.empty?}.join("\n")
      else
        result = comment_to_s range, with_name
      end
      result += "\n" if not result.empty?
      return result
    end

    def commented?
      not count_of_comment.zero?
    end

    def count_of_comment
      @comments.inject(0){|count, comment| comment.empty? ? count+0 : count+1}
    end

    def te_to_s
      result = sprintf("%4d", @tesuu) + " "

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

    private :te_to_s, :crlfize, :comments_with_names_within,
            :comment_to_s, :comments_to_s
  end
end

if $0 == __FILE__
  k = Kifu::Kifu.new NKF.nkf("-w", File.read("sandmark.kif"))
  puts NKF.nkf("-s", k.to_s)
end
