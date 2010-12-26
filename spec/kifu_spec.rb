# -*- coding: utf-8 -*-
$KCODE='u'
require 'kifu'
require 'nkf'

describe Kifu::Kifu do
  describe "クラスメソッド: " do
    describe "Kifu.valid?: " do
      it "正当な棋譜なら true を返す" do
        Kifu::Kifu.valid?(NKF.nkf('-w', File.read('sandmark.kif'))).should be_true
      end

      it "不当な棋譜なら false を返す" do
        Kifu::Kifu.valid?(NKF.nkf('-w', File.read('invalid.kif'))).should be_false
      end
    end

    describe "Kifu.new: " do
      it "Kifu.valid? が成立しなければ RuntimeError を投げる" do
        lambda {Kifu::Kifu.new(NKF.nkf('-w', File.read('invalid.kif')))}.
          should raise_error(RuntimeError)
      end

      pending "棋譜は内部でUTF-8にエンコーディングされていること"
    end
  end

  describe "インスタンスメソッド: " do
    before :each do
      @sandmark =
        Kifu::Kifu.new(NKF.nkf('-w', File.read('sandmark.kif')), "sandmark")
      @asanebou =
        Kifu::Kifu.new(NKF.nkf('-w', File.read('asanebou.kif')), "asanebou")
      @invalid  = Kifu::Kifu.new(NKF.nkf('-w', File.read('invalid.kif')))
      @started_at = DateTime.new(2010,12,11,23,31,33)
    end

    describe "Kifu#same?: " do
      pending "同じ棋譜なら（コメントやヘッダが違っても） true を返す" do
        @sandmark.same?(@asanebou).should be_true
      end

      pending "Kifu.valid? を通すこと: " do
        @sandmark.same?(@invalid).should be_false
      end
    end

    describe "Kifu.strict_same?: " do
      pending "より厳密なチェックを行う"
    end

    describe "Kifu#started_at: " do
      pending "開始日時を返す" do
        @sandmark.started_at.should eq(@started_at)
      end
    end
  end
end

describe Kifu::Sashite do
  describe "クラスメソッド: " do
    before :each do
      @sashite = '   1 ５六歩(57)   ( 0:11/00:00:11)'
      @comment = '*あさねぼうさんとの対局ぱーと2！'
    end

    describe "Sashite.sashite?: " do
      it "指し手なら true を返す" do
        Kifu::Sashite.sashite?(@sashite).should be_true
      end

      it "それ以外（コメントなど）なら false を返す" do
        Kifu::Sashite.sashite?(@comment).should be_false
      end
    end

    describe "Sashite.comment?: " do
      it "コメントなら true を返す" do
        Kifu::Sashite.comment?(@comment).should be_true
      end

      it "それ以外（指し手など）なら false を返す" do
        Kifu::Sashite.comment?(@sashite).should be_false
      end
    end

    describe "Sashite.new: " do
      before :each do
        @normal = '   1 ５六歩(57)   ( 0:11/00:00:11)'
        @commented = '*あさねぼうさんとの対局ぱーと2！
*先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。
   1 ５六歩(57)   ( 0:11/00:00:11)'
      end

      it "普通の指し手を記録できる" do
        Kifu::Sashite.new(@normal).should be_an_instance_of(Kifu::Sashite)
      end

      it "コメント付き指し手を記録できる" do
        Kifu::Sashite.new(@commented).should be_an_instance_of(Kifu::Sashite)
      end
    end
  end

  describe "インスタンスメソッド: " do
    before :each do
      @first = Kifu::Sashite.new "*あさねぼうさんとの対局ぱーと2！
*先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。
   1 ５六歩(57)   ( 0:11/00:00:11)"
      @second = Kifu::Sashite.new "   2 ５四歩(53)   ( 0:22/00:00:22)"
    end

    describe "Sashite#comment: " do
      it "コメントを参照できる" do
        @first.comment.should eq("あさねぼうさんとの対局ぱーと2！
先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。")
      end

      it "書き込みはできない" do
        lambda {@first.comment = "hoge"}.should raise_error
      end
    end

    describe "Sashite#tesuu: " do
      it "手数を参照できる" do
        @first.tesuu.should eq(1)
        @second.tesuu.should eq(2)
      end

      it "書き込みはできない" do
        lambda {@first.tesuu = 10}.should raise_error
        lambda {@first.tesuu = 10}.should raise_error
      end
    end

    describe "Sashite#te: " do
      it "指し手を参照できる" do
        @first.te.should eq("５六歩")
        @second.te.should eq("５四歩")
      end

      it "書き込みはできない" do
        lambda {@first.te  = "hoge"}.should raise_error
        lambda {@second.te = "fuga"}.should raise_error
      end
    end

    describe "Sashite#prev_te: " do
      it "よくわからないプログラム的な前の位置を参照できる" do
        @first. prev_te.should eq("57")
        @second.prev_te.should eq("53")
      end

      it "書き込みはできない" do
        lambda {@first. prev_te = "33"}.should raise_error
        lambda {@second.prev_te = "44"}.should raise_error
      end
    end

    describe "Sashite#time_considered: " do
      pending "消費時間を参照できる"
      it "書き込みはできない" do
        lambda {@first. time_considered = "hoge"}.should raise_error
        lambda {@second.time_considered = "fuga"}.should raise_error
      end
    end
  end
end
