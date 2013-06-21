#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-

require 'scanf'

################################################################################
# 2次元配列
################################################################################

class Matrix
  include Enumerable

  def initialize(n, m, array = nil)
    @n = n
    @m = m
    @array = array
    @array ||= Array.new(n * m)
  end

  def [](i, j)
    @array[i * @m + j]
  end
  def []=(i, j, value)
    @array[i * @m + j] = value
  end

  def each(&proc)
    @array.each(&proc)
  end
  def each_with_index
    return enum_for(:each_with_index) unless block_given?

    (0 ... @n).each {|i|
      (0 ... @m).each {|j|
        value = @array[i * @m + j]
        yield(value, i, j)
      }
    }
  end

  def to_a
    @array
  end
  def to_s
    to_a.to_s
  end

  # 配列インスタンスごと複製する
  def clone
    Matrix.new(@n, @m, @array.clone)
  end
end

################################################################################
# ぬりかべ
################################################################################

class Nurikabe
  U = "0"
  W = " "
  B = "#"
  
  def initialize(n, m, board)
    @n = n
    @m = m
    @board = board
  end

  def to_s
    s = "\##{@n} #{@m}"
    s << "\n"
    s << @board.each_slice(@m).map {|row| row.map(&:to_s).join }.join("\n")
    s
  end

  def white?(v)
    v == W
  end
  def number?(v)
    (v =~ /^[1-9]$/) != nil
  end
  def black?(v)
    v == B
  end
  def filled?(v)
    white?(v) || number?(v) || black?(v)
  end

  ######################################
  # group
  ######################################

  # 未確定マス、白・数字マス、黒マスに対してそれぞれ異なる値を返却する
  def group_type(v)
    case true
    when white?(v) || number?(v)
      1
    when black?(v)
      2
    else
      0
    end
  end
  # 未確定マスと白・数字マスを同一視する
  def group_type_white(v)
    v == U ? group_type(W) : group_type(v)
  end
  # 未確定マスと黒マスを同一視する
  def group_type_black(v)
    v == U ? group_type(B) : group_type(v)
  end
  # ルックアップテーブルを作成する
  def group_map(t)
    data1 = []
    data2 = Hash.new
    next_index = 0

    t.each {|v1, v2|
      tmp1 = data1.find {|values| values.include?(v1) }
      tmp2 = data1.find {|values| values.include?(v2) }

      if !tmp1 && !tmp2
        data1.push([v1, v2])
      elsif !tmp1 && tmp2
        tmp2.push(v1)
      elsif tmp1 && !tmp2
        tmp1.push(v2)
      elsif tmp1 != tmp2
        data1.delete(tmp1)
        data1.delete(tmp2)
        data1.push(tmp1 | tmp2)
      end
    }

    data1.each {|values|
      values.each {|v| data2[v] = next_index }
      next_index += 1
    }

    data2
  end
  # 4連結ラベリングしてindexを付ける
  def group_index
    t = Matrix.new(@n, @m)
    data1 = []
    data2 = Hash.new
    next_index = 0

    t.each_with_index {|value, i, j|
      same_t = i > 0 && yield(@board[i - 1, j], @board[i, j])
      same_l = j > 0 && yield(@board[i, j - 1], @board[i, j])

      if !same_t && !same_l
        t[i, j] = next_index
        data1.push([next_index, next_index])
        next_index += 1
      elsif same_t && !same_l
        t[i, j] = t[i - 1, j]
      elsif !same_t && same_l
        t[i, j] = t[i, j - 1]
      else
        min = [t[i - 1, j], t[i, j - 1]].min
        max = [t[i - 1, j], t[i, j - 1]].max
        data1.push([min, max])
        t[i, j] = min
      end
    }

    data2 = group_map(data1)

    t.each_with_index {|value, i, j|
      t[i, j] = data2[value]
    }

    t
  end
  # 4連結ラベリングする
  def group
    return @group if @group

    @group = group_index {|v1, v2|
      group_type(v1) == group_type(v2)
    }
  end
  # 未確定マスを白マスと見做し、4連結ラベリングする
  def group_white
    return @group_white if @group_white

    @group_white = group_index {|v1, v2|
      group_type_white(v1) == group_type_white(v2)
    }
  end
  # 未確定マスを黒マスと見做し、4連結ラベリングする
  def group_black
    return @group_black if @group_black

    @group_black = group_index {|v1, v2|
      group_type_black(v1) == group_type_black(v2)
    }
  end
  # ラベリング結果からHashを生成する
  def group_to_h(t)
    h = Hash.new

    t.each_with_index {|index, i, j|
      h[index] = [] unless h.has_key?(index)
      h[index].push(yield(index, i, j))
    }

    h
  end

  ######################################
  # hash
  ######################################

  # エリア番号と「各マスのエリア番号、X座標、Y座標の配列」のHash
  def summary
    return @summary if @summary

    @summary = group_to_h(group) {|index, i, j|
      [@board[i, j], i, j]
    }
  end
  # 未確定マスを白マスと見做したときの、
  # エリア番号と「各マスのエリア番号、X座標、Y座標の配列」のHash
  def summary_white
    return @summary_white if @summary_white

    @summary_white = group_to_h(group_white) {|index, i, j|
      [@board[i, j], i, j]
    }
  end
  # 未確定マスを黒マスと見做したときの、
  # エリア番号と「各マスのエリア番号、X座標、Y座標の配列」のHash
  def summary_black
    return @summary_black if @summary_black

    @summary_black = group_to_h(group_black) {|index, i, j|
      [@board[i, j], i, j]
    }
  end

  ######################################
  # check
  ######################################

  # 2x2以上の黒マスの固まりがあればNG
  def validate_include_2x2
    @board.each_with_index.map {|value, i, j|
      i > 0 && j > 0 && value == B &&
        @board[i - 0, j - 0] == @board[i - 0, j - 1] &&
        @board[i - 0, j - 1] == @board[i - 1, j - 0] &&
        @board[i - 1, j - 0] == @board[i - 1, j - 1]
    }.none?
  end
  # 黒エリアが連結である
  def validate_continuity
    summary.map {|index, entries|
      values = entries.map {|value, i, j| value }
      values.include?(B)
    }.one?
  end
  # 各エリアにおいて下記のどれかが真
  # -> すべて黒マス
  # -> 含まれる数字マスが1個 &&
  #    数字マス以外はすべて白マス &&
  #    エリアの数字とエリアの要素数が同じ
  def validate_combination
    summary.each_pair {|index, entries|
      values = entries.map {|value, i, j| value }
      number = values.find {|v| number?(v) }
      count_w = values.count {|v| white?(v) }
      count_n = values.count {|v| number?(v) }
      count_b = values.count {|v| black?(v) }

      next if count_b == values.size
      next if count_n == 1 &&
        count_w == values.size - 1 &&
        number.to_i == values.size
      return false
    }

    true
  end
  # 回答をチェックする
  def validate
    @group = @summary = nil

    validate_include_2x2 &&
      validate_continuity &&
      validate_combination
  end

  # 未確定マスを黒マスと見做したとき、黒エリアが連結である
  # ただし、黒エリアが存在しない場合も連結とする
  def validate_continuity_in_searching
    count = summary_black.count {|index, entries|
      values = entries.map {|value, i, j| value }
      values.include?(B)
    }
    count == 0 || count == 1
  end
  # 各エリアについて下記のどれかが真
  # -> すべて黒マス
  # -> すべて白マス
  # -> すべて未確定マス
  # -> 含まれる数字マスが1個 &&
  #    数字マス以外はすべて白マス &&
  #    エリアの数字がエリアの要素数以上
  def validate_combination_in_searching
    summary.each_pair {|index, entries|
      values = entries.map {|value, i, j| value }
      number = values.find {|v| number?(v) }
      count_e = values.count {|v| !filled?(v) }
      count_w = values.count {|v| white?(v) }
      count_n = values.count {|v| number?(v) }
      count_b = values.count {|v| black?(v) }

      next if count_e == values.size
      next if count_w == values.size
      next if count_b == values.size
      next if count_n == 1 &&
        count_w == values.size - 1 &&
        number.to_i >= values.size
      return false
    }

    true
  end
  # 未確定マスを白マスと見做したとき、エリア内のマスがすべて白マスならばNG
  def validate_without_number
    summary_white.map {|index, entries|
      values = entries.map {|value, i, j| value }
      count = values.count {|v| white?(v) }
      count == values.size
    }.none?
  end
  # 未確定マスを白マスと見做したとき、エリアの数字がエリアの要素数を上回るならばNG
  def validate_number_more
    summary_white.map {|index, entries|
      values = entries.map {|value, i, j| value }
      number = values.find {|v| number?(v) }
      number && number.to_i > values.size
    }.none?
  end
  # エリアの白マスの個数が「全エリアの数字の最大値」未満ならばOK
  def validate_number_max
    max_number = 0

    summary.each_pair {|index, entries|
      values = entries.map {|value, i, j| value }
      number = values.find {|v| number?(v) }
      next unless number

      max_number = number.to_i if number.to_i > max_number
    }

    summary.map {|index, entries|
      values = entries.map {|value, i, j| value }
      count = values.count {|v| white?(v) }
      count < max_number
    }.all?
  end
  # 途中回答をチェックする
  def validate_in_searching
    @group = @summary = nil
    @group_white = @summary_white = nil
    @group_black = @summary_black = nil

    validate_include_2x2 &&
      validate_continuity_in_searching &&
      validate_combination_in_searching &&
      validate_without_number &&
      validate_number_more &&
      validate_number_max
  end

  ######################################
  # fill
  ######################################

  # 数字マスが2x2の対角にある
  # -> 数字マス以外の2マスが黒マスで確定
  # 数字マスが1マス挟んで隣り合っている
  # -> 間の1マスが黒マスで確定
  def fill_neighbor
    @board.each_with_index {|value, i, j|
      if i > 0 && j > 0
        v1 = @board[i - 0, j - 0]
        v2 = @board[i - 0, j - 1]
        v3 = @board[i - 1, j - 0]
        v4 = @board[i - 1, j - 1]

        @board[i - 0, j - 1] = @board[i - 1, j - 0] = B if number?(v1) && number?(v4)
        @board[i - 0, j - 0] = @board[i - 1, j - 1] = B if number?(v2) && number?(v3)
      end

      if i >= 2
        v1 = @board[i - 2, j]
        v2 = @board[i - 0, j]

        @board[i - 1, j] = B if number?(v1) && number?(v2)
      end

      if j >= 2
        v1 = @board[i, j - 2]
        v2 = @board[i, j - 0]

        @board[i, j - 1] = B if number?(v1) && number?(v2)
      end
    }
  end
  # 未確定マスを白マスと見做したとき、エリア内の数字マスが0個
  # -> エリア内のマスがすべて黒マスで確定
  def fill_without_number
    @group_white = @summary_white = nil

    summary_white.each_pair {|index, entries|
      values = entries.map {|value, i, j| value }
      number = values.find {|v| number?(v) }
      next if number

      summary_white[index].each {|_, i, j|
        @board[i, j] = B
      }
    }
  end
  # 未確定マスを白マスと見做したとき、エリアの数字がエリアの要素数と同じ
  # -> エリア内の未確定マスが白マスで確定
  def fill_with_number
    @group_white = @summary_white = nil

    summary_white.each_pair {|index, entries|
      values = entries.map {|value, i, j| value }
      number = values.find {|v| number?(v) }
      next unless number
      next unless number.to_i == values.size

      summary_white[index].each {|_, i, j|
        @board[i, j] = W if !filled?(@board[i, j])
      }
    }
  end
  # エリアの数字がエリアの要素数と同じ
  # -> エリアに隣接するマスが黒マスで確定
  def fill_edge_with_number
    @group = @summary = nil

    summary.each_pair {|index, entries|
      values = entries.map {|value, i, j| value }
      number = values.find {|v| number?(v) }
      next unless number
      next unless number.to_i == values.size

      summary[index].each {|_, i, j|
        @board[i - 1, j] = B if i > 0 && group[i - 1, j] != index
        @board[i, j - 1] = B if j > 0 && group[i, j - 1] != index
        @board[i + 1, j] = B if i < @n - 1 && group[i + 1, j] != index
        @board[i, j + 1] = B if j < @m - 1 && group[i, j + 1] != index
      }
    }
  end
  # エリアの数字がエリアの要素数を上回り、隣接する未確定マスが1個
  # もしくはエリアがすべて白マスで、隣接する未確定マスが1個
  # -> エリアに隣接する未確定マスが白マスで確定
  def fill_extensible
    @group = @summary = nil

    summary.each_pair {|index, entries|
      values = entries.map {|value, i, j| value }
      number = values.find {|v| number?(v) }
      count = values.count {|v| white?(v) }
      next if (!number || number.to_i <= values.size) && count != values.size

      data = []

      summary[index].each {|_, i, j|
        data.push([i - 1, j]) if i > 0 && !filled?(@board[i - 1, j])
        data.push([i, j - 1]) if j > 0 && !filled?(@board[i, j - 1])
        data.push([i + 1, j]) if i < @n - 1 && !filled?(@board[i + 1, j])
        data.push([i, j + 1]) if j < @m - 1 && !filled?(@board[i, j + 1])
      }

      # ラベリングからやり直す必要がある
      if data.size == 1
        i, j = data[0]
        @board[i, j] = W
        return
      end
    }
  end
  # ルールを元に確定する
  def fill
    count = 0

    while true
      next_count = @board.count {|v| !filled?(v) }
      return if count == next_count
      count = next_count

      fill_neighbor
      fill_without_number
      fill_with_number
      fill_edge_with_number
      fill_extensible
    end
  end

  ######################################
  # solve
  ######################################

  # 未確定マスを抽出する
  def solve_find
    @board.each_with_index.select {|value, i, j|
      !filled?(value)
    }.map {|count, i, j|
      [i, j]
    }
  end
  # 解を深さ優先で探索する
  def solve
    queue = [@board]

    while !queue.empty?
      @board = queue.pop

      if validate_in_searching
        # ルールを元に確定する
        fill

        # 未確定のマスを選択する
        data = solve_find

        if !data.empty?
          i, j = data[0]
          puts "DEBUG[#{i}, #{j}]:" 
          puts to_s 

          @board[i, j] = B
          queue.push(@board.clone)
          @board[i, j] = W
          queue.push(@board.clone)
        elsif validate
          puts "FOUND:"
          puts to_s
          return
        else
          puts "NONE:"
          puts to_s
        end
      end
    end
  end
end

################################################################################
# エントリポイント
################################################################################

n, m = $stdin.gets.scanf("\#%d%d")
board = $stdin.read.gsub(/[\r\n]/, String.new).split(//)

nurikabe = Nurikabe.new(n, m, Matrix.new(n, m, board))
nurikabe.solve