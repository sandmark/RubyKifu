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
      it "Kifu.valid? が成立しなければ InvalidKifuError を投げる" do
        lambda {Kifu::Kifu.new(NKF.nkf('-w', File.read('invalid.kif')))}.
          should raise_error(Kifu::InvalidKifuError)
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

      @ham_kifu = File.read('ham.kif')
      @ham = Kifu::Kifu.new @ham_kifu, "ham"

      @to_s_with_names_test_raw = File.read('to_s_with_names_test.kif')
      @to_s_with_names_test = Kifu::Kifu.new @to_s_with_names_test_raw, "to_s"
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
      before :each do
        @same1 = Kifu::Kifu.new NKF.nkf("-w", File.read("same1.kif"))
        @same2 = Kifu::Kifu.new NKF.nkf("-w", File.read("same2.kif"))
      end
      
      it "同じ棋譜なら（コメントやヘッダが違っても） true を返す" do
        @sandmark.same?(@asanebou).should be_true
      end

      it "指し手表記の違いがあっても true を返す" do
        @same1.same?(@same2).should be_true
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
        @asanebou.to_s.should eq(@asanebou_kifu)
      end
    end

    describe "Kifu#to_s_with_names: " do
      it "読み込んだ棋譜を名前付きで返す" do
        @to_s_with_names_test.to_s_with_names.
          should eq(File.read("to_s_with_names_test.out.kif"))
      end
    end

    describe "マージ関連: " do
      before :each do
        @sandmark_m = Kifu::Kifu.new File.read("sandmark.kif"), "sandmark"
        @asanebou_m = Kifu::Kifu.new File.read("asanebou.kif"), "asanebou"
        @merged = @sandmark_m.merge @asanebou_m
      end

      describe "Kifu#merge: " do
        it "棋譜を合成し、新たな棋譜オブジェクトを返す" do
          @merged.should be_an_instance_of(Kifu::Kifu)
        end

        it "同じ棋譜でなければ例外を投げる" do
          lambda{@sandmark.merge(@ham)}.should raise_error(Kifu::KifuDifferenceError)
        end

        it "棋譜オブジェクトでなければ例外を投げる" do
          lambda{@sandmark.merge("string")}.should raise_error
        end

        it "ヘッダは呼び出し元を保持する" do
          ["header", "started_at",
           "kisen", "teai", "sente", "gote"].each do |method|
            @merged.__send__(method).should eq(@sandmark.__send__(method))
          end
        end

        it "& にエイリアスされている" do
          (@sandmark & @asanebou).should be_an_instance_of(Kifu::Kifu)
        end

        it "各指し手の名前に反映されている" do
          @merged[0].names.should eq(["sandmark", "asanebou"])
        end

        it "Kifu#to_s_with_names_and_comments で指し手がマージされていること" do
          @merged.to_s_with_names.should eq(File.read("merged.kif"))
        end
      end

      describe "コメントマージ関連: " do
        before :each do
          @new_comment = Kifu::Sashite.new(nil, nil, {
                                             :merge => true, 
                                             :tesuu => 12,
                                             :name => "nanashi",
                                             :comment => "コメントですよ"})
        end

        it "棋譜に手数を指定してマージできる（破壊的）" do
          @merged.merge_comment! @new_comment
          @merged[12].to_s_with_names_and_comments.
            should eq("*nanashi: コメントですよ\r\n  13 ２八玉(38)   ( 0:02/00:00:37)")
        end

        it "一時オブジェクトでもマージできる" do
          @merged[11].merge(@new_comment).
            should be_an_instance_of(Kifu::Sashite)
        end
      end
    end
  end
end

describe Kifu::Sashite do
  describe "クラスメソッド: " do
    before :each do
      @sashite = '   1 ５六歩(57)   ( 0:11/00:00:11)'
      @comment = '*あさねぼうさんとの対局ぱーと2！'
      @footer   = "まで76手で後手の勝ち"
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

    describe "Sashite.footer?: " do
      it "「までxxx手でXXの勝ち」などなら MatchData オブジェクトを返す" do
        Kifu::Sashite.footer?(@footer).should be_true
        Kifu::Sashite.footer?(@footer).should be_an_instance_of(MatchData)
      end

      it "それ以外には false を返す" do
        Kifu::Sashite.footer?(@comment).should be_false
        Kifu::Sashite.footer?(@sashite).should be_false
      end

      it "to_s すること" do
        Kifu::Sashite.footer?(nil).should be_false
      end
    end

    describe "Sashite.comment_or_sashite?: " do
      it "コメント・指し手のどちらかなら true を返す" do
        Kifu::Sashite.comment_or_sashite?(@comment).should be_true
        Kifu::Sashite.comment_or_sashite?(@sashite).should be_true
      end

      it "コメントでも指し手でもなければ false を返す" do
        Kifu::Sashite.comment_or_sashite?(@footer).should be_false
      end

      it "to_s すること" do
        Kifu::Sashite.comment_or_sashite?(nil).should be_false
      end
    end

    describe "Sashite.new: " do
      before :each do
        @normal = "   1 ５六歩(57)   ( 0:11/00:00:11)"
        @commented = "*あさねぼうさんとの対局ぱーと2！\r\n*先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。\r\n   1 ５六歩(57)   ( 0:11/00:00:11)"
        @footer = "*これで投了となりました。\r\n*\r\n*本局は４３手目の４５桂が、さんどさんの悪手であったと思います。\r\n*あそこで５５金と角を取られていたら、おそらくこちらの負けでした。\r\n*\r\n*幸運があり、勝負に勝つことができました。\r\n*さんどさんありがとうございました！\r\n*\r\n*また対戦しましょうね！\r\nまで76手で後手の勝ち"

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

      it "フッタを記録できる" do
        Kifu::Sashite.new(@footer).should be_an_instance_of(Kifu::Sashite)
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

      @footer_raw = "*これで投了となりました。\r\n*\r\n*本局は４３手目の４５桂が、さんどさんの悪手であったと思います。\r\n*あそこで５５金と角を取られていたら、おそらくこちらの負けでした。\r\n*\r\n*幸運があり、勝負に勝つことができました。\r\n*さんどさんありがとうございました！\r\n*\r\n*また対戦しましょうね！\r\nまで76手で後手の勝ち"
      @footer_named = "*no name: これで投了となりました。\r\n*no name: \r\n*no name: 本局は４３手目の４５桂が、さんどさんの悪手であったと思います。\r\n*no name: あそこで５５金と角を取られていたら、おそらくこちらの負けでした。\r\n*no name: \r\n*no name: 幸運があり、勝負に勝つことができました。\r\n*no name: さんどさんありがとうございました！\r\n*no name: \r\n*no name: また対戦しましょうね！\r\nまで76手で後手の勝ち"
      @footer = Kifu::Sashite.new @footer_raw
    end

    describe "Sashite#to_s関連: " do
      before :each do
        @sandmark4_raw = "*この辺で「中飛車！有効！」などとチャット欄に打ち込んでは2人ではしゃいでいました。\r\n   4 ５二飛(82)   ( 0:03/00:00:25)"
        @asanebou4_raw = "   4 ５二飛(82)   ( 0:03/00:00:25)"

        @sandmark4 = Kifu::Sashite.new @sandmark4_raw, "sandmark"
        @asanebou4 = Kifu::Sashite.new @asanebou4_raw, "asanebou"
        @merged    = @sandmark4.merge @asanebou4
        @merged_to_s_nc_result = "*sandmark: この辺で「中飛車！有効！」などとチャット欄に打ち込んでは2人ではしゃいでいました。\r\n   4 ５二飛(82)   ( 0:03/00:00:25)"

        @sandmark1_raw = "*あさねぼうさんとの対局ぱーと2！\r\n*先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。\r\n   1 ５六歩(57)   ( 0:11/00:00:11)"
        @asanebou1_raw = "*さんどさんと対戦だ！\r\n*先手を取られてしまったので、たぶん中飛車でありましょう。\r\n   1 ５六歩(57)   ( 0:11/00:00:11)"

        @sandmark1 = Kifu::Sashite.new @sandmark1_raw, "sandmark"
        @asanebou1 = Kifu::Sashite.new @asanebou1_raw, "asanebou"
        @merged2   = @sandmark1.merge @asanebou1
        @merged2_to_s_nc_result = "*sandmark: あさねぼうさんとの対局ぱーと2！\r\n*sandmark: 先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。\r\n*asanebou: さんどさんと対戦だ！\r\n*asanebou: 先手を取られてしまったので、たぶん中飛車でありましょう。\r\n   1 ５六歩(57)   ( 0:11/00:00:11)"
      end

      describe "Sashite#to_s: " do
        it "指し手を柿木棋譜形式にして返す" do
          @first.to_s.should eq(@first_raw)
          @second.to_s.should eq(@second_raw)
          @thirty_seven.to_s.should eq(@thirty_seven_raw)
          @footer.to_s.should eq(@footer_raw)
        end
      end

      describe "Sashite#to_s_without_comments" do
        it "指し手をコメント無しで返す" do
          @first.to_s_without_comments.should eq("   1 ５六歩(57)   ( 0:11/00:00:11)")
          @second.to_s_without_comments.should eq(@second_raw)
          @thirty_seven.to_s_without_comments.should eq(@thirty_seven_raw)
          
          @footer.to_s_without_comments.should eq("まで76手で後手の勝ち")
          @merged.to_s_without_comments.should eq("   4 ５二飛(82)   ( 0:03/00:00:25)")
        end
      end

      describe "Sashite#to_s_with_names_and_comments" do
        it "すべてのコメントを名前付きで結合して返す" do
          @merged2.to_s_with_names_and_comments.
            should eq(@merged2_to_s_nc_result)
        end

        it "片方のみのコメントでも返す" do
          @merged.to_s_with_names_and_comments.should eq(@merged_to_s_nc_result)
        end

        it "コメントがひとつでも正常に返す" do
          @footer.to_s_with_names_and_comments.should eq(@footer_named)
        end
      end
    end

    describe "Sashite#commented?" do
      it "コメントされている指し手なら true を返す" do
        @first.commented?.should be_true
        @footer.commented?.should be_true
      end

      it "コメントされていない指し手なら false を返す" do
        @second.commented?.should be_false
      end
    end

    describe "Sashite#footer?: " do
      it "自身がフッタなら true を返す" do
        @footer = Kifu::Sashite.new @footer_raw
        @footer.footer?.should be_true
      end
    end

    describe "Sashite#comment: " do
      it "コメントを参照できる" do
        @first.comment.should eq("あさねぼうさんとの対局ぱーと2！\r\n先手番もらいました。ちなみに天下一将棋会ごっこも兼ねていたようです。")
        @footer = Kifu::Sashite.new @footer_raw
        @footer.comment.should eq("これで投了となりました。\r\n\r\n本局は４３手目の４５桂が、さんどさんの悪手であったと思います。\r\nあそこで５５金と角を取られていたら、おそらくこちらの負けでした。\r\n\r\n幸運があり、勝負に勝つことができました。\r\nさんどさんありがとうございました！\r\n\r\nまた対戦しましょうね！")
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

        @commented_raw = "*この辺で「中飛車！有効！」などとチャット欄に打ち込んでは2人ではしゃいでいました。\r\n   4 ５二飛(82)   ( 0:03/00:00:25)"
        @nocommented_raw = "   4 ５二飛(82)   ( 0:03/00:00:25)"

        @commented = Kifu::Sashite.new @commented_raw, "commented"
        @nocommented = Kifu::Sashite.new @nocommented_raw, "nocommented"

        @footer_sandmark_raw = "まで76手で後手の勝ち"
        @footer_asanebou_raw = "*これで投了となりました。\r\n*\r\n*本局は４３手目の４５桂が、さんどさんの悪手であったと思います。\r\n*あそこで５５金と角を取られていたら、おそらくこちらの負けでした。\r\n*\r\n*幸運があり、勝負に勝つことができました。\r\n*さんどさんありがとうございました！\r\n*\r\n*また対戦しましょうね！\r\nまで76手で後手の勝ち"

        @footer_sandmark = Kifu::Sashite.new @footer_sandmark_raw, "sandmark"
        @footer_asanebou = Kifu::Sashite.new @footer_asanebou_raw, "asanebou"
        @footer_merged = @footer_sandmark.merge @footer_asanebou
        @footer_merged_raw = "*asanebou: これで投了となりました。\r\n*asanebou: \r\n*asanebou: 本局は４３手目の４５桂が、さんどさんの悪手であったと思います。\r\n*asanebou: あそこで５５金と角を取られていたら、おそらくこちらの負けでした。\r\n*asanebou: \r\n*asanebou: 幸運があり、勝負に勝つことができました。\r\n*asanebou: さんどさんありがとうございました！\r\n*asanebou: \r\n*asanebou: また対戦しましょうね！\r\nまで76手で後手の勝ち"
      end

      describe "フッタ関係: " do
        it "名前を保持できる" do
          @footer_merged.names.should eq(["sandmark", "asanebou"])
        end

        it "to_s できる" do
          @footer_merged.to_s.should eq(@footer_sandmark_raw)
        end

        it "to_s_with_names_and_comments できる" do
          @footer_merged.to_s_with_names_and_comments.
            should eq(@footer_merged_raw)
        end
      end

      describe "Sashite#commented?: " do
        it "誰かのコメントがあれば true を返す" do
          @commented.merge(@nocommented).commented?.should be_true
          @nocommented.merge(@commented).commented?.should be_true
        end
      end

      describe "Sashite#count_of_comment: " do
        it "コメントの数を返す" do
          @commented.count_of_comment.should_not be_zero
          @nocommented.count_of_comment.should be_zero
        end
      end

      describe "Sashite#names: " do
        it "名前を複数保有している" do
          @first.names.should be_an_instance_of(Array)
          @first.names.first.should eq("sandmark")
        end

        it "マージされた場合、名前を継承している" do
          @merged.names[0].should eq("sandmark")
          @merged.names[1].should eq("asanebou")
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
        it "指し手オブジェクトでなければ例外を投げる" do
          lambda{@merged.merge("string")}.should raise_error
        end

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

        it "& で呼び出せる" do
          (@sandmark1 & @asanebou1).should be_an_instance_of(Kifu::Sashite)
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

      describe "フッタ関連: " do
        before :each do
          @footer_sandmark = Kifu::Sashite.new "まで76手で後手の勝ち", "sandmark"
          @footer_asanebou = Kifu::Sashite.new "*これで投了となりました。\r\n*\r\n*本局は４３手目の４５桂が、さんどさんの悪手であったと思います。\r\n*あそこで５５金と角を取られていたら、おそらくこちらの負けでした。\r\n*\r\n*幸運があり、勝負に勝つことができました。\r\n*さんどさんありがとうございました！\r\n*\r\n*また対戦しましょうね！\r\nまで76手で後手の勝ち", "asanebou"
          @footer_merged = @footer_sandmark & @footer_asanebou

          @comment_sandmark = ""
          @comment_asanebou = "これで投了となりました。\r\n\r\n本局は４３手目の４５桂が、さんどさんの悪手であったと思います。\r\nあそこで５５金と角を取られていたら、おそらくこちらの負けでした。\r\n\r\n幸運があり、勝負に勝つことができました。\r\nさんどさんありがとうございました！\r\n\r\nまた対戦しましょうね！"

          @comment_with_name_of_sandmark = ""
          @comment_with_name_of_asanebou = "asanebou: これで投了となりました。\r\nasanebou: \r\nasanebou: 本局は４３手目の４５桂が、さんどさんの悪手であったと思います。\r\nasanebou: あそこで５５金と角を取られていたら、おそらくこちらの負けでした。\r\nasanebou: \r\nasanebou: 幸運があり、勝負に勝つことができました。\r\nasanebou: さんどさんありがとうございました！\r\nasanebou: \r\nasanebou: また対戦しましょうね！"
        end

        describe "Sashite#comments" do
          it "コメントが保持されていること" do
            @footer_merged.comments[0].should eq(@comment_sandmark)
            @footer_merged.comments[1].should eq(@comment_asanebou)
          end
        end

        describe "Sashite#comments_with_names" do
          it "名前付きコメントが保持されていること" do
            @footer_merged.comments_with_names[0].
              should eq(@comment_with_name_of_sandmark)
            @footer_merged.comments_with_names[1].
              should eq(@comment_with_name_of_asanebou)
          end
        end
      end
    end
  end
end

describe "まるたさんの棋譜: " do
  before :each do
    @maruta1_raw = File.read "maruta1.kif"
    @maruta1_raw_expected = File.read "maruta1_expected.kif"
    @maruta1     = Kifu::Kifu.new @maruta1_raw, "maruta"
    @maruta1_1   = "   1 ７六歩(77)   (00:00/00:00:00)"
  end

  it "棋譜を相互変換できること" do
    @maruta1.to_s.should eq(@maruta1_raw_expected)
  end

  it "指し手を識別できること" do
    Kifu::Sashite.sashite?(@maruta1_1).should be_true
  end
end
