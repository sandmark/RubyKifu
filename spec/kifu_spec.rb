# -*- coding: utf-8 -*-
$KCODE='u'
require 'kifu'
require 'nkf'

describe Kifu::Kifu do
  before :each do
    @kifu = Kifu::Kifu.new NKF.nkf('-w', File.read('sandmark.kif')), 'sandmark'
  end

  describe "クラスメソッド: " do
    describe "self.valid?: " do
      it "正当な棋譜なら true を返す" do
        Kifu::Kifu.valid?(NKF.nkf('-w', File.read('sandmark.kif'))).should be_true
      end

      it "不当な棋譜なら false を返す" do
        Kifu::Kifu.valid?(NKF.nkf('-w', File.read('invalid.kif'))).should be_false
      end
    end
  end
end
