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
    end
  end

  describe "インスタンスメソッド: " do
    before :each do
      @sandmark_kifu = NKF.nkf('-w', File.read('sandmark.kif'))
      @asanebou_kifu = NKF.nkf('-w', File.read('asanebou.kif'))
      @sandmark = Kifu::Kifu.new @sandmark_kifu, "sandmark"
      @asanebou = Kifu::Kifu.new @asanebou_kifu, "asanebou"
      @started_at = DateTime.new(2010,12,11,23,31,33)
      @sandmark_first = Kifu::Sashite.new "*あさねぼうさんとの対局ぱーと2！\r\n*先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。\r\n   1 ５六歩(57)   ( 0:11/00:00:11)"
    end

    describe "Kifu#at: " do
      it "0を一手目に、棋譜の指し手を参照できる" do
        @sandmark.at(0).should be_an_instance_of(Kifu::Sashite)
        @sandmark.at(0).te.should eq(@sandmark_first.te)
      end

      it "Kifu#[] にエイリアスされている" do
        @sandmark[0].should be_an_instance_of(Kifu::Sashite)
        @sandmark[0].te.should eq(@sandmark_first.te)
      end
    end

    describe "Kifu#each: " do
      it "一手目から投了、中断までブロックを繰り返す" do
        result = []
        @sandmark.each do |sashite|
          result.push sashite.te
        end
        result.first.should eq("５六歩")
        result.last.should  eq("投了")
      end
    end

    describe "Kifu#each_with_index: " do
      it "一手目から投了、中断まで、インデックス付きでブロックを繰り返す" do
        result = {}
        @sandmark.each_with_index do |sashite, index|
          result[index] = sashite
        end
        result[4].te.should eq("７六歩")
      end
    end

    describe "Kifu#same?: " do
      it "同じ棋譜なら（コメントやヘッダが違っても） true を返す" do
        @sandmark.same?(@asanebou).should be_true
      end
    end

    describe "Kifu#strict_same?: " do
      it "まったく同じ棋譜でなければ true を返さない" do
        @sandmark.strict_same?(@asanebou).should be_false
        @sandmark.strict_same?(@sandmark).should be_true
      end
    end

    describe "Kifu#started_at: " do
      it "開始日時を返す" do
        @sandmark.started_at.should eq(@started_at)
      end
    end

    describe "Kifu#kisen: " do
      it "棋戦情報を返す" do
        @sandmark.kisen.should eq("レーティング対局室")
      end
    end

    describe "Kifu#teai: " do
      it "手合割を返す" do
        @sandmark.teai.should eq("平手")
      end
    end

    describe "Kifu#sente: " do
      it "先手の名前を返す" do
        @sandmark.sente.should eq("sandmark")
      end
    end

    describe "Kifu#gote: " do
      it "後手の名前を返す" do
        @sandmark.gote.should eq("asanebou")
      end
    end

    describe "Kifu#header: " do
      it "Kifu for Windows によって生成されたヘッダを返す" do
        @sandmark.header.should eq("# --- Kifu for Windows V6.32 棋譜ファイル ---")
      end
    end

    describe "Kifu#to_s: " do
      it "読み込んだ棋譜をUTF-8形式で返す" do
        NKF.guess(@sandmark.to_s).should be(NKF::UTF8)
      end

      it "読み込んだ棋譜と同一のものを返す" do
        @sandmark.to_s.should eq(@sandmark_kifu)
      end
    end
  end
end

describe Kifu::Sashite do
  describe "クラスメソッド: " do
    before :each do
      @sashite = '   1 ５六歩(57)   ( 0:11/00:00:11)'
      @comment = '*あさねぼうさんとの対局ぱーと2！'
      @toryo   = "まで76手で後手の勝ち"
    end

    describe "Sashite.sashite?: " do
      it "指し手なら MatchData を返す" do
        Kifu::Sashite.sashite?(@sashite).should be_true
        Kifu::Sashite.sashite?(@sashite).should be_an_instance_of(MatchData)
      end

      it "それ以外（コメントなど）なら false を返す" do
        Kifu::Sashite.sashite?(@comment).should be_false
      end

      it "to_s すること" do
        Kifu::Sashite.sashite?(nil).should be_false
      end
    end

    describe "Sashite.comment?: " do
      it "コメントなら MatchData オブジェクトを返す" do
        Kifu::Sashite.comment?(@comment).should be_true
        Kifu::Sashite.comment?(@comment).should be_an_instance_of(MatchData)
      end

      it "それ以外（指し手など）なら false を返す" do
        Kifu::Sashite.comment?(@sashite).should be_false
      end

      it "to_s すること" do
        Kifu::Sashite.comment?(nil).should be_false
      end
    end

    describe "Sashite.comment_or_sashite?: " do
      it "コメント・指し手のどちらかなら true を返す" do
        Kifu::Sashite.comment_or_sashite?(@comment).should be_true
        Kifu::Sashite.comment_or_sashite?(@sashite).should be_true
      end

      it "コメントでも指し手でもなければ false を返す" do
        Kifu::Sashite.comment_or_sashite?(@toryo).should be_false
      end
    end

    describe "Sashite.new: " do
      before :each do
        @normal = "   1 ５六歩(57)   ( 0:11/00:00:11)"
        @commented = "*あさねぼうさんとの対局ぱーと2！\r\n*先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。\r\n   1 ５六歩(57)   ( 0:11/00:00:11)"

        @names = ["sandmark", "asanebou"]
        @comments = ["あさねぼうさんとの対局ぱーと2！", "さんどさんと対戦だ！"]
        @tesuu = 1
        @te = "５六歩"
        @prev_te = "57"
        @time_considered = "0:11"
        @clock = "00:00:11"
        @args_specified =
          Kifu::Sashite.new(nil, nil, {
                              :names => @names,
                              :comments => @comments,
                              :tesuu => @tesuu,
                              :te => @te,
                              :prev_te => @prev_te,
                              :time_considered => @time_considered,
                              :clock => @clock})
      end

      it "普通の指し手を記録できる" do
        Kifu::Sashite.new(@normal).should be_an_instance_of(Kifu::Sashite)
      end

      it "コメント付き指し手を記録できる" do
        Kifu::Sashite.new(@commented).should be_an_instance_of(Kifu::Sashite)
      end

      it "「名前」を指定することができる" do
        Kifu::Sashite.new(@normal, "sandmark").
          should be_an_instance_of(Kifu::Sashite)
      end

      it "指し手を指定することができる" do
        @args_specified.te.should eq(@te)
      end

      it "コメントを複数指定できる" do
        @args_specified.comments.should eq(@comments)
      end

      it "手数を指定できる" do
        @args_specified.tesuu.should eq(@tesuu)
      end

      it "前の位置を指定できる" do
        @args_specified.prev_te.should eq(@prev_te)
      end

      it "消費時間を指定できる" do
        @args_specified.time_considered.should eq(@time_considered)
      end

      it "総消費時間を指定できる" do
        @args_specified.clock.should eq(@clock)
      end
    end
  end

  describe "インスタンスメソッド: " do
    before :each do
      @first = Kifu::Sashite.new "*あさねぼうさんとの対局ぱーと2！\r\n*先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。\r\n   1 ５六歩(57)   ( 0:11/00:00:11)", "sandmark"
      @second = Kifu::Sashite.new "   2 ５四歩(53)   ( 0:22/00:00:22)", "sandmark"
      @thirty_seven = Kifu::Sashite.new "  37 ３二銀成(41) ( 0:05/00:01:38)"

      @first_raw = "*あさねぼうさんとの対局ぱーと2！\r\n*先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。\r\n   1 ５六歩(57)   ( 0:11/00:00:11)"
      @second_raw = "   2 ５四歩(53)   ( 0:22/00:00:22)"
      @thirty_seven_raw = "  37 ３二銀成(41) ( 0:05/00:01:38)"
    end

    describe "Sashite#to_s: " do
      it "指し手を柿木棋譜形式にして返す" do
        @first.to_s.should eq(@first_raw)
        @second.to_s.should eq(@second_raw)
        @thirty_seven.to_s.should eq(@thirty_seven_raw)
      end
    end

    describe "Sashite#to_s_without_comment" do
      it "指し手をコメント無しで返す" do
        @first.to_s_without_comment.should eq("   1 ５六歩(57)   ( 0:11/00:00:11)")
        @second.to_s_without_comment.should eq(@second_raw)
        @thirty_seven.to_s_without_comment.should eq(@thirty_seven_raw)
      end
    end

    describe "Sashite#commented?" do
      it "コメントされている指し手なら true を返す" do
        @first.commented?.should be_true
      end

      it "コメントされていない指し手なら false を返す" do
        @second.commented?.should be_false
      end
    end

    describe "Sashite#comment: " do
      it "コメントを参照できる" do
        @first.comment.should eq("あさねぼうさんとの対局ぱーと2！\r\n先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。")
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

    describe "マージ関連: " do
      before :each do
        @sandmark1_raw = "*あさねぼうさんとの対局ぱーと2！\r\n*先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。\r\n   1 ５六歩(57)   ( 0:11/00:00:11)"
        @asanebou1_raw = "*さんどさんと対戦だ！\r\n*先手を取られてしまったので、たぶん中飛車でありましょう。\r\n   1 ５六歩(57)   ( 0:11/00:00:11)"
        @merge1_raw = "*マージできているかどうかのテストです。\r\n*名前付けがダブらないように。\r\n   1 ５六歩(57)   ( 0:11/00:00:11)"
        @merge1_comment = "マージできているかどうかのテストです。\r\n名前付けがダブらないように。"
        @merge1_named_comment = "merge: マージできているかどうかのテストです。\r\nmerge: 名前付けがダブらないように。"

        @sandmark1 = Kifu::Sashite.new @sandmark1_raw, "sandmark"
        @asanebou1 = Kifu::Sashite.new @asanebou1_raw, "asanebou"
        @merge1    = Kifu::Sashite.new @merge1_raw,    "merge"

        @merged = @sandmark1.merge(@asanebou1)
        @merged_twice = @merged.merge(@merge1)
      end

      describe "Sashite#names: " do
        it "名前を複数保有している" do
          @first.names.should be_an_instance_of(Array)
          @first.names.first.should eq("sandmark")
        end

        it "書き込みはできない" do
          lambda{@first.names.push("hoge")}.should raise_error
        end
      end

      describe "Sashite#name: " do
        it "オブジェクト生成時の名前を参照することができる" do
          @first.name.should eq("sandmark")
          @merged_twice.name.should eq("sandmark")
        end
      end

      describe "Sashite#merge: " do
        it "他の指し手と融合することができる" do
          @merged.should be_an_instance_of(Kifu::Sashite)
          @merged_twice.should be_an_instance_of(Kifu::Sashite)
        end

        it "名前リストに引数の指し手の名前が入る" do
          @merged.names[1].should eq("asanebou")
        end

        it "呼び出し元の名前、順番が優先される" do
          @merged_twice.names[2].should eq("merge")
          @merged_twice.comments[2].should eq(@merge1_comment)
        end
      end

      describe "Sashite#comments: " do
        it "コメントの配列が返る" do
          @merged.comments.should be_an_instance_of(Array)
          @merged.comments.should eq(["あさねぼうさんとの対局ぱーと2！\r\n先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。", "さんどさんと対戦だ！\r\n先手を取られてしまったので、たぶん中飛車でありましょう。"])
          @merged_twice.comments.should be_an_instance_of(Array)
          @merged_twice.comments.should eq(["あさねぼうさんとの対局ぱーと2！\r\n先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。", "さんどさんと対戦だ！\r\n先手を取られてしまったので、たぶん中飛車でありましょう。", @merge1_comment])
        end
      end

      describe "Sashite#comments_with_names: " do
        it "名前付きでコメントの配列を返す" do
          @merged.comments_with_names.
            should eq(["sandmark: あさねぼうさんとの対局ぱーと2！\r\nsandmark: 先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。", "asanebou: さんどさんと対戦だ！\r\nasanebou: 先手を取られてしまったので、たぶん中飛車でありましょう。"])
          @merged_twice.comments_with_names.
            should eq(["sandmark: あさねぼうさんとの対局ぱーと2！\r\nsandmark: 先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。", "asanebou: さんどさんと対戦だ！\r\nasanebou: 先手を取られてしまったので、たぶん中飛車でありましょう。", @merge1_named_comment])
        end
      end

      describe "Sashite#comment_with_name: " do
        it "各行に名前付きでコメントを返す" do
          @sandmark1.comment_with_name.
            should eq("sandmark: あさねぼうさんとの対局ぱーと2！\r\nsandmark: 先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。")
          @asanebou1.comment_with_name.
            should eq("asanebou: さんどさんと対戦だ！\r\nasanebou: 先手を取られてしまったので、たぶん中飛車でありましょう。")
        end
      end
    end
  end
end
