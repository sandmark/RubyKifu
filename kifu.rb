# -*- coding: utf-8 -*-

$KCODE='u'
require 'nkf'

module Kifu
  class Kifu
    ValidKifuPattern = /^開始日時：/

    # 柿木形式棋譜の判定を行う（適当）
    def self.valid? kifu
      not NKF.nkf('-w', kifu).scan(ValidKifuPattern).empty?
    end

    def initialize kifu, name=''
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
