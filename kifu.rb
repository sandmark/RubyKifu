# -*- coding: utf-8 -*-
module Kifu
  class Kifu
    attr_accessor :name

    CommentAreaStartingPattern = /^手数/
    CommentPattern = /^\*/

    def initialize string, name='' # must be UTF-8
      raise RuntimeError, "kif must be encoded with UTF8" if NKF.guess(string) != NKF::UTF8
      @kifu = string
      @name = name
    end

    def to_s
      @kifu
    end

    def to_s_with_name
      @kifu.gsub /^\*(.*)$/, "*#{@name}: \\1"
    end

    def to_s_with_name!
      @kifu.gsub! /^\*(.*)$/, "*#{@name}: \\1"
    end

    def comments
      result = Array.new
      comment = String.new
      comment_area = false
      comment_pattern = /^\*/

      @kifu.each_line do |line|
        comment_area = true if line.match CommentAreaStartingPattern
        if comment_area
          if line.match comment_pattern
            comment += line
          else
            result.push comment
            comment = ''
          end
        end
      end
      result.push comment
      return result[1..-1]
    end

    def comments_with_name
      comments.map{ |comment| comment.gsub /^\*(.*)$/, "*#{@name}: \\1" }
    end

    def merge kifu
      comments = Array.new
      comments_with_name2 = kifu.comments_with_name
      comments_with_name.each_with_index do |comment, index|
        comments.push(comment.to_s + comments_with_name2[index].to_s)
      end

      result = String.new
      comment_area = false
      tesuu = 0
      delete_comments_of_kifu_data(@kifu).each_line do |line|
        comment_area = true if line.match CommentAreaStartingPattern
        if not comment_area
          result += line
        else
          result += line
          result += comments[tesuu]
          tesuu += 1
        end
      end
      return Kifu.new(result)
    end

    def &(kifu)
      merge kifu
    end

    def delete_comments
      delete_comments_of_kifu_data @kifu
    end

    private
    def delete_comments_of_kifu_data data
      data.gsub(/^(\*.*)$/, "\n").gsub(/\n\n/, "")
    end

    def comment? string
      string.match CommentPattern
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
